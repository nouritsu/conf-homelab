"""Pull the CampusNet schedule and publish it as ICS feeds for Proton Calendar to subscribe to."""

import argparse
import datetime as dt
import json
import logging
import logging.handlers
import os
import re
import shutil
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import urljoin, urlparse
from zoneinfo import ZoneInfo

import icalendar
import requests
from bs4 import BeautifulSoup
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

log = logging.getLogger("cn-calsync")

BASE = "https://campusnet.constructor.university"
DLL = BASE + "/scripts/mgrqispi.dll"
START_PAGE = DLL + "?APPNAME=CampusNet&PRGNAME=EXTERNALPAGES&ARGUMENTS=-N000000000000001,-N000157,-Adata%5Fprivacy%5Fstatement%2Ehtml"
SCHEDULE_MENU = "-N000056"
TZ = ZoneInfo("Europe/Berlin")
COURSE_TTL = dt.timedelta(days=7)
HISTORY = dt.timedelta(days=365)
PLACEHOLDER = "CHANGEME"

# feed file -> (calendar name suffix, RFC 7986 colour)
FEEDS = {
    "lectures": ("Lectures", "royalblue"),
    "tutorials": ("Tutorials", "seagreen"),
    "exams": ("Exams", "crimson"),
    "other": ("Other", "slategray"),
}

MONTHS = {
    "jan": 1, "feb": 2, "mar": 3, "mär": 3, "apr": 4, "may": 5, "mai": 5, "jun": 6,
    "jul": 7, "aug": 8, "sep": 9, "oct": 10, "okt": 10, "nov": 11, "dec": 12, "dez": 12,
}
TIME_RANGE = re.compile(r"(\d{1,2}:\d{2})\s*-\s*(\d{1,2}:\d{2})")
EXAM_TITLE = re.compile(r"^(?P<form>[^:]*\bexam[^:]*):\s*(?P<name>.+)$", re.IGNORECASE)
EVENT_FIELDS = ("summary", "category", "date", "start", "end", "location", "description")


class SyncError(Exception):
    """A failure worth one log line rather than a traceback."""


class ParseError(SyncError):
    """CampusNet returned a page this script does not understand."""


# ---------------------------------------------------------------- parsing


def soup(html):
    return BeautifulSoup(html, "html.parser")


def text(node):
    return " ".join(node.get_text(" ").split()) if node else ""


def parse_date(value):
    m = re.search(r"(\d{1,2})\.(\d{1,2})\.(\d{4})", value)
    if m:
        return dt.date(int(m[3]), int(m[2]), int(m[1]))
    m = re.search(r"(\d{1,2})\.\s*([^\W\d_]+)\.?\s+(\d{4})", value)
    if m and m[2][:3].lower() in MONTHS:
        return dt.date(int(m[3]), MONTHS[m[2][:3].lower()], int(m[1]))
    raise ParseError(f"unreadable date {value!r}")


def link_ids(href):
    """(appointment id, kind, course or module id) from a COURSEPREP link."""
    m = re.search(r"ARGUMENTS=([^&]*)", href or "")
    args = m[1].split(",") if m else []
    # -N<session>,-N<menu>,-N0,-N<appointment>,-A<CODA|MOFF>,-N<course or module>
    if len(args) < 6:
        return None
    return args[3][2:], args[4][2:], args[5][2:]


def appointment(href, day, times, rooms, name, code):
    ids = link_ids(href)
    m = TIME_RANGE.search(times)
    if not ids or not m:
        raise ParseError(f"unreadable appointment {name!r} on {day}")
    appt_id, kind, ref = ids
    return {
        "id": appt_id,
        "kind": kind,
        "ref": ref,
        "date": day.isoformat(),
        "start": m[1].zfill(5),
        "end": m[2].zfill(5),
        "rooms": [r for r in (r.strip() for r in rooms) if r],
        "name": name.strip(),
        "code": code.strip(),
        "href": href,
    }


def parse_month(html):
    """Appointments of a month view, and the (day, link) of days it only lists in part."""
    cells = soup(html).select("td.tbMonthDayCell")
    if not cells:
        raise ParseError("no day cells; not a month view (session expired?)")
    appts, crowded = [], []
    for cell in cells:
        head = cell.select_one(".tbsubhead a[title]")
        if head is None:
            continue
        day = parse_date(head["title"])
        more = cell.find("a", title="more...")
        if more is not None:
            crowded.append((day, more["href"]))
        for a in cell.select(".appMonth a.apmntLink"):
            # title is "09:45 - 11:00 / Room A;Room B / Course name"
            times, rooms, name = (a.get("title", "").split(" / ", 2) + ["", ""])[:3]
            appts.append(appointment(a["href"], day, times, rooms.split(";"), name, text(a).split(" - ", 1)[-1]))
    return appts, crowded


def parse_day(html, day):
    appts = []
    for cell in soup(html).select("td.appointment"):
        link = cell.select_one("a.link")
        if link is None:
            continue
        rooms = [text(a) for a in cell.select("a.arrow")]
        appts.append(appointment(link["href"], day, text(cell.find("span")), rooms, link.get("title", ""), text(link)))
    if not appts:
        raise ParseError(f"day view for {day} lists no appointments")
    return appts


def parse_prep(html):
    """An appointment page: code, title, rooms, instructors and where the course details are."""
    page = soup(html)
    code, _, title = text(page.find("h1")).partition(" ")
    if not code:
        raise ParseError("appointment page without a heading")
    details = page.find("a", attrs={"name": "eventLink"})
    return {
        "code": code,
        "title": title,
        # sic: CampusNet spells it appoinmentRooms here
        "rooms": [text(e) for e in page.find_all(attrs={"name": "appoinmentRooms"})],
        "instructors": [text(e) for e in page.find_all(attrs={"name": "instructorName"})],
        "details": details["href"] if details else None,
    }


def parse_details(html):
    """A course offering's details: type, instructors, modules and every appointment's instructors."""
    page = soup(html)
    code, _, title = text(page.find("h1")).partition(" ")

    def field(label):
        b = page.find("b", string=re.compile(rf"^\s*{re.escape(label)}\s*:?\s*$"))
        return text(b.parent).split(":", 1)[-1].strip() if b else ""

    modules = []
    caption = page.find("caption", string=re.compile("Contained in modules"))
    if caption is not None:
        modules = [text(td).split(" ", 1)[0] for td in caption.find_parent("table").select("td.tbdata") if text(td)]

    instructors_at = {}
    for row in page.find_all("tr"):
        date = row.find(attrs={"name": "appointmentDate"})
        start = row.find(attrs={"name": "appointmentTimeFrom"})
        who = row.find(attrs={"name": "appointmentInstructors"})
        if date and start and who:
            instructors_at[f"{parse_date(text(date)).isoformat()} {text(start).zfill(5)}"] = text(who)

    return {
        "code": code,
        "title": title,
        "type": field("Type"),
        "instructors": field("Instructors"),
        "org_unit": field("Org-unit"),
        "credits": field("Credits"),
        "modules": modules,
        "instructors_at": instructors_at,
    }


# ---------------------------------------------------------------- campusnet


def find_session(*sources):
    for source in sources:
        for m in re.finditer(r"-N(\d{15})", source or ""):
            # the anonymous sessions are 000000000000001 and 000000000000002
            if int(m[1]) > 999:
                return m[1]
    return None


class CampusNet:
    def __init__(self):
        self.http = requests.Session()
        self.http.headers["User-Agent"] = "Mozilla/5.0 (compatible; cn-calsync)"
        # campusnet regularly answers 504 under load
        retry = Retry(total=4, backoff_factor=10, status_forcelist=(500, 502, 503, 504), allowed_methods=None)
        self.http.mount("https://", HTTPAdapter(max_retries=retry))
        self.session = None
        self.last = None

    def request(self, method, url, what, **kwargs):
        started = time.monotonic()
        r = self.http.request(method, url, timeout=(15, 90), **kwargs)
        self.last = r.text
        log.info("fetched %s (%d, %.1fs)", what, r.status_code, time.monotonic() - started)
        r.raise_for_status()
        return r

    def get(self, href, what):
        return self.request("GET", urljoin(BASE, href), what).text

    def page(self, prgname, arguments, what):
        url = f"{DLL}?APPNAME=CampusNet&PRGNAME={prgname}&ARGUMENTS=-N{self.session},{arguments}"
        return self.request("GET", url, what).text

    def login(self, username, password):
        link = soup(self.get(START_PAGE, "start page")).select_one("a#logIn_btn")
        if link is None:
            raise ParseError("no login link on the start page")
        form_page = self.request("GET", link["href"], "login form")
        page = soup(form_page.text)
        fields = {i.get("name"): i.get("value", "") for i in page.select("form input[type=hidden]")}
        if "__RequestVerificationToken" not in fields:
            raise ParseError("the login form has no anti-forgery token")
        form = page.find("form")
        action = urljoin(form_page.url, form.get("action") or "")
        data = {
            "ReturnUrl": fields.get("ReturnUrl", ""),
            "__RequestVerificationToken": fields["__RequestVerificationToken"],
            "Username": username,
            "Password": password,
            "RememberLogin": "false",
            "button": "login",
        }
        r = self.request("POST", action, "login", data=data)
        if urlparse(r.url).hostname != urlparse(BASE).hostname:
            raise SyncError("the identity server rejected the login; check campusnet/username and campusnet/password")
        self.session = find_session(r.headers.get("REFRESH"), r.url, r.text)
        if self.session is None:
            raise ParseError("logged in, but CampusNet handed back no session number")
        log.info("logged in")

    def logout(self):
        if self.session is None:
            return
        try:
            self.page("LOGOUT", "-N001", "logout")
        except requests.RequestException as e:
            log.warning("logout failed: %s", e)


def window(today, back, ahead):
    first = today.year * 12 + today.month - 1 - back
    return [divmod(i, 12) for i in range(first, first + back + ahead + 1)]


def fetch_appointments(cn, months):
    appts = []
    for year, month0 in months:
        month = month0 + 1
        listed, crowded = parse_month(cn.page("MONTH", f"{SCHEDULE_MENU},-A01.{month:02d}.{year},-A,-N000000000000000", f"month {year}-{month:02d}"))
        for day, href in crowded:
            # the month view cuts busy days short; the day view has all of them
            seen = {a["id"]: a for a in listed if a["date"] == day.isoformat()}
            full = parse_day(cn.get(href, f"day {day}"), day)
            for a in full:
                # the month view names "Online" rooms the day view leaves out
                if not a["rooms"] and a["id"] in seen:
                    a["rooms"] = seen[a["id"]]["rooms"]
            listed = [a for a in listed if a["date"] != day.isoformat()] + full
        exams = sum(a["kind"] == "MOFF" for a in listed)
        log.info("%d-%02d: %d appointments, %d of them exams", year, month, len(listed), exams)
        appts += listed
    return appts


def course_info(cn, appt, cache, now):
    hit = cache.get(appt["ref"])
    if hit and now - dt.datetime.fromisoformat(hit["fetched"]) < COURSE_TTL:
        return hit
    try:
        prep = parse_prep(cn.get(appt["href"], f"appointment {appt['code']} {appt['date']}"))
        info = {
            "code": prep["code"],
            "title": prep["title"],
            "type": "",
            "instructors": "; ".join(prep["instructors"]),
            "org_unit": "",
            "credits": "",
            "modules": [],
            "instructors_at": {},
        }
        if prep["details"]:
            info.update(parse_details(cn.get(prep["details"], f"course details {prep['code']}")))
    except requests.RequestException as e:
        if hit:
            log.warning("keeping cached details of %s: %s", hit["code"], e)
            return hit
        raise
    info["fetched"] = now.isoformat()
    cache[appt["ref"]] = info
    log.info("course %s %s: %s, modules %s", info["code"], info["title"], info["type"] or "type unknown", ", ".join(info["modules"]) or "none")
    return info


def exam_info(cn, appt):
    info = parse_prep(cn.get(appt["href"], f"exam {appt['code']} {appt['date']}"))
    log.info("exam %s %s on %s %s-%s", info["code"], info["title"], appt["date"], appt["start"], appt["end"])
    return info


# ---------------------------------------------------------------- events


def base_code(code):
    return re.sub(r"-[A-Z]{1,2}$", "", code)


def room_set(rooms):
    return sorted(r.strip() for room in rooms for r in re.split(r"[;,]", room) if r.strip())


def category(course_type, code):
    kind = course_type.lower()
    if "tutorial" in kind and "lecture" not in kind:
        return "tutorials"
    if "lecture" in kind:
        return "lectures"
    if kind:
        return "other"
    # no type on the details page: A is the lecture, B the tutorial
    return {"A": "lectures", "B": "tutorials"}.get(code.rsplit("-", 1)[-1], "other")


def class_summary(title, course_type, code, cat):
    word = course_type or {"lectures": "Lecture", "tutorials": "Tutorial"}.get(cat, "")
    if not word:
        return f"{title} ({base_code(code)})"
    name = re.sub(rf"\s+{re.escape(word)}s?$", "", title, flags=re.IGNORECASE)
    return f"{name} {word} ({base_code(code)})"


def overlaps(a, b):
    return a["date"] == b["date"] and a["start"] < b["end"] and b["start"] < a["end"]


def event(appt, cat, summary, rooms, details):
    return {
        "uid": f"{appt['id']}@cn-calsync",
        "category": cat,
        "summary": summary,
        "date": appt["date"],
        "start": appt["start"],
        "end": appt["end"],
        "location": ", ".join(rooms),
        "description": "\n".join(f"{k}: {v}" for k, v in details if v),
    }


def build_events(appts, courses, exams):
    """Events by uid; each exam replaces the class appointments CampusNet lists alongside it."""
    events, superseded = {}, set()
    classes = [a for a in appts if a["kind"] != "MOFF"]
    for a in (a for a in appts if a["kind"] == "MOFF"):
        exam = exams[a["id"]]
        module = exam["code"]
        rooms = exam["rooms"] or a["rooms"]
        twins = [
            c for c in classes
            if overlaps(c, a) and (module in courses[c["ref"]]["modules"] or room_set(c["rooms"]) == room_set(rooms))
        ]
        for c in twins:
            superseded.add(c["id"])
            log.info("dropped %s %s %s, superseded by exam %s", courses[c["ref"]]["code"], c["date"], c["start"], module)
        related = [courses[c["ref"]] for c in twins] + [c for c in courses.values() if module in c["modules"]]
        family = base_code(related[0]["code"]) if related else module
        m = EXAM_TITLE.match(exam["title"])
        form, name = (m["form"].strip(), m["name"].strip()) if m else ("Exam", exam["title"])
        events[f"{a['id']}@cn-calsync"] = event(a, "exams", f"[EXAM] {name} ({family})", rooms, [
            ("Exam", form),
            ("Module", f"{module} {name}"),
            ("Course", ", ".join(f"{c['code']} {c['title']}" for c in related[:1])),
            ("Instructors", "; ".join(exam["instructors"])),
        ])
    for a in classes:
        if a["id"] in superseded:
            continue
        course = courses[a["ref"]]
        cat = category(course["type"], course["code"])
        events[f"{a['id']}@cn-calsync"] = event(a, cat, class_summary(course["title"], course["type"], course["code"], cat), a["rooms"], [
            ("Type", course["type"]),
            ("Course", f"{course['code']} {course['title']}"),
            ("Instructors", course["instructors_at"].get(f"{a['date']} {a['start']}") or course["instructors"]),
            ("Module", ", ".join(course["modules"])),
            ("Credits", course["credits"]),
            ("Org-unit", course["org_unit"]),
        ])
    return events


def describe(e):
    return f"{e['date']} {e['start']}-{e['end']} {e['summary']} @ {e['location'] or '-'}"


def same(a, b):
    return all(a.get(k) == b.get(k) for k in EVENT_FIELDS)


def in_window(e, months):
    return e["date"][:7] in months


def log_diff(old, new, months):
    before = {u: e for u, e in old.items() if in_window(e, months)}
    after = {u: e for u, e in new.items() if in_window(e, months)}
    if not old:
        log.info("no previous run; publishing %d events", len(after))
        return

    def order(u):
        return (after.get(u) or before[u])["date"] + u

    added = sorted(after.keys() - before.keys(), key=order)
    removed = sorted(before.keys() - after.keys(), key=order)
    changed = sorted((u for u in after.keys() & before.keys() if not same(after[u], before[u])), key=order)
    for u in added:
        log.info("added %s", describe(after[u]))
    for u in removed:
        log.info("removed %s", describe(before[u]))
    for u in changed:
        diff = "; ".join(f"{k} {before[u].get(k)!r} -> {after[u].get(k)!r}" for k in EVENT_FIELDS if before[u].get(k) != after[u].get(k))
        log.info("changed %s: %s", describe(before[u]), diff)
    log.info("%d added, %d removed, %d changed", len(added), len(removed), len(changed))


def merge(old, fresh, months, now):
    """Fresh events replace the fetched months; earlier ones stay for a year."""
    horizon = (now - HISTORY).date().isoformat()
    kept = {u: e for u, e in old.items() if not in_window(e, months) and e["date"] >= horizon}
    for u, e in fresh.items():
        prev = old.get(u)
        e["stamp"] = prev["stamp"] if prev and "stamp" in prev and same(prev, e) else now.isoformat()
    return {**kept, **fresh}


# ---------------------------------------------------------------- output


def local(date, clock):
    return dt.datetime.combine(dt.date.fromisoformat(date), dt.time.fromisoformat(clock), tzinfo=TZ)


def render(name, color, events):
    cal = icalendar.Calendar()
    cal.add("prodid", "-//nouritsu//cn-calsync//EN")
    cal.add("version", "2.0")
    cal.add("calscale", "GREGORIAN")
    cal.add("x-wr-calname", name)
    cal.add("name", name)
    cal.add("x-wr-timezone", str(TZ))
    cal.add("refresh-interval", icalendar.vDuration(dt.timedelta(hours=6)), parameters={"VALUE": "DURATION"})
    cal.add("x-published-ttl", "PT6H")
    cal.add("color", color)
    for e in sorted(events, key=lambda e: (e["date"], e["start"], e["uid"])):
        ev = icalendar.Event()
        ev.add("uid", e["uid"])
        ev.add("dtstamp", dt.datetime.fromisoformat(e["stamp"]))
        ev.add("summary", e["summary"])
        ev.add("dtstart", local(e["date"], e["start"]))
        ev.add("dtend", local(e["date"], e["end"]))
        if e["location"]:
            ev.add("location", e["location"])
        if e["description"]:
            ev.add("description", e["description"])
        ev.add("categories", [FEEDS[e["category"]][0]])
        ev.add("color", FEEDS[e["category"]][1])
        cal.add_component(ev)
    cal.add_missing_timezones()
    return cal.to_ical()


def write_atomic(path, data, mode):
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    try:
        with os.fdopen(fd, "wb") as f:
            f.write(data)
        os.chmod(tmp, mode)
        os.replace(tmp, path)
    except BaseException:
        os.unlink(tmp)
        raise


def load_json(path):
    return json.loads(path.read_text()) if path.exists() else {}


def save_json(path, value):
    write_atomic(path, json.dumps(value, indent=1, sort_keys=True).encode(), 0o600)


def publish(root, token, events):
    # 0711: caddy can open the token's path, nobody can list it
    target = root / token
    target.mkdir(parents=True, exist_ok=True)
    os.chmod(root, 0o711)
    os.chmod(target, 0o711)
    for name, (label, color) in FEEDS.items():
        subset = [e for e in events if e["category"] == name]
        write_atomic(target / f"{name}.ics", render(f"CampusNet · {label}", color, subset), 0o644)
        log.info("wrote %s.ics with %d events", name, len(subset))
    write_atomic(target / "all.ics", render("CampusNet", "steelblue", events), 0o644)
    for stale in root.iterdir():
        if stale.is_dir() and stale != target:
            shutil.rmtree(stale)
            log.info("removed the feeds of an old token")


# ---------------------------------------------------------------- main


def credential(name, env):
    directory = os.environ.get("CREDENTIALS_DIRECTORY")
    if directory and (Path(directory) / name).is_file():
        return (Path(directory) / name).read_text().strip()
    if os.environ.get(env):
        return os.environ[env]
    raise SyncError(f"no credential {name} (systemd LoadCredential) or ${env}")


def run(args, state):
    now = dt.datetime.now(dt.timezone.utc)
    username = credential("username", "CN_USERNAME")
    password = credential("password", "CN_PASSWORD")
    if PLACEHOLDER in (username, password):
        raise SyncError("campusnet/username or campusnet/password is still the placeholder; set them with sops")
    token = None
    if not args.dry_run:
        token = credential("feed-token", "CN_FEED_TOKEN")
        if not re.fullmatch(r"[A-Za-z0-9_-]{16,}", token):
            raise SyncError("the feed token must be at least 16 characters of [A-Za-z0-9_-]")

    months = window(dt.datetime.now(TZ).date(), args.months_back, args.months_ahead)
    keys = {f"{y}-{m + 1:02d}" for y, m in months}
    cache = load_json(state / "courses.json")
    old = load_json(state / "events.json")

    cn = CampusNet()
    try:
        cn.login(username, password)
        appts = fetch_appointments(cn, months)
        courses = {a["ref"]: course_info(cn, a, cache, now) for a in appts if a["kind"] != "MOFF"}
        exams = {a["id"]: exam_info(cn, a) for a in appts if a["kind"] == "MOFF"}
        fresh = build_events(appts, courses, exams)
    except Exception:
        if cn.last and not args.dry_run:
            debug = state / "debug"
            debug.mkdir(mode=0o700, parents=True, exist_ok=True)
            write_atomic(debug / "last-failure.html", cn.last.encode(), 0o600)
            log.error("saved the last page CampusNet returned to %s", debug / "last-failure.html")
        raise
    finally:
        cn.logout()

    if not fresh and any(in_window(e, keys) for e in old.values()):
        raise SyncError("CampusNet listed nothing for months that had events last run; not publishing")

    log_diff(old, fresh, keys)
    merged = merge(old, fresh, keys, now)
    counts = {name: sum(e["category"] == name for e in merged.values()) for name in FEEDS}
    log.info("%d events in total: %s", len(merged), ", ".join(f"{n} {k}" for k, n in counts.items()))

    if args.dry_run:
        for e in sorted(merged.values(), key=lambda e: (e["date"], e["start"])):
            print(f"[{e['category']}] {describe(e)}")
        return
    save_json(state / "courses.json", cache)
    publish(state / "feeds", token, list(merged.values()))
    save_json(state / "events.json", merged)


def setup_logging(directory, verbose):
    root = logging.getLogger()
    root.setLevel(logging.DEBUG if verbose else logging.INFO)
    stderr = logging.StreamHandler()
    stderr.setFormatter(logging.Formatter("%(levelname)s %(message)s"))
    root.addHandler(stderr)
    if directory:
        file = logging.handlers.RotatingFileHandler(Path(directory) / "cn-calsync.log", maxBytes=1 << 20, backupCount=5)
        file.setFormatter(logging.Formatter("%(asctime)s %(levelname)s %(message)s"))
        root.addHandler(file)
    # urllib3 logs each retry at WARNING already
    logging.getLogger("urllib3").setLevel(logging.WARNING)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="fetch and print the events, write nothing")
    parser.add_argument("--months-back", type=int, default=int(os.environ.get("CN_MONTHS_BACK", "1")))
    parser.add_argument("--months-ahead", type=int, default=int(os.environ.get("CN_MONTHS_AHEAD", "6")))
    parser.add_argument("--verbose", action="store_true")
    args = parser.parse_args()

    setup_logging(os.environ.get("LOGS_DIRECTORY"), args.verbose)
    state = Path(os.environ.get("STATE_DIRECTORY", "cn-calsync-state"))
    log.info("sync started%s", " (dry run)" if args.dry_run else "")
    try:
        run(args, state)
    except SyncError as e:
        log.error("%s", e)
        return 1
    except Exception:
        log.exception("sync failed; the feeds are left as they were")
        return 1
    log.info("sync finished")
    return 0


if __name__ == "__main__":
    sys.exit(main())

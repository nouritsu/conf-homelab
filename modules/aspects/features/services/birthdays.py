"""Turn the birthdays, anniversaries and other dates in Radicale's address books into one ICS feed."""

import argparse
import datetime as dt
import hashlib
import json
import logging
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

import icalendar

log = logging.getLogger("birthdays")

# vCard 3 writers (Apple, DAVx⁵) give a year-less date this placeholder year
OMIT_YEAR = 1604
# a year-less date still needs a year to recur from; a leap year keeps 29 February
NO_YEAR = 2000
DATE = re.compile(r"^(?:(\d{4})|--)-?(\d{2})-?(\d{2})")
APPLE_LABEL = re.compile(r"^_\$!<(.+)>!\$_$")
ICONS = {"birthday": "🎂", "anniversary": "💍"}


class FeedError(Exception):
    """A failure worth one log line rather than a traceback."""


# ---------------------------------------------------------------- vcard


def unfold(text):
    return re.sub(r"\r?\n[ \t]", "", text).splitlines()


def parse(line):
    """`group.NAME;PARAM=x:value` -> (group, NAME, {PARAM: x}, value)."""
    quoted = False
    for i, c in enumerate(line):
        if c == '"':
            quoted = not quoted
        elif c == ":" and not quoted:
            head, value = line[:i], line[i + 1:]
            break
    else:
        return None
    name, *params = head.split(";")
    group, _, name = name.rpartition(".")
    return group.lower(), name.upper(), {k.upper(): v.strip('"') for k, _, v in (p.partition("=") for p in params)}, value


def unescape(value):
    return re.sub(r"\\(.)", lambda m: "\n" if m[1] in "nN" else m[1], value)


def cards(text):
    card = None
    for line in unfold(text):
        prop = parse(line)
        if not prop:
            continue
        name, value = prop[1], prop[3].strip().upper()
        if name == "BEGIN" and value == "VCARD":
            card = []
        elif name == "END" and value == "VCARD" and card is not None:
            yield card
            card = None
        elif card is not None:
            card.append(prop)


def display_name(card):
    def first(prop):
        return next((v for _, n, _, v in card if n == prop and v.strip(";, ")), None)

    if fn := first("FN"):
        return unescape(fn).strip()
    if n := first("N"):
        family, given, *_ = re.split(r"(?<!\\);", n) + ["", ""]
        return " ".join(unescape(p) for p in (given, family) if p).strip()
    if org := first("ORG"):
        return unescape(re.split(r"(?<!\\);", org)[0]).strip()
    return None


def date_of(value, params):
    """(year or None, month, day), or None for a date this feed can't place in a year."""
    if params.get("VALUE", "").lower() == "text":
        return None
    m = DATE.match(value.strip())
    if not m:
        return None
    year = int(m[1]) if m[1] else None
    if year is not None and (year == OMIT_YEAR or str(year) == params.get("X-APPLE-OMIT-YEAR")):
        year = None
    try:
        dt.date(year or NO_YEAR, int(m[2]), int(m[3]))
    except ValueError:
        return None
    return year, int(m[2]), int(m[3])


def dates(card):
    """(kind, label, date) for every date on a card; kind is birthday, anniversary or other."""
    labels = {g: unescape(v) for g, n, _, v in card if n == "X-ABLABEL" and g}
    for group, name, params, value in card:
        label = None
        if name == "BDAY":
            kind = "birthday"
        elif name in ("ANNIVERSARY", "X-ANNIVERSARY"):
            kind = "anniversary"
        elif name == "X-ABDATE":
            label = labels.get(group, "")
            if m := APPLE_LABEL.match(label):
                label = m[1]
            kind = "anniversary" if label.lower() == "anniversary" else "other"
        else:
            continue
        if d := date_of(value, params):
            yield kind, (label or "Date") if kind == "other" else None, d


# ---------------------------------------------------------------- storage


def address_books(root):
    for props in sorted((root / "collection-root").rglob(".Radicale.props")):
        try:
            tag = json.loads(props.read_text()).get("tag")
        except ValueError:
            continue
        if tag == "VADDRESSBOOK":
            yield props.parent


def collect(root):
    """One entry per event: anniversaries on the same date share one, as a couple would."""
    events = {}
    books = list(address_books(root))
    if not books:
        raise FeedError(f"no address books under {root}")
    count = 0
    for book in books:
        for item in sorted(p for p in book.iterdir() if p.is_file() and not p.name.startswith(".")):
            stamp = dt.datetime.fromtimestamp(item.stat().st_mtime, dt.timezone.utc).replace(microsecond=0)
            for card in cards(item.read_text(errors="replace")):
                count += 1
                name = display_name(card)
                if not name:
                    continue
                for kind, label, date in dates(card):
                    source = f"{book.name}/{item.name}"
                    key = (kind, date) if kind == "anniversary" else (kind, label, date, source)
                    e = events.setdefault(key, {"kind": kind, "label": label, "date": date, "names": [], "sources": [], "stamp": stamp})
                    if name not in e["names"]:
                        e["names"].append(name)
                    e["sources"].append(source)
                    e["stamp"] = max(e["stamp"], stamp)
    log.info("%d address books, %d cards, %d events", len(books), count, len(events))
    return list(events.values())


# ---------------------------------------------------------------- output


def summary(e):
    names = " & ".join(sorted(e["names"]))
    if e["kind"] == "other":
        return f"📅 {names}: {e['label']}"
    return f"{ICONS[e['kind']]} {names}"


def render(events):
    cal = icalendar.Calendar()
    cal.add("prodid", "-//nouritsu//birthdays//EN")
    cal.add("version", "2.0")
    cal.add("calscale", "GREGORIAN")
    cal.add("x-wr-calname", "Birthdays")
    cal.add("name", "Birthdays")
    cal.add("refresh-interval", icalendar.vDuration(dt.timedelta(hours=12)), parameters={"VALUE": "DURATION"})
    cal.add("x-published-ttl", "PT12H")
    cal.add("color", "hotpink")
    for e in sorted(events, key=lambda e: (e["date"][1:], summary(e))):
        year, month, day = e["date"]
        start = dt.date(year or NO_YEAR, month, day)
        uid = hashlib.sha256("\0".join([e["kind"], e["label"] or "", *sorted(e["sources"])]).encode()).hexdigest()[:32]
        ev = icalendar.Event()
        ev.add("uid", f"{uid}@birthdays")
        ev.add("dtstamp", e["stamp"])
        ev.add("summary", summary(e))
        ev.add("dtstart", start)
        ev.add("dtend", start + dt.timedelta(days=1))
        # the last day of February, so a 29 February date shows up in common years too
        rule = {"freq": "yearly", "bymonth": 2, "bymonthday": -1} if (month, day) == (2, 29) else {"freq": "yearly"}
        ev.add("rrule", rule)
        ev.add("transp", "TRANSPARENT")
        if year:
            ev.add("description", f"since {year}" if e["kind"] == "anniversary" else f"born {year}")
        cal.add_component(ev)
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


def credential(name):
    directory = os.environ.get("CREDENTIALS_DIRECTORY")
    if not directory or not (Path(directory) / name).is_file():
        raise FeedError(f"no credential {name} (systemd LoadCredential)")
    return (Path(directory) / name).read_text().strip()


def publish(root, token, data):
    # 0711: caddy can open the token's path, nobody can list it
    target = root / token
    target.mkdir(parents=True, exist_ok=True)
    os.chmod(root, 0o711)
    os.chmod(target, 0o711)
    write_atomic(target / "birthdays.ics", data, 0o644)
    for stale in root.iterdir():
        if stale.is_dir() and stale != target:
            shutil.rmtree(stale)
            log.info("removed the feed of an old token")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("collections", type=Path, help="radicale's storage folder, e.g. /var/lib/radicale/collections")
    parser.add_argument("--feeds", type=Path, help="publish to FEEDS/<feed-token>/birthdays.ics instead of stdout")
    args = parser.parse_args()
    logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
    try:
        data = render(collect(args.collections))
        if not args.feeds:
            sys.stdout.buffer.write(data)
            return
        token = credential("feed-token")
        if not re.fullmatch(r"[A-Za-z0-9_-]{16,}", token):
            raise FeedError("the feed token must be at least 16 characters of [A-Za-z0-9_-]")
        publish(args.feeds, token, data)
    except FeedError as e:
        log.error("%s", e)
        sys.exit(1)


if __name__ == "__main__":
    main()

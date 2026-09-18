#!/usr/bin/env fish
# Compare the working tree's homelab config against the pre-den baseline.
#
# The den migration cannot reproduce the old derivation hash: den composes
# modules by aspect graph, so `environment.systemPackages` comes out in a
# different order than the hand-written flat module list produced. The order
# carries no meaning, so this compares every derived option tree instead, with
# list-valued options compared as sorted multisets.
#
# Usage: ./scripts/compare-to-baseline.fish

set -l baseline 97b17b7d07f2eeb08be22522cb42008a8dc48fbd
set -l out (mktemp -d)

set -l apply 'c: {
  packages = builtins.sort builtins.lessThan (map (p: p.name or (toString p)) c.environment.systemPackages);
  containers = builtins.mapAttrs (n: x: {
    inherit (x) image dependsOn volumes devices environmentFiles;
    env = x.environment;
    ports = builtins.sort builtins.lessThan x.ports;
    opts = builtins.sort builtins.lessThan x.extraOptions;
  }) c.virtualisation.oci-containers.containers;
  caddy = builtins.mapAttrs (n: v: v.extraConfig) c.services.caddy.virtualHosts;
  dns = builtins.sort builtins.lessThan c.services.pihole-ftl.settings.dns.hosts;
  rathole = c.services.rathole.settings;
  creds = c.sops.templates."rathole-credentials.toml".content;
  secrets = builtins.attrNames c.sops.secrets;
  templates = builtins.attrNames c.sops.templates;
  tmpfiles = builtins.sort builtins.lessThan c.systemd.tmpfiles.rules;
  fs = c.boot.supportedFilesystems;
  kmods = builtins.sort builtins.lessThan c.boot.kernelModules;
  sysctl = c.boot.kernel.sysctl;
  users = builtins.mapAttrs (n: u: {
    inherit (u) isNormalUser extraGroups hashedPassword;
    keys = builtins.sort builtins.lessThan u.openssh.authorizedKeys.keys;
  }) c.users.users;
  groups = builtins.mapAttrs (n: g: g.gid) c.users.groups;
  timers = builtins.listToAttrs (map (n: {name = n; value = c.systemd.timers.${n}.enable;})
    (builtins.filter (n: builtins.match "restart-container-.*" n != null) (builtins.attrNames c.systemd.timers)));
  firewall = {
    tcp = builtins.sort builtins.lessThan c.networking.firewall.allowedTCPPorts;
    udp = builtins.sort builtins.lessThan c.networking.firewall.allowedUDPPorts;
  };
  fileSystems = builtins.mapAttrs (n: f: { inherit (f) device fsType; options = builtins.sort builtins.lessThan f.options; }) c.fileSystems;
  domain = c.networking.domain;
  hostName = c.networking.hostName;
  stateVersion = c.system.stateVersion;
  shell = c.users.defaultUserShell.name or "?";
}'

echo "baseline $baseline -> working tree"

nix eval --json "git+file://$PWD?rev=$baseline#nixosConfigurations.homelab.config" \
  --apply "$apply" 2>/dev/null | python3 -m json.tool --sort-keys >$out/before.json
or begin; echo "FAILED to evaluate baseline"; exit 1; end

nix eval --json ".#nixosConfigurations.homelab.config" \
  --apply "$apply" 2>/dev/null | python3 -m json.tool --sort-keys >$out/after.json
or begin; echo "FAILED to evaluate working tree"; exit 1; end

if diff -u $out/before.json $out/after.json >$out/diff
    echo "IDENTICAL - every derived option tree matches"
    rm -rf $out
    exit 0
else
    echo "DIFFERS ("(wc -l <$out/diff | string trim)" lines):"
    cat $out/diff
    echo
    echo "kept at $out"
    exit 1
end

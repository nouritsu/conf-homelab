# Anything I would want on a machine of mine, headless or not.
{den, ...}: {
  den.aspects.base.includes = with den.aspects; [
    i18n
    i18n.tz-germany
    network

    nix
    nix.cache
    nix.gc
    nix.abbrs

    ssh
    ssh.from-pc
    ssh.from-laptop
    ssh.from-pixel

    apps.core
    apps.helix
    apps.shell
    apps.starship

    secrets
  ];
}

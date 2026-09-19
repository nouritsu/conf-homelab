# Anything I would want on a machine of mine, headless or not.
{den, ...}: {
  den.aspects.base.includes = with den.aspects; [
    i18n
    i18n.tz-automatic
    network

    nix
    nix.cache

    ssh
    ssh.from-pc
    ssh.from-phone

    apps.core
    apps.fish
    apps.nh

    aneesh
    secrets
  ];
}

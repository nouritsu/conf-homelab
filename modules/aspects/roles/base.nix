# Anything I would want on a machine of mine, headless or not.
{den, ...}: {
  den.aspects.base.includes = with den.aspects; [
    locale
    auto-tz
    network

    nix-base
    nix-cache

    ssh-base
    ssh-from-pc
    ssh-from-phone

    app-core
    app-fish
    app-nh

    user-aneesh
    secrets
  ];
}

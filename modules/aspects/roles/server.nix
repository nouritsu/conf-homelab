# base, plus the container stack and the reverse proxy every service here is
# reached through.
{den, ...}: {
  den.aspects.server.includes = with den.aspects; [
    base

    filesystem.xfs
    filesystem.btrfs

    virtualization.podman
    containers

    caddy
    gluetun
    rathole
    postfix
  ];
}

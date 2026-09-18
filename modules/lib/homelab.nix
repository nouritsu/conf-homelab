# Single owner of the `den.lib.homelab` key.
#
# den.lib is declared freeform multi-writer, unlike flake-parts' flake.lib which
# is `unique raw` and can only ever be written by one module - so helpers may be
# split across files here if this one grows.
{lib, ...}: {
  den.lib.homelab = rec {
    base-domain = "nouritsu.com";
    host-ip = "192.168.178.128";

    fqdn = subdomain: "${subdomain}.${base-domain}";

    # Put a container on gluetun's network. It can publish no ports of its own;
    # the service declares them through the `gluetun-ports` quirk and gluetun
    # publishes them on its behalf.
    #
    # mkAfter keeps this flag last, after the service's own (order 1000) and the
    # --group-add the containers aspect adds at order 1400.
    via-gluetun = name: {
      virtualisation.oci-containers.containers.${name} = {
        dependsOn = ["gluetun"];
        extraOptions = lib.mkAfter ["--network=container:gluetun"];
      };
    };
  };
}

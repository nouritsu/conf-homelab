# Quirks are den's mechanism for one aspect emitting structured data that other
# aspects aggregate, without either side knowing the other exists. A service
# declares what it needs; caddy, pihole, rathole and gluetun each read the whole
# pool and build their own config from it.
{
  den.quirks.endpoint.description = ''
    A service reachable through caddy. { subdomain, port, tunnel ? false } -
    tunnel picks the rathole tunnel over a local DNS record.
  '';

  den.quirks.gluetun-ports.description = ''
    Host port mappings a service needs published on its behalf, because it
    shares gluetun's network namespace and can publish none of its own.
  '';
}

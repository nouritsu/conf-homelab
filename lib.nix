# flake-parts types `flake.lib` as `unique raw`, so exactly one module may write
# it. Mirror den.lib.homelab through it until the last `self.lib` caller is gone.
{den, ...}: {
  flake.lib = den.lib.homelab;
}

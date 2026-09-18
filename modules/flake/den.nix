{inputs, ...}: {
  imports = [inputs.den.flakeModules.default];

  # den drives flake-parts' `systems`, and its default is the set of systems
  # that have hosts - aarch64 alone. The devShell is used from the x86_64 pc,
  # so both have to be named here.
  den.systems = ["x86_64-linux" "aarch64-linux"];

  # NOT importing den.flakeModules.strict. It applies den.lib.strict to five
  # schema kinds at once, `aspect` among them, and an aspect's class keys
  # (nixos, homeManager, ...) are freeform by design - so it rejects every
  # `den.aspects.<n>.nixos = ...` in the tree. Applying it to host/user/home
  # /flake alone evaluates, but is a no-op for the case worth catching: an
  # undeclared attribute on den.hosts.<system>.<name> is absorbed by the
  # deepMergeAttrs passthrough on hostsOption before it reaches the strict
  # freeformType, so a typo'd host attribute is still accepted silently.
  # Verified both ways against den 61ed76c.
}

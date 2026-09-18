{inputs, ...}: {
  imports = [inputs.den.flakeModules.default];

  # den drives flake-parts' `systems`, and its default is the set of systems
  # that have hosts - aarch64 alone. The devShell is used from the x86_64 pc,
  # so both have to be named here.
  den.systems = ["x86_64-linux" "aarch64-linux"];
}

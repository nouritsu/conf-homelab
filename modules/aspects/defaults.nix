# Applied to every host and user den knows about, so neither has to be named
# twice: hostname reads den.hosts.<name>.hostName, define-user turns a declared
# user entity into users.users.<name>.
# system.stateVersion is per host: each one keeps the release it was installed with.
{den, ...}: {
  den.default = {
    includes = [
      den.batteries.hostname
      den.batteries.define-user
    ];
  };
}

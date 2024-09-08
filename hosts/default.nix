{
  withSystem,
  self,
  inputs,
  ...
}:
let
  inherit (builtins) readFile fromTOML;
  inherit (self.lib) pipe;
  inherit
    (pipe ./sum.toml [
      readFile
      fromTOML
    ])
    hosts
    ;
in
{
  flake.nixosConfigurations = self.lib.genAttrs hosts (
    n: import ./${n} { inherit withSystem self inputs; } # TODO: weird.. @ pattern not work here
  );
}

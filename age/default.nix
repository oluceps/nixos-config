{
  type ? "default",
}:
{
  config,
  data,
  user,
  self,
  ...
}:
{

  age = {

    rekey = {
      extraEncryptionPubkeys = [ data.keys.ageKey ];
      masterIdentities = [
        (self + "/sec/age-yubikey-identity-7d5d5540.txt.pub")
      ];
      storageMode = "local";
      localStorageDir = self + "/sec/rekeyed/${config.networking.hostName}";
    };

    secrets = (
      let
        gen =
          ns: owner: group: mode:
          self.lib.genAttrs ns (n: {
            rekeyFile = ../sec/${n}.age;
            inherit owner group mode;
          });
        hard = i: gen i "root" "users" "400";
        userRo = i: gen i user "users" "400";
        rootRo = i: gen i "root" "root" "400";
        sdnetRo = i: gen i "systemd-network" "root" "400";
        rrr = i: gen i "root" "root" "444";
        gener = {
          inherit
            hard
            userRo
            rootRo
            sdnetRo
            rrr
            ;
        };
      in
      (hard [
        "ss"
        "sing"
        "trojan-server"
        "caddy"
      ])
      // (userRo [
        "nyaw.cert"
        "nyaw.key"
        "gh-token"
      ])
      // (sdnetRo [ "wg" ])
      // (rrr [ "ntfy-token" ])
      // (if type != "default" then (import ./${type}.nix gener) else { })
    );
  };
}

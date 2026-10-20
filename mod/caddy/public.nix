{ self, ... }:
{
  flake.modules.nixos.caddy-public = {
    imports = [ self.modules.nixos.caddy ];
    realm.workloads.caddy.egress = {
      atuin = {
        service = "atuin";
        verifyID = "spiffe://nyaw.xyz/service/atuin";
      };
      immich = {
        service = "immich";
        verifyID = "spiffe://nyaw.xyz/service/immich";
      };
      immich-public-proxy = {
        service = "immich-public-proxy";
        verifyID = "spiffe://nyaw.xyz/service/immich-public-proxy";
      };
      vaultwarden = {
        service = "vaultwarden";
        verifyID = "spiffe://nyaw.xyz/service/vaultwarden";
      };
      calibre = {
        service = "calibre";
        verifyID = "spiffe://nyaw.xyz/service/calibre";
      };
      synapse = {
        service = "synapse";
        verifyID = "spiffe://nyaw.xyz/service/synapse";
      };
      meilisearch = {
        service = "meilisearch";
        verifyID = "spiffe://nyaw.xyz/service/meilisearch";
      };
      grafana = {
        service = "grafana";
        verifyID = "spiffe://nyaw.xyz/service/grafana";
      };
      misskey = {
        service = "misskey";
        verifyID = "spiffe://nyaw.xyz/service/misskey";
      };
      s3 = {
        service = "seaweedfs-s3";
        verifyID = "spiffe://nyaw.xyz/service/seaweedfs";
      };
      rustypaste = {
        service = "rustypaste";
        verifyID = "spiffe://nyaw.xyz/service/rustypaste";
      };
      # Legacy HTTP routes terminate at the internal entrypoint, rather
      # than exposing their plaintext backend ports to public entrypoints.
      internal-https = {
        service = "internal-https";
        verifyID = "spiffe://nyaw.xyz/service/caddy";
      };
    };
  };
}

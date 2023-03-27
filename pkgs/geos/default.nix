{ v2ray-geoip
, v2ray-domain-list-community
, symlinkJoin
}:
symlinkJoin {
  name = "geos";
  version = "0.0.1";

  paths = [ v2ray-domain-list-community v2ray-geoip ];

}

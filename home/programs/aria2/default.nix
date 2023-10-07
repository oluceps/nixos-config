{ user, ... }:
{
  programs.aria2 = {
    enable = true;
    settings = {
      enable-rpc = true;
      rpc-listen-port = 6800;
      rpc-allow-origin-all = true;
      rpc-listen-all = true;
      rpc-secret = "HmSu9kuMU9M=";
      disk-cache = "64M";
      continue = true;
      disable-ipv6 = false;
      no-file-allocation-limit = "64M";
      ca-certificate = "/etc/ssl/certs/ca-bundle.crt";
      always-resume = false;
      bt-tracker = "udp://tracker.opentrackr.org:1337/announce,https://tracker1.520.jp:443/announce,udp://opentracker.i2p.rocks:6969/announce,udp://open.demonii.com:1337/announce,udp://tracker.openbittorrent.com:6969/announce,http://tracker.openbittorrent.com:80/announce,udp://open.stealth.si:80/announce,udp://exodus.desync.com:6969/announce,udp://tracker.torrent.eu.org:451/announce,udp://explodie.org:6969/announce,udp://tracker1.bt.moack.co.kr:80/announce,udp://p4p.arenabg.com:1337/announce,udp://movies.zsw.ca:6969/announce,udp://uploads.gamecoast.net:6969/announce,udp://tracker2.dler.org:80/announce,udp://tracker.tiny-vps.com:6969/announce,udp://tracker.theoks.net:6969/announce,udp://tracker.4.babico.name.tr:3131/announce,udp://sanincode.com:6969/announce,udp://retracker01-msk-virt.corbina.net:80/announce";
      dir = "/home/${user}/Downloads/aria2";
    };
  };
}

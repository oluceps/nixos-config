{  user, ... }:
{
  programs.aria2 = {
    enable = true;
    settings = {
      enable-rpc = true;
      rpc-listen-port = 6800;
      rpc-secret = "HmSu9kuMU9M=";
      disk-cache = "64M";
      continue = true;
      no-file-allocation-limit = "64M";
      always-resume = false;
      bt-tracker = "http://107.189.10.20.sslip.io:7777/announce,http://1337.abcvg.info:80/announce,http://207.241.226.111:6969/announce,http://207.241.231.226:6969/announce,http://[2001:1b10:1000:8101:0:242:ac11:2]:6969/announce,http://[2a04:ac00:1:3dd8::1:2710]:2710/announce,http://bt.okmp3.ru:2710/announce,http://chouchou.top:8080/announce,http://fe.dealclub.de:6969/announce,http://fxtt.ru:80/announce,http://i-p-v-6.tk:6969/announce,http://incine.ru:6969/announce,http://ipv4announce.sktorrent.eu:6969/announce,http://ipv6.1337.cx:6969/announce,http://ipv6.govt.hu:6969/announce,http://nyaa.tracker.wf:7777/announce,http://open-v6.demonoid.ch:6969/announce,http://open.acgnxtracker.com:80/announce,http://open.acgtracker.com:1096/announce,http://open.tracker.ink:6969/announce,http://p2p.0g.cx:6969/announce,http://retracker.hotplug.ru:2710/announce,http://share.camoe.cn:8080/announce,http://t.acg.rip:6699/announce,http://torrentsmd.com:8080/announce,http://tr.cili001.com:8070/announce,http://tracker.birkenwald.de:6969/announce,http://tracker.bt4g.com:2095/announce,http://tracker.computel.fr:80/announce,http://tracker.dler.com:6969/announce,http://tracker.dler.org:6969/announce,http://tracker.edkj.club:6969/announce,http://tracker.files.fm:6969/announce,http://tracker.gbitt.info:80/announce,http://tracker.ipv6tracker.ru:80/announce,http://tracker.k.vu:6969/announce,http://tracker.lelux.fi:80/announce,http://tracker.mywaifu.best:6969/announce,http://tracker.opentrackr.org:1337/announce,http://tracker.servequake.com:9999/announce,http://tracker.skyts.net:6969/announce,http://tracker.srv00.com:6969/announce,http://tracker.swateam.org.uk:2710/announce,http://tracker2.dler.org:80/announce,http://trackme.theom.nz:80/announce,http://v6-tracker.0g.cx:6969/announce,http://vps02.net.orel.ru:80/announce,http://wepzone.net:6969/announce,http://www.all4nothin.net:80/announce.php,http://www.peckservers.com:9000/announce,http://www.wareztorrent.com:80/announce,https://1337.abcvg.info:443/announce,https://opentracker.i2p.rocks:443/announce,https://t1.hloli.org:443/announce,https://tr.abiir.top:443/announce,https://tr.abir.ga:443/announce,https://tr.burnabyhighstar.com:443/announce,https://tracker.foreverpirates.co:443/announce,https://tracker.gbitt.info:443/announce,https://tracker.imgoingto.icu:443/announce,https://tracker.jiesen.life:8443/announce,https://tracker.kuroy.me:443/announce,https://tracker.lilithraws.cf:443/announce,https://tracker.lilithraws.org:443/announce,https://tracker.loligirl.cn:443/announce,https://tracker.m-team.cc:443/announce.php,https://tracker.mlsub.net:443/announce,https://tracker.moeblog.cn:443/announce,https://tracker.nanoha.org:443/announce,https://tracker.tamersunion.org:443/announce,https://tracker1.520.jp:443/announce,https://tracker2.ctix.cn:443/announce,https://trackers.mlsub.net:443/announce,https://trackme.theom.nz:443/announce,udp://184.105.151.166:6969/announce,udp://207.241.226.111:6969/announce,udp://207.241.231.226:6969/announce,udp://52.58.128.163:6969/announce,udp://9.rarbg.com:2810/announce,udp://91.216.110.52:451/announce,udp://[2001:1b10:1000:8101:0:242:ac11:2]:6969/announce,udp://[2001:470:1:189:0:1:2:3]:6969/announce,udp://[2a03:7220:8083:cd00::1]:451/announce,udp://[2a04:ac00:1:3dd8::1:2710]:2710/announce,udp://[2a0f:e586:f:f::81]:6969/announce,udp://aarsen.me:6969/announce,udp://acxx.de:6969/announce,udp://admin.52ywp.com:6969/announce,udp://aegir.sexy:6969/announce,udp://astrr.ru:6969/announce,udp://bedro.cloud:6969/announce,udp://black-bird.ynh.fr:6969/announce,udp://boysbitte.be:6969/announce,udp://bt.ktrackers.com:6666/announce,udp://bt1.archive.org:6969/announce,udp://bt2.archive.org:6969/announce,udp://camera.lei001.com:6969/announce,udp://chouchou.top:8080/announce,udp://concen.org:6969/announce,udp://creative.7o7.cx:6969/announce,udp://cutscloud.duckdns.org:6969/announce,udp://dht.bt251.com:6969/announce,udp://epider.me:6969/announce,udp://exodus.desync.com:6969/announce,udp://fe.dealclub.de:6969/announce,udp://fh2.cmp-gaming.com:6969/announce,udp://free.publictracker.xyz:6969/announce,udp://freedom.1776.ga:6969/announce,udp://htz3.noho.st:6969/announce,udp://ipv4.tracker.harry.lu:80/announce,udp://ipv6.tracker.monitorit4.me:6969/announce,udp://laze.cc:6969/announce,udp://leet-tracker.moe:1337/announce,udp://mail.artixlinux.org:6969/announce,udp://mail.zasaonsk.ga:6969/announce,udp://mirror.aptus.co.tz:6969/announce,udp://moonburrow.club:6969/announce,udp://movies.zsw.ca:6969/announce,udp://new-line.net:6969/announce,udp://open.4ever.tk:6969/announce,udp://open.demonii.com:1337/announce,udp://open.dstud.io:6969/announce,udp://open.free-tracker.ga:6969/announce,udp://open.publictracker.xyz:6969/announce,udp://open.stealth.si:80/announce,udp://open.tracker.ink:6969/announce,udp://opentor.org:2710/announce,udp://opentracker.i2p.rocks:6969/announce,udp://p4p.arenabg.com:1337/announce,udp://private.anonseed.com:6969/announce,udp://psyco.fr:6969/announce,udp://public.publictracker.xyz:6969/announce,udp://public.tracker.vraphim.com:6969/announce,udp://qtstm32fan.ru:6969/announce,udp://rep-art.ynh.fr:6969/announce,udp://retracker.hotplug.ru:2710/announce,udp://retracker.lanta-net.ru:2710/announce,udp://run.publictracker.xyz:6969/announce,udp://sanincode.com:6969/announce,udp://slicie.icon256.com:8000/announce,udp://stargrave.org:6969/announce,udp://static.54.161.216.95.clients.your-server.de:6969/announce,udp://t.133335.xyz:6969/announce,udp://tamas3.ynh.fr:6969/announce,udp://thagoat.rocks:6969/announce,udp://themaninashed.com:6969/announce,udp://theodoric.fr:6969/announce,udp://thouvenin.cloud:6969/announce,udp://torrentclub.space:6969/announce,udp://torrents.artixlinux.org:6969/announce,udp://tr.bangumi.moe:6969/announce,udp://tr.cili001.com:8070/announce,udp://tracker-udp.gbitt.info:80/announce,udp://tracker.4.babico.name.tr:3131/announce,udp://tracker.altrosky.nl:6969/announce,udp://tracker.artixlinux.org:6969/announce,udp://tracker.auctor.tv:6969/announce,udp://tracker.beeimg.com:6969/announce,udp://tracker.birkenwald.de:6969/announce,udp://tracker.bitsearch.to:1337/announce,udp://tracker.cyberia.is:6969/announce,udp://tracker.ddunlimited.net:6969/announce,udp://tracker.dler.com:6969/announce,udp://tracker.dler.org:6969/announce,udp://tracker.filemail.com:6969/announce,udp://tracker.jonaslsa.com:6969/announce,udp://tracker.joybomb.tw:6969/announce,udp://tracker.leech.ie:1337/announce,udp://tracker.lelux.fi:6969/announce,udp://tracker.moeking.me:6969/announce,udp://tracker.monitorit4.me:6969/announce,udp://tracker.openbittorrent.com:6969/announce,udp://tracker.openbtba.com:6969/announce,udp://tracker.opentrackr.org:1337/announce,udp://tracker.pimpmyworld.to:6969/announce,udp://tracker.pomf.se:80/announce,udp://tracker.publictracker.xyz:6969/announce,udp://tracker.qu.ax:6969/announce,udp://tracker.skynetcloud.site:6969/announce,udp://tracker.skyts.net:6969/announce,udp://tracker.srv00.com:6969/announce,udp://tracker.swateam.org.uk:2710/announce,udp://tracker.tcp.exchange:6969/announce,udp://tracker.theoks.net:6969/announce,udp://tracker.tiny-vps.com:6969/announce,udp://tracker.torrent.eu.org:451/announce,udp://tracker.yangxiaoguozi.cn:6969/announce,udp://tracker1.bt.moack.co.kr:80/announce,udp://tracker1.myporn.club:9337/announce,udp://tracker2.dler.com:80/announce,udp://tracker2.dler.org:80/announce,udp://trackerb.jonaslsa.com:6969/announce,udp://u4.trakx.crim.ist:1337/announce,udp://u6.trakx.crim.ist:1337/announce,udp://uploads.gamecoast.net:6969/announce,udp://v1046920.hosted-by-vdsina.ru:6969/announce,udp://v2.iperson.xyz:6969/announce,udp://wepzone.net:6969/announce,udp://www.peckservers.com:9000/announce,udp://www.torrent.eu.org:451/announce,udp://zecircle.xyz:6969/announce,ws://hub.bugout.link:80/announce,wss://tracker.openwebtorrent.com:443/announce";
      dir = "/home/${user}/Downloads";
    };
  };



}

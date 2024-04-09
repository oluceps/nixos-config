{ ... }:
{
  enable = true;
  config = ''
    # main config for srs.
    # @see full.conf for detail config.

    listen              1935;
    max_connections     1000;
    srs_log_tank        console;
    daemon              off;
    pid /run/srs.pid;

    http_api {
        enabled         on;
        listen          1985;
    }
    http_server {
        enabled         on;
        listen          8080;
        dir             ./objs/nginx/html;
    }
    rtc_server {
        enabled on;
        listen 8000; # UDP port
        # @see https://ossrs.net/lts/zh-cn/docs/v4/doc/webrtc#config-candidate
        candidate $CANDIDATE;
    }
    vhost __defaultVhost__ {
        hls {
            enabled         on;
        }
        http_remux {
            enabled     on;
            mount       [vhost]/[app]/[stream].flv;
        }
        rtc {
            enabled     on;
            # @see https://ossrs.net/lts/zh-cn/docs/v4/doc/webrtc#rtmp-to-rtc
            rtmp_to_rtc off;
            # @see https://ossrs.net/lts/zh-cn/docs/v4/doc/webrtc#rtc-to-rtmp
            rtc_to_rtmp off;
        }

        play{
            gop_cache_max_frames 2500;
        }
    }
  '';
}

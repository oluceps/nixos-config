{ pkgs, reIf, ... }:
reIf {
  services.alloy = {
    enable = true;
  };
  environment.etc."alloy/config.alloy".text = ''
    loki.process "journal" {
    	forward_to = [loki.write.default.receiver]

    	stage.match {
    		selector = "{facility=\"kern\"} |= \"NFT_VM_FORWARD_LOG\""

    		stage.regex {
    			expression = "\\sSRC=(?P<src>.*?)\\s"
    		}

    		stage.regex {
    			expression = "\\sDST=(?P<dst>.*?)\\s"
    		}

    		stage.geoip {
    			db      = "${
         pkgs.fetchurl {
           url = "https://github.com/P3TERX/GeoLite.mmdb/releases/download/2025.09.16/GeoLite2-City.mmdb";
           hash = "sha256-b9IhwKmT2kRy7YhD18LtzKc2okuv5YYsPvqJoLfA03M=";
         }
       }"
    			source  = "src"
    			db_type = "city"
    		}

    	}
    }

    discovery.relabel "journal" {
    	targets = []

    	rule {
    		source_labels = ["__journal__systemd_unit"]
    		target_label  = "unit"
    	}
    }

    loki.source.journal "journal" {
    	max_age       = "12h0m0s"
    	relabel_rules = discovery.relabel.journal.rules
    	forward_to    = [loki.process.journal.receiver]
    	labels        = {
    		host = "vm1",
    		job  = "systemd-journal",
    	}
    }

    loki.write "default" {
    	endpoint {
    		url = "http://loki:3100/loki/api/v1/push"
    	}
    	external_labels = {}
    }
  '';
}

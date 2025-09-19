{ pkgs, reIf, ... }:
reIf {
  services.alloy = {
    enable = true;
  };
  environment.etc."alloy/config.alloy".text = ''
    livedebugging {
      enabled = true
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
    	forward_to    = [loki.write.default.receiver]
    	labels        = {
    		host = "vm1",
    		job  = "systemd-journal",
    	}
    }

    loki.write "default" {
    	endpoint {
    		url = "http://[fdcc::1]:3030/loki/api/v1/push"
    	}
    	external_labels = {}
    }
  '';
}

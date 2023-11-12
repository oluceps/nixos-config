{ inputs, pkgs, ... }: {
  programs.anyrun = {
    enable = true;
    config = {
      plugins = [
        inputs.anyrun.packages.${pkgs.system}.applications
        # "libapplications.so"
      ];
      x.fraction = 0.5;
      y.absolute = 200;
      width.absolute = 800;
      height.absolute = 0;
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = true;
      closeOnClick = false;
      showResultsImmediately = true;
      maxEntries = null;
    };
    extraCss = ''
      #window {
        background-color: rgba(0, 0, 0, 0);
        font-size: 20px;
        color: rgba(255,255,255,1.000);
      }

      #entry {
        background-color: rgba(0, 0, 0, 0.7);
        color: rgba(255,255,255,1.000);
        padding-top: 10px;
        padding-bottom: 10px;
        border-radius: 0px;
        box-shadow: 5px 5px 10px rgba(0, 0, 0, 0.7);  
        caret-color: rgba(0, 0, 0, 0);
        border-width: 1px;
        border-style: solid;
        border-top-style: solid;
        border-bottom-style: solid;
        border-color: rgba(0, 0, 0, 0.7);
        margin: 10px;
        margin-bottom: -10px;
        padding: 20px;
        border-bottom-color: rgba(255,255,255,1);
      }

      #match {
        color: rgba(255,255,255,1.000);
      }

      box#main {
        border-radius: 10px;
        background-color: rgba(0, 0, 0, 0);

      }

      list#main {
        background-color: rgba(0, 0, 0, 0.7);
        border-color: rgba(0, 0, 0, 0);
        box-shadow: 5px 5px 10px rgba(0, 0, 0, 0.7);  
        margin: 10px;
      }

      list#main row:selected {
        background-color: rgba(255, 255, 255, 0.7);
      }


      list#plugin {
        background-color: rgba(0, 0, 0, 0);
      }

      label#match-desc {
        font-size: 10px;
      }

      label#plugin {
        font-size: 14px;
      }
    '';
  };
}

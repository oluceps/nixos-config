{ inputs, pkgs, ... }: {
  programs.anyrun = {
    enable = true;
    config = {
      plugins = with inputs.anyrun.packages.${pkgs.system}; [
        applications
        # randr
        rink
        shell
        symbols
        dictionary
      ];

      width.fraction = 0.3;
      y.absolute = 200;
      hidePluginInfo = true;
      closeOnClick = true;
      hideIcons = true;
      showResultsImmediately = false;
    };
    extraCss = ''
      * {
        all: unset;
        font-size: 1.3rem;
        color: black;
      }

      #window,
      #match,
      #entry,
      #plugin,
      #main {
        background: transparent;
      }

      #match.activatable {
        border-radius: 16px;
        padding: 0.3rem 0.9rem;
        margin-top: 0.01rem;
      }
      #match.activatable:first-child {
        margin-top: 0.7rem;
      }
      #match.activatable:last-child {
        margin-bottom: 0.6rem;
      }

      #plugin:hover #match.activatable {
        border-radius: 10px;
        padding: 0.3rem;
        margin-top: 0.01rem;
        margin-bottom: 0;
      }

      #match:selected,
      #match:hover,
      #plugin:hover {
        background: rgba(255, 255, 255, 0.3);
      }

      #entry {
        background: rgba(255, 255, 255, 0.3);
        border: 1px solid rgba(0, 0, 0, 0.1);
        border-radius: 16px;
        margin: 0.5rem;
        padding: 0.3rem 1rem;
      }

      #match:selected,
      #match:hover {
        box-shadow: 0 1px 5px -5px rgba(0, 0, 0, 0.5);
      }

      list > #plugin {
        border-radius: 16px;
        margin: 0 0.3rem;
      }
      list > #plugin:first-child {
        margin-top: 0.3rem;
      }
      list > #plugin:last-child {
        margin-bottom: 0.3rem;
      }
      list > #plugin:hover {
        padding: 0.6rem;
      }

      box#main {
        background: rgba(255, 255, 255, 0.5);
        box-shadow:
          0 0 0 1px rgba(0, 0, 0, 0.1),
          inset 0 0 0 1px rgba(255, 255, 255, 0.1);
        border-radius: 24px;
        padding: 0.3rem;
      }
    '';
  };
}

{ withSystem, inputs, ... }:
let
  envoyOverlay =
    final: prev:
    let
      version = "1.40.0";
      releases = {
        x86_64-linux = {
          arch = "x86_64";
          hash = "sha256-iqE3p9AJlM5D9hNVb1oSBwkin2O+24bu3eXMvEAsK4A=";
        };
        aarch64-linux = {
          arch = "aarch_64";
          hash = "sha256-A8rMlSVhY1wLfSqCkpHzQdrb68MgUEde++cyGxu+GMI=";
        };
      };
      release = releases.${final.stdenv.hostPlatform.system};
    in
    {
      envoy = final.stdenvNoCC.mkDerivation {
        pname = "envoy";
        inherit version;
        # 1.40 switched to bzlmod; use the upstream release with a pinned digest.
        src = final.fetchurl {
          url = "https://github.com/envoyproxy/envoy/releases/download/v${version}/envoy-${version}-linux-${release.arch}";
          inherit (release) hash;
        };
        dontUnpack = true;
        dontStrip = true;
        nativeBuildInputs = [ final.autoPatchelfHook ];
        buildInputs = [ final.stdenv.cc.cc.lib ];
        installPhase = ''
          runHook preInstall
          install -Dm755 "$src" "$out/bin/envoy"
          runHook postInstall
        '';
        meta = prev.envoy.meta // {
          changelog = "https://github.com/envoyproxy/envoy/releases/tag/v${version}";
          platforms = builtins.attrNames releases;
          sourceProvenance = [ final.lib.sourceTypes.binaryNativeCode ];
        };
      };
    };
in
{
  flake.overlays.envoy = envoyOverlay;
  flake.modules.nixos.overlay =
    # Go: https://github.com/NixOS/nixpkgs/issues/86349#issuecomment-624489806
    # Rust:
    {
      nixpkgs.overlays = (
        withSystem "x86_64-linux" (
          { inputs', ... }:
          (map
            (
              i:
              if inputs.${i}.overlays ? "default" then inputs.${i}.overlays.default else inputs.${i}.overlays.${i}
            )
            [
              "fenix"
              "nuenv"
              "dae"
              "niri"
              "nix-cachyos-kernel"
              "run0-sudo-shim"
            ]
          )
          ++ [
            (
              final: prev:
              (prev.lib.genAttrs [
                "prismlauncher"
                "resign"
                "nix-direnv"
                # "radicle"
                "xwayland-satellite"
                # "atuin"
                "vicinae"
              ] (n: inputs'.${n}.packages.default))

              // {
                inherit (inputs'.browser-previews.packages) google-chrome-beta;
                inherit (inputs'.nixpkgs-stable.legacyPackages) calibre-web wayprompt;
                # foot = prev.foot.overrideAttrs (o: {
                #   version = "1.26.0-ecf3";
                #   src = prev.fetchFromCodeberg {
                #     owner = "dnkl";
                #     repo = "foot";
                #     rev = "ecf3b864e461bf6bf5033ac794cc6109013cd816";
                #     hash = "sha256-TbeDUJkdkz8IVAnSnf75gvVhGxwcMOizpSGSHq6rKrM=";
                #   };
                # });
                # telegram-desktop = prev.telegram-desktop.override {
                #   unwrapped = prev.telegram-desktop.unwrapped.overrideAttrs (old: {
                #     patches = (old.patches or [ ]) ++ [ ./tdesktop-focus.patch ];
                #   });
                # };
                # sing-box = prev.sing-box.overrideAttrs (o: {
                #   version = prev.sing-box.version + "-mldsa65";
                #   src = prev.fetchFromGitHub {
                #     owner = "oluceps";
                #     repo = "sing-box";
                #     rev = "a7a37926c8dd0934ea8e9b201913eeaf86b3cc9d";
                #     hash = "sha256-an99ek6YExBpqd9tlyXJO/flLECJbcC9Fl3DgCGra2Q=";
                #   };
                #   vendorHash = "sha256-5ou+KtnnZSPwr+wGhTZADD6rpC53pYi0KAhjHJ3Bqv0=";
                # });
              }
            )
          ]
        )
        ++ [
          inputs.self.overlays.default
          envoyOverlay
          inputs.nix-topology.overlays.default
          inputs.nix-minecraft.overlay
        ]
      );
    };
}

# flake + home-manager NixOS configurations

Home managing with [home-manager](https://github.com/nix-community/home-manager)  
Secrets managing with [agenix](https://github.com/ryantm/agenix)  

## Contents
+ hosts: host-specific configuration  
+ home: home-manager config  
+ modules: as its name  
+ modules/packs: self-packaged softwares


## Usage
flake outputs:  

```console
> nix flake show github:oluceps/nixos-config
github:oluceps/nixos-config/d60a21a4d40a779f40b484bb9ef2445372bbfe34
└───nixosConfigurations
    ├───hastur: NixOS configuration
    └───kaambl: NixOS configuration
```  

### NixOS Deployment

```console
nixos-rebuild switch --flake github:oluceps/nixos-config#hastur
  
```
|Type|Program|
|---|---|
|Editor|[helix](https://github.com/oluceps/nixos-config/tree/pub/home/programs/helix)|
|WM|[sway](https://github.com/oluceps/nixos-config/tree/pub/home/programs/sway)|
|Shell|[fish](https://github.com/oluceps/nixos-config/tree/pub/home/programs/fish)|
|Bar|[waybar](https://github.com/oluceps/nixos-config/tree/pub/home/programs/waybar)|
|Terminal|[wezterm](https://github.com/oluceps/nixos-config/tree/pub/home/programs/wezterm)|

## Resources  
Excellent configurations that I've learned and copied:  
+ [NickCao/flakes](https://github.com/NickCao/flakes)  
+ [ocfox/nixos-config](https://github.com/ocfox/nixos-config)  
+ [Clansty/flake](https://github.com/Clansty/flake)  
+ [fufexan/dotfiles](https://github.com/fufexan/dotfiles)  
+ [gvolpe/nix-config](https://github.com/gvolpe/nix-config)


## Screenshot  
![screenshot](./screenshot.png)

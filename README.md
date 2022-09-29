# flake + home-manager NixOS configurations

Home managing with [home-manager](https://github.com/nix-community/home-manager)  
Secrets managing with [agenix](https://github.com/ryantm/agenix)  


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


## Contents
+ hosts: host-specific configuration  
+ home: home-manager config  
+ modules: as its name  
+ modules/packs: self-packaged softwares


## Directory structure  
```console  
> tree
.
├── boot.nix
├── flake.lock
├── flake.nix
├── home
│   ├── default.nix
│   ├── home.nix
│   └── programs
│       ├── bspwm
│       │   ├── bspwmrc
│       │   ├── default.nix
│       │   └── sxhkdrc
│       ├── chrome
│       │   └── default.nix
│       ├── default.nix
│       ├── fish
│       │   └── default.nix
│       ├── helix
│       │   ├── config
│       │   │   ├── config.toml
│       │   │   ├── languages.toml
│       │   │   └── themes
│       │   │       └── catppuccin_macchiato.toml
│       │   └── default.nix
│       ├── kitty.nix
│       ├── nnn.nix
│       ├── nushell
│       │   ├── config.nu
│       │   ├── default.nix
│       │   └── env.nu
│       ├── ranger
│       │   └── default.nix
│       ├── starship.nix
│       ├── sway
│       │   └── default.nix
│       ├── waybar
│       │   ├── default.nix
│       │   └── waybar.css
│       └── wezterm
│           ├── catppuccin.lua
│           ├── default.nix
│           └── wezterm.lua
├── hosts
│   ├── default.nix
│   ├── hastur
│   │   ├── default.nix
│   │   ├── hardware.nix
│   │   └── network.nix
│   └── kammbl
│       ├── default.nix
│       ├── hardware.nix
│       └── network.nix
├── misc.nix
├── modules
│   ├── blog
│   │   └── default.nix
│   ├── clash-m
│   │   ├── default.nix
│   │   └── result -> /nix/store/kxzdgmar75jq51d1nkrkchc88k9w03zx-clash-meta-1.13.1
│   ├── default.nix
│   ├── foot
│   │   └── foot.ini
│   ├── hyprland
│   │   ├── config.nix
│   │   └── default.nix
│   ├── hysteria
│   │   ├── config.nix
│   │   └── default.nix
│   ├── nvim
│   │   ├── init.lua
│   │   └── lua
│   │       ├── basic.lua
│   │       ├── colorscheme.lua
│   │       ├── keybindings.lua
│   │       ├── lsp
│   │       │   ├── cmp.lua
│   │       │   ├── config
│   │       │   │   ├── bash.lua
│   │       │   │   ├── c.lua
│   │       │   │   ├── css.lua
│   │       │   │   ├── emmet.lua
│   │       │   │   ├── go.lua
│   │       │   │   ├── html.lua
│   │       │   │   ├── json.lua
│   │       │   │   ├── latex.lua
│   │       │   │   ├── lua.lua
│   │       │   │   ├── markdown.lua
│   │       │   │   ├── pyright.lua
│   │       │   │   ├── rnix.lua
│   │       │   │   ├── rust.lua
│   │       │   │   ├── toml.lua
│   │       │   │   ├── ts.lua
│   │       │   │   └── yamlls.lua
│   │       │   ├── formatter.lua
│   │       │   ├── null-ls.lua
│   │       │   ├── setup.lua
│   │       │   └── ui.lua
│   │       └── plugin-config
│   │           ├── bufferline.lua
│   │           ├── catppuccin.lua
│   │           ├── comment.lua
│   │           ├── dashboard.lua
│   │           ├── fidget.lua
│   │           ├── gitsigns.lua
│   │           ├── indent-blankline.lua
│   │           ├── lualine.lua
│   │           ├── nvim-autopairs.lua
│   │           ├── nvim-treesitter.lua
│   │           ├── project.lua
│   │           ├── surround.lua
│   │           ├── telescope.lua
│   │           └── toggleterm.lua
│   ├── packs
│   │   ├── clash-m
│   │   │   └── default.nix
│   │   ├── clash-p
│   │   │   └── default.nix
│   │   ├── glowsans
│   │   │   └── default.nix
│   │   ├── Graphite-cursors
│   │   │   ├── default.nix
│   │   │   └── result -> /nix/store/p0ma20yqzlmvmnzk6wfdp1p7a0vhhsaa-Graphite-cursors-2021-11-26
│   │   ├── maple-font
│   │   │   ├── default.nix
│   │   │   ├── result -> /nix/store/pmy11x6hqqbfdqvnfnzvnsi0gir31abm-MapleMono-NF-5.5
│   │   │   └── result-2 -> /nix/store/vik3wgcwmlk8yqa202xrkg173p2klnsn-MapleMono-5.5
│   │   ├── opensk-udev-rules
│   │   │   └── default.nix
│   │   ├── plangothic
│   │   │   ├── default.nix
│   │   │   └── result -> /nix/store/4k7ww8i79j1c27s9nkvmb0q6gs0k9sn2-plangothic-font-0.5.5694
│   │   ├── RustPlayer
│   │   │   ├── default.nix
│   │   │   └── result -> /nix/store/pdrgp01yzpp0018hjc7vljfx06kkfkas-RustPlayer-d37026dcc3c0b77e527b8e3e814de7e5be894d46
│   │   ├── san-francisco
│   │   │   ├── default.nix
│   │   │   └── result -> /nix/store/xdha819h50jp8hf97bspjgm814r8vznz-san-francisco-53ffbe571bb83dbb4835a010b4a49ebb9a32fc55
│   │   ├── sing-box
│   │   │   └── default.nix
│   │   └── v2ray-plugin
│   │       └── default.nix
│   ├── polybar
│   │   ├── config.ini
│   │   └── default.nix
│   ├── sing-box
│   │   └── default.nix
│   └── ss
│       └── default.nix
├── overlay.nix
├── packages.nix
├── secrets
│   ├── secrets.nix
│   ├── sing.age
│   └── ssconf.age
├── services.nix
├── shell.nix
├── sysvars.nix
└── users.nix

46 directories, 111 files
```  

## Screenshot  
![screenshot](./screenshot.png)


## Resources  
Excellent configurations that I've learned and copied:  
+ [NickCao/flakes](https://github.com/NickCao/flakes)  
+ [ocfox/nixos-config](https://github.com/ocfox/nixos-config)  
+ [Clansty/flake](https://github.com/Clansty/flake)  
+ [fufexan/dotfiles](https://github.com/fufexan/dotfiles)  
+ [gvolpe/nix-config](https://github.com/gvolpe/nix-config)



# Nix flake

Home managing with [home-manager](https://github.com/nix-community/home-manager)  
Secrets managing with [agenix](https://github.com/ryantm/agenix)  
Secure boot with [lanzaboote](https://github.com/nix-community/lanzaboote)  
Root-On-Tmpfs persistence with [impermanence](https://github.com/nix-community/impermanence)  

## May be helpful
[Erase your darlings](https://grahamc.com/blog/erase-your-darlings)  
[NixOS: tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/)  
[How to Learn Nix](https://ianthehenry.com/posts/how-to-learn-nix/)  
[Attrset functions](https://ryantm.github.io/nixpkgs/functions/library/attrsets/)  
[List manipulation functions](https://ryantm.github.io/nixpkgs/functions/library/lists/)  
[Way to search function](http://noogle.dev)  

## How to use
> Follow Nix official guide to initialize NixOS first.  

flake outputs:  
<details>
<summary>Full</summary>

```console
> nix flake show
warning: Git tree '/etc/nixos' is dirty
git+file:///etc/nixos
├───devShells
│   ├───aarch64-linux
│   │   ├───android: development environment 'android-env-shell'
│   │   ├───default: development environment 'python-env'
│   │   ├───eunomia: development environment 'eunomia-dev'
│   │   ├───general: development environment 'generalEnv'
│   │   ├───kernel: development environment 'kernel-build-env-shell-env'
│   │   ├───mips: development environment 'nix-shell-mipsel-unknown-linux-gnu'
│   │   ├───ml: development environment 'machine-learning'
│   │   ├───openwrt: development environment 'openwrt-build-env-shell-env'
│   │   └───rv: development environment 'linux-riscv64-unknown-linux-gnu-5.15.91'
│   └───x86_64-linux
│       ├───android: development environment 'android-env-shell'
│       ├───default: development environment 'python-env'
│       ├───eunomia: development environment 'eunomia-dev'
│       ├───general: development environment 'generalEnv'
│       ├───kernel: development environment 'kernel-build-env-shell-env'
│       ├───mips: development environment 'nix-shell-mipsel-unknown-linux-gnu'
│       ├───ml: development environment 'machine-learning'
│       ├───openwrt: development environment 'openwrt-build-env-shell-env'
│       └───rv: development environment 'linux-riscv64-unknown-linux-gnu-5.15.91'
├───nixosConfigurations
│   ├───hastur: NixOS configuration
│   ├───kaambl: NixOS configuration
│   └───livecd: NixOS configuration
└───overlays
    └───default: Nixpkgs overlay
```  
</details>

### NixOS Deployment

__Before deployment, adjust configurations manually__

Optional: replace hostname globally with:    
```console  
sed -i "s/hastur/YOUR_HOSTNAME/g" `rg -rl "hastur" ./`  
```


```console
nixos-rebuild switch --flake github:oluceps/nixos-config#<hostname>
  
```
|Type|Program|
|---|---|
|Editor|[helix](https://github.com/oluceps/nixos-config/tree/pub/home/programs/helix)|
|WM|[Hyprland](https://github.com/oluceps/nixos-config/tree/pub/home/programs/hyprland)|
|Shell|[fish](https://github.com/oluceps/nixos-config/tree/pub/home/programs/fish)|
|Bar|[waybar](https://github.com/oluceps/nixos-config/tree/pub/home/programs/waybar)|
|Terminal|[foot](https://github.com/oluceps/nixos-config/tree/pub/home/programs/foot)|
|backup|[btrbk](https://github.com/oluceps/nixos-config/tree/pub/modules/btrbk)|  

__Build devShell__  
```console
nix develop .#devShells.<Arch>.<Shell>
```   

__Build livecd__  
```console
nix build .#nixosConfigurations.livecd.config.system.build.isoImage
```

__Use Overlay__  

> Since this flake contains overlay of few packages (check ./pkgs),to use these packages:  

Add to your flake:  

    inputs.oluceps = "github:oluceps/nixos-config";

Pass overlay while importing nixpkgs:  

    overlays = [ inputs.oluceps.overlay ];


## Contents
+ hosts: host-specific configuration  
+ home: home-manager config  
+ modules: modules  
+ pkgs: packaged softwares


## Directory structure  
<details>
<summary>Full</summary>

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
│       ├── alacritty
│       │   ├── alacritty.yml
│       │   └── default.nix
│       ├── aria2
│       │   └── default.nix
│       ├── bspwm
│       │   ├── bspwmrc
│       │   ├── default.nix
│       │   └── sxhkdrc
│       ├── btop
│       │   └── default.nix
│       ├── chrome
│       │   └── default.nix
│       ├── default.nix
│       ├── fish
│       │   └── default.nix
│       ├── helix
│       │   ├── config
│       │   │   ├── clang-format.nix
│       │   │   ├── languages.nix
│       │   │   └── themes
│       │   │       └── catppuccin_macchiato.toml
│       │   └── default.nix
│       ├── hyprland
│       │   ├── config.nix
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
│       ├── tmux
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
│   │   ├── network.nix
│   │   ├── persist.nix
│   │   └── secureboot.nix
│   ├── kaambl
│   │   ├── default.nix
│   │   ├── hardware.nix
│   │   └── network.nix
│   ├── livecd
│   │   ├── default.nix
│   │   ├── home.nix
│   │   └── network.nix
│   └── shares.nix
├── misc.nix
├── modules
│   ├── aria2
│   ├── blog
│   │   └── default.nix
│   ├── btrbk
│   │   └── default.nix
│   ├── clash-m
│   │   └── default.nix
│   ├── default.nix
│   ├── foot
│   │   └── foot.ini
│   ├── hysteria
│   │   └── default.nix
│   ├── hysteria-do
│   │   └── default.nix
│   ├── naive
│   │   └── default.nix
│   ├── polybar
│   │   ├── config.ini
│   │   └── default.nix
│   ├── shadow-tls
│   ├── sing-box
│   │   └── default.nix
│   ├── ss
│   │   └── default.nix
│   └── tuic
│       └── default.nix
├── overlay.nix
├── packages
│   ├── clash-m
│   │   └── default.nix
│   ├── clash-p
│   │   └── default.nix
│   ├── glowsans
│   │   └── default.nix
│   ├── Graphite-cursors
│   │   └── default.nix
│   ├── hysteria
│   │   └── default.nix
│   ├── maple-font
│   │   └── default.nix
│   ├── opensk-udev-rules
│   │   └── default.nix
│   ├── plangothic
│   │   └── default.nix
│   ├── RustPlayer
│   │   └── default.nix
│   ├── san-francisco
│   │   └── default.nix
│   ├── shadow-tls
│   │   └── default.nix
│   ├── sing-box
│   │   └── default.nix
│   ├── TDesktop-x64
│   │   └── default.nix
│   └── v2ray-plugin
│       └── default.nix
├── packages.nix
├── secrets
│   ├── hyst.age
│   ├── hyst-do.age
│   ├── naive.age
│   ├── secrets.nix
│   ├── sing.age
│   ├── ss.age
│   └── tuic.age
├── services.nix
├── shells.nix
├── sysvars.nix
└── users.nix

52 directories, 89 files
```  
</details>

## Screenshot  
![screenshot](./screenshots/shot_1.png)
 
Background picture from [Ramiro Martinez](https://unsplash.com/@ramiro250)  

## Resources  
Excellent configurations that I've learned and copied:  
+ [NickCao/flakes](https://github.com/NickCao/flakes)  
+ [ocfox/nixos-config](https://github.com/ocfox/nixos-config)  
+ [Clansty/flake](https://github.com/Clansty/flake)  
+ [fufexan/dotfiles](https://github.com/fufexan/dotfiles)  
+ [gvolpe/nix-config](https://github.com/gvolpe/nix-config)

[NixOS-CN-telegram](https://github.com/nixos-cn/NixOS-CN-telegram)



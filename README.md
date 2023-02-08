# flake + home-manager Configurations

Home managing with [home-manager](https://github.com/nix-community/home-manager)  
Secrets managing with [agenix](https://github.com/ryantm/agenix)  
Secure boot with [lanzaboote](https://github.com/nix-community/lanzaboote)  
Root-On-Tmpfs persistence with [impermanence](https://github.com/nix-community/impermanence)  


## Usage
flake outputs:  

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
    └───oluceps: Nixpkgs overlay
```  

### NixOS Deployment

__Before deployment, adjust configurations manually__

Optionally replace hostname globally with:    
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
|Terminal|[alacritty](https://github.com/oluceps/nixos-config/tree/pub/home/programs/alacritty)|
|backup|[btrbk](https://github.com/oluceps/nixos-config/tree/pub/modules/btrbk)|  

_Build devShell:_  
```console
nix develop .#devShells.<Arch>.<Shell>
```   

_Build livecd:_

```console
nix build .#nixosConfigurations.livecd.config.system.build.isoImage
```



## Contents
+ hosts: host-specific configuration  
+ home: home-manager config  
+ modules: modules  
+ packages: packaged softwares


## Directory structure  
<details>
<summary>Full</summary>

```console  
> exa --tree --level=2
.
├── boot.nix
├── flake.lock
├── flake.nix
├── home
│  ├── default.nix
│  ├── home.nix
│  └── programs
├── hosts
│  ├── default.nix
│  ├── hastur
│  ├── kaambl
│  ├── livecd
│  └── shares.nix
├── misc.nix
├── modules
│  ├── aria2
│  ├── blog
│  ├── btrbk
│  ├── clash-m
│  ├── default.nix
│  ├── foot
│  ├── hysteria
│  ├── hysteria-do
│  ├── naive
│  ├── polybar
│  ├── shadow-tls
│  ├── sing-box
│  ├── ss
│  └── tuic
├── overlay.nix
├── packages
│  ├── clash-m
│  ├── clash-p
│  ├── glowsans
│  ├── Graphite-cursors
│  ├── hysteria
│  ├── maple-font
│  ├── opensk-udev-rules
│  ├── plangothic
│  ├── RustPlayer
│  ├── san-francisco
│  ├── shadow-tls
│  ├── sing-box
│  ├── TDesktop-x64
│  └── v2ray-plugin
├── packages.nix
├── secrets
│  ├── hyst-do.age
│  ├── hyst.age
│  ├── naive.age
│  ├── secrets.nix
│  ├── sing.age
│  ├── ss.age
│  └── tuic.age
├── services.nix
├── shells.nix
├── sysvars.nix
└── users.nix
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



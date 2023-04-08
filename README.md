![CI state](https://github.com/oluceps/nixos-config/actions/workflows/eval.yaml/badge.svg)

![screenshot](./.attachs/shot_2.png)

<details>

![screenshot](./.attachs/shot_1.png)

</details>

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
[NixOS CN DOC](https://github.com/OpenTritium/NixOS-CN-DOC)  

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

This flake contains overlay of few packages (check ./pkgs), to apply:  

Add to your flake, passing overlay while importing nixpkgs:  
```nix
# flake.nix
{
  inputs.oluceps.url = "github:oluceps/nixos-config";
  outputs = inputs: {
    nixosConfigurations.machine-name = {
    # ...
    modules = [
      # ...
      {
        nixpkgs.overlays = [ inputs.oluceps.overlay ];
        # packages in `pkgs` dir of this repo,
        # with pname consist with dir name
        environment.systemPackages = [ pkgs.shadow-tls ];
      }
    ];
  };
};
}
```

## Contents
+ hosts: host-specific configuration  
+ home: home-manager config  
+ modules: modules  
+ pkgs: packaged softwares


## Resources  
Excellent configurations that I've learned and copied:  
+ [NickCao/flakes](https://github.com/NickCao/flakes)  
+ [ocfox/nixos-config](https://github.com/ocfox/nixos-config)  
+ [Clansty/flake](https://github.com/Clansty/flake)  
+ [fufexan/dotfiles](https://github.com/fufexan/dotfiles)  
+ [gvolpe/nix-config](https://github.com/gvolpe/nix-config)

[NixOS-CN-telegram](https://github.com/nixos-cn/NixOS-CN-telegram)



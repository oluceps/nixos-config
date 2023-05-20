![built with nix](https://img.shields.io/static/v1?logo=nixos&logoColor=white&label=&message=Built%20with%20Nix&color=41439a)![CI state](https://github.com/oluceps/nixos-config/actions/workflows/eval.yaml/badge.svg)

> v.zh_CN README translated with ChatGPT


# Nix flake

家目录管理：[home-manager](https://github.com/nix-community/home-manager)

秘密管理：[agenix](https://github.com/ryantm/agenix) [rekey](https://github.com/oddlama/agenix-rekey)

安全引导：[lanzaboote](https://github.com/nix-community/lanzaboote)

Root-On-Tmpfs 持久化：[impermanence](https://github.com/nix-community/impermanence)

---

![screenshot](./.attachs/shot_2.png)

<details>

![screenshot](./.attachs/050101344059_0050101333921_0image_2023-05-01_01-18-05.png)

</details>


## 如何使用

> 首先，请按照 Nix 官方指南初始化 NixOS。

flake 输出:
<details>
<summary>完整输出</summary>

```console
> nix flake show
git+file:///etc/nixos
├───apps
│   ├───aarch64-linux
│   │   ├───edit-secret: app
│   │   ├───rekey: app
│   │   └───rekey-save-outputs: app
│   └───x86_64-linux
│       ├───edit-secret: app
│       ├───rekey: app
│       └───rekey-save-outputs: app
├───checks
│   ├───aarch64-linux
│   │   └───pre-commit-check omitted (use '--all-systems' to show)
│   └───x86_64-linux
│       └───pre-commit-check: derivation 'pre-commit-run'
├───devShells
│   ├───aarch64-linux
│   │   ├───eunomia omitted (use '--all-systems' to show)
│   │   ├───kernel omitted (use '--all-systems' to show)
│   │   └───ubt-rv omitted (use '--all-systems' to show)
│   └───x86_64-linux
│       ├───eunomia: development environment 'nix-shell'
│       ├───kernel: development environment 'kernel-build-env-shell-env'
│       └───ubt-rv: development environment 'riscv-ubuntu-qemu-boot-script'
├───nixosConfigurations
│   ├───hastur: NixOS configuration
│   ├───kaambl: NixOS configuration
│   └───livecd: NixOS configuration
└───overlays
    └───default: Nixpkgs overlay
```  
</details>

### NixOS 部署

__在部署之前，请手动调整配置__

```console
nixos-rebuild switch --flake github:oluceps/nixos-config#HOSTNAME
  
```
| 类型 | 程序 |
|---|---|
| 编辑器 | [helix](https://github.com/oluceps/nixos-config/tree/main/home/programs/helix) |
| 窗口管理器 | [Hyprland](https://github.com/oluceps/nixos-config/tree/main/home/programs/hyprland) |
| Shell | [fish](https://github.com/oluceps/nixos-config/tree/main/home/programs/fish) |
| 状态栏 | [waybar](https://github.com/oluceps/nixos-config/tree/main/home/programs/waybar) |
| 终端 | [foot](https://github.com/oluceps/nixos-config/tree/main/home/programs/foot) |
| 备份 | [btrbk](https://github.com/oluceps/nixos-config/tree/main/modules/btrbk) |

__构建 devShell__  
```console
nix develop .#devShells.ARCH.SHELL
```

__构建 livecd__  
```console
nix build .#nixosConfigurations.livecd.config.system.build.isoImage
```

__使用 Overlay__

该 flake 包含了一些软件包的 Overlay（请

检查 ./pkgs 文件夹），要应用这些 Overlay：

在你的 flake 文件中添加，同时导入 nixpkgs 时传递 overlay：

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

## Resources  
Excellent configurations that I've learned and copied:  
+ [NickCao/flakes](https://github.com/NickCao/flakes)  
+ [ocfox/nixos-config](https://github.com/ocfox/nixos-config)  
+ [Clansty/flake](https://github.com/Clansty/flake)  
+ [fufexan/dotfiles](https://github.com/fufexan/dotfiles)  
+ [gvolpe/nix-config](https://github.com/gvolpe/nix-config)

[NixOS-CN-telegram](https://github.com/nixos-cn/NixOS-CN-telegram)


## References
[Erase your darlings](https://grahamc.com/blog/erase-your-darlings)  
[NixOS: tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/)  
[How to Learn Nix](https://ianthehenry.com/posts/how-to-learn-nix/)  
[Attrset functions](https://ryantm.github.io/nixpkgs/functions/library/attrsets/)  
[Way to search function](http://noogle.dev)  


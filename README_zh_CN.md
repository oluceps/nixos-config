> v.zh_CN README translated with ChatGPT


# 尼克斯雪花 (?

此仓库包含一些 `NixOS` 系统的配置，几乎完全通过 Nix 配置。

+ 使用 [agenix](https://github.com/ryantm/agenix) 和 [rekey](https://github.com/oddlama/agenix-rekey) ，密钥不存储在磁盘上，可以使用 YubiKey 进行解密和加密。
+ 使用 [lanzaboote](https://github.com/nix-community/lanzaboote) 实现了安全引导。
+ 根目录使用 tmpfs，通过 [impermanence](https://github.com/nix-community/impermanence) 保持状态。
+ [home-manager](https://github.com/nix-community/home-manager) 作为 flake 模块配置。


![screenshot](./.attachs/shot_1.png)


<details><summary>misc</summary>

![screenshot](./.attachs/shot_2.png)

</details>

|Type|Program|
|---|---|
|Editor|[helix](https://github.com/oluceps/nixos-config/tree/main/home/programs/helix)|
|WM|[sway](https://github.com/oluceps/nixos-config/tree/main/home/programs/sway)|
|Bar|[waybar](https://github.com/oluceps/nixos-config/tree/main/home/programs/waybar)|
|Shell|[fish](https://github.com/oluceps/nixos-config/tree/main/home/programs/fish)|
|Terminal|[foot](https://github.com/oluceps/nixos-config/tree/main/home/programs/foot)|
|backup|[btrbk](https://github.com/oluceps/nixos-config/tree/main/modules/btrbk)|  

__Overlay & nixosModules__  
此 flake 包含了一些软件包的覆盖和模块。

应用示例：
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

      inputs.oluceps.nixosModules.default
      # 或者其他独立的模块 (see `nix flake show`)
    ];
  };
};
}
```

## 参考资料
一些出色的配置，我学习并借鉴了其中的一些内容。
+ [NickCao/flakes](https://github.com/NickCao/flakes)  
+ [ocfox/nixos-config](https://github.com/ocfox/nixos-config)  
+ [Clansty/flake](https://github.com/Clansty/flake)  
+ [fufexan/dotfiles](https://github.com/fufexan/dotfiles)  
+ [gvolpe/nix-config](https://github.com/gvolpe/nix-config)

---

+ [Erase your darlings](https://grahamc.com/blog/erase-your-darlings)  
+ [NixOS: tmpfs as root](https://elis.nu/blog/2020/05/nixos-tmpfs-as-root/)  
+ [How to Learn Nix](https://ianthehenry.com/posts/how-to-learn-nix/)  
+ [Attrset functions](https://ryantm.github.io/nixpkgs/functions/library/attrsets/)  
+ [Way to search function](http://noogle.dev)  
 
[NixOS-CN-telegram](https://github.com/nixos-cn/NixOS-CN-telegram)
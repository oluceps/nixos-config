从parent的flake迁移至 dendritic pattern 遵循以下规则：

凡 parent 的 repack 文件夹中的文件，一般分为两种情况，含有 `options` 和 `config` 的，即一个标准的nixos module，或含有 `reIf` 的，由 repack/default.nix 进行了自动包装。

对于前者，如 bird.nix, autosign.nix, incus.nix，将config = {} 段的mkIf去掉，导入即开启，需要以option表达的是额外的配置项。然后用 flake.modules.nixos.* 包起来，算基本完成。你可以自行根据现有的 ./mod/repack 进行学习。

对于后者，去掉reIf然后用 flake.modules.nixos.* 一般包起来就好了

对于其中有调用vaultix的，参考garage和dae，你需要在parent的 age/ 中查找对应的secret配置项的权限，并直接写在迁移后的文件里面。

每完成一个repack模块的迁移，进行一次以 "+ migrate repack: " 作commit msg的记录

你可以访问nix mcp

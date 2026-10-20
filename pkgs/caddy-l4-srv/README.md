# Caddy L4 SRV discovery

`layer4.handlers.srv_proxy` 为 caddy-l4 增加按 DNS SRV 记录发现 TCP 上游的终端 handler。
一个 Caddy 进程可以通过多个 Unix listener 服务不同 egress，每个 listener 固定对应一个 SRV 名称。

```text
应用 → ghostunnel egress → Caddy 的 Unix socket → 远端 ghostunnel ingress → 服务
         └─────────────── 端到端 SPIFFE mTLS ────────────────┘
```

应用仍然只访问自己的 egress socket。Caddy 接收 ghostunnel 发出的 TLS 密文，查询 SRV
记录取得目标主机和端口，再通过同一个 resolver 查询目标的 AAAA/A。它不加载 SVID、不终止 TLS。
egress 的 `verifyID` 和 ingress 的 `allowedIDs` 保持在 ghostunnel 中配置。
入口选择由本地 Unix socket 决定，不依赖 SNI，也不读取应用协议。

## 构建与验证

在仓库根目录运行：

```sh
nix build .#caddy-srv
./result/bin/caddy list-modules
./result/bin/caddy validate --config pkgs/caddy-l4-srv/example.json
```

该包包含 Caddy 2.11.4、仓库锁定的 caddy-l4 和本插件，二进制名为 `caddy`。
它可供独立的服务发现进程使用。仓库 HTTP Caddy 所需的 Cloudflare、S3、security 等额外插件
没有打入这个包，因此不能直接用它覆盖现有 `caddy.package`。
`pkgs.caddy-realm` 在保留现有全部 HTTP 插件的基础上加入本插件，供共享 Caddy profile 使用。
realm 将生成的发现路由合入 `caddy.settings.apps.layer4.servers`；未使用该 profile 的节点
自动运行单独的 `realm-discovery.service`，使用此处的轻量包。egress 已改用发现 Unix socket。

开发测试：

```sh
cd pkgs/caddy-l4-srv
go test -race ./...
```

测试包含真实 DNS 查询及 UDP→TCP 回退、IPv6、Caddy Unix listener、无 SNI 的双向 TLS、SRV 优先级/权重、
端点刷新、失败回退、并发缓存、预读字节、TCP 半关闭和取消时清理连接。

## 配置

[example.json](example.json) 给出两个独立 Unix listener 的完整 JSON 配置。
先由 systemd 创建 `/run/realm-discovery`，分配目录和 socket 的用户/组权限，使相应的
ghostunnel 能连接；然后启动：

```sh
caddy run --config /path/to/example.json
```

对应的 ghostunnel client 使用 `--target unix:/run/realm-discovery/loki.sock`。
连接这个 socket 的必须是 ghostunnel 的密文出口，应用仍连接 ghostunnel 的明文入口。
Unix socket 的模式使用 Caddy 的 `|0660` 语法；各路由的权限隔离还需由运行目录、组或
systemd 挂载限制保证。

同样支持 caddy-l4 的 Caddyfile handler 语法：

```caddyfile
srv_proxy loki.service.mesh.nyaw.xyz {
    resolver 127.0.0.1:8600
    refresh 5s
    dial_timeout 5s
}
```

| 字段 | 默认值 | 含义 |
| --- | --- | --- |
| `name` | 必填 | 固定的完整 SRV 查询名，不支持动态占位符 |
| `resolver` | `127.0.0.1:8600` | SRV 和 AAAA/A 共用的 DNS 服务器，必须为 IP:端口；IPv6 使用 `[::1]:8600` |
| `refresh` | `5s` | SRV 缓存时长，连接到来时按需刷新 |
| `dial_timeout` | `5s` | 每次 DNS 查询和单个地址 TCP 建连的超时 |

## 行为与边界

- 每条路由独立缓存 SRV；同一路由的并发刷新合并为一次查询。`refresh` 是显式缓存时长，
  不读取 DNS TTL。负缓存最长 1 秒；DNS 失败后不使用过期结果。
- 先尝试较低 priority，同级按 weight 随机排序；同级正权重端点先于零权重端点，
  全零权重时均匀随机。目标地址优先 IPv6，保留 IPv4 回退。
- DNS 和 TCP 建连失败会尝试后续目标。全部建连失败会清空 SRV 缓存，供下一个连接重新发现。
  多目标的总等待时间可能超过 `dial_timeout`。
- 一旦建立 TCP 连接，流量只送往该连接。TLS 握手失败交由 ghostunnel 处理，
  插件不会重放数据或在不同 ingress 之间扇出流量。
- SRV 变化只影响后续连接，已建立连接继续转发。Caddy 配置卸载/重载会取消旧 handler
  并关闭其连接，因此建议将发现进程与经常修改的 HTTP Caddy 配置分开。
- 仅支持 TCP 和 Unix stream，不支持 UDP；不做主动健康检查，使用 Consul 的服务健康结果。
- 对端身份仍由 ghostunnel 验证。DNS 决定连接地址，不能代替 SPIFFE 身份授权。

插件源代码沿用仓库根目录的 MIT 许可证。

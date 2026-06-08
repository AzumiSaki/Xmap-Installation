## WSL 环境提醒

你当前这套默认后端已经切到 `WSL Ubuntu`，不再优先走 Docker。

当前运行方式是：

- Windows 上执行 `xmap.bat`
- `xmap.bat` 把命令转发到 WSL 发行版 `xmap-ubuntu`
- WSL 里真正执行的是 `/usr/local/sbin/xmap`

这样做的主要目的，就是避开 Docker 在原始发包和虚拟网关识别上的限制。

## 1. 这份本地部署是怎么工作的

你当前这套不是原生 Windows 版，而是：

- Windows 上用 `xmap.bat` 作为启动器
- `xmap.bat` 直接调用 WSL 发行版 `xmap-ubuntu` 里的 `xmap`
- Windows 当前目录会映射到 WSL 里的对应 `/mnt/...` 路径

这意味着：

- 你在什么目录执行 `xmap.bat`，输出文件就更适合写到那个目录里
- 先 `cd` 到你想保存结果的目录，再运行命令，会更顺手

## 2. 运行前检查

先确认这三件事：

1. `xmap-ubuntu` 这个 WSL 发行版存在
2. WSL 里的 `/usr/local/sbin/xmap` 已安装完成
3. 你当前目录是希望保存输出文件的目录

快速检查：

```bat
wsl -l -v
D:\xmap-master\xmap.bat --version
```

## 3. 最简单的使用方式

### 3.1 双击菜单

直接双击：

```text
D:\xmap-master\xmap.bat
```

你会看到菜单：

- `1` 查看完整帮助
- `2` 查看版本
- `3` 查看 Probe 模块
- `4` 查看 Output 模块
- `5` 查看 IID 模块
- `6` 查看某组模块的详细帮助
- `7` 自定义运行参数
- `8` 查看概念说明

如果你还不熟，最建议先用：

1. `8` 看概念
2. `3` 看探测模块
3. `6` 查看某个模块组合的帮助
4. `7` 输入自己的参数

### 3.2 命令行直跑

如果你更习惯命令行，直接这样用：

```bat
D:\xmap-master\xmap.bat --help
D:\xmap-master\xmap.bat --version
D:\xmap-master\xmap.bat --list-probe-modules
D:\xmap-master\xmap.bat --list-output-modules
D:\xmap-master\xmap.bat --list-iid-modules
```

## 4. 先理解三个核心概念

### 4.1 Probe module

Probe 模块决定“发什么包”。

常见类型：

- `icmp_echo`：发 ICMP Echo，适合做主机存活探测
- `tcp_syn`：发 TCP SYN，适合看端口是否开放
- `udp`：发 UDP 探测包
- `dns*`：各种 DNS 相关探测

理解方法：

- 你想看“机器在不在”，优先想 `icmp_echo`
- 你想看“某端口开没开”，优先想 `tcp_syn`
- 你想看“UDP 服务会不会回包”，优先想 `udp`

### 4.2 Output module

Output 模块决定“结果怎么写出来”。

当前可用：

- `csv`
- `json`

选择建议：

- 想直接看，先用 `csv`
- 想后处理、喂给脚本或日志系统，优先 `json`

### 4.3 IID module

IID 模块主要影响 IPv6 地址的后缀生成方式。

当前可用：

- `full`
- `low`
- `low_fill`
- `rand`
- `set`
- `zero`

常见理解：

- `low`：低位固定，比较直观
- `rand`：随机后缀，适合更分散的 IPv6 探测
- `zero`：后缀全零

如果你主要做 IPv4，IID 影响相对没那么强。

## 5. 新手推荐起手方式

第一次不要直接高速扫。建议按下面顺序来。

### 第一步：只看帮助和模块

```bat
D:\xmap-master\xmap.bat --help
D:\xmap-master\xmap.bat --list-probe-modules
D:\xmap-master\xmap.bat --list-output-modules
D:\xmap-master\xmap.bat --list-iid-modules
```

### 第二步：先做 dry-run

`--dryrun` 不真正发包，只显示计划行为，非常适合先确认参数是否写对。

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 --dryrun 192.168.56.0/24
```

### 第三步：低速、小范围开始

先扫你靶场里一个小网段，速率压低：

```bat
D:\xmap-master\xmap.bat -4 -M icmp_echo -R 100 -N 20 192.168.56.0/24
```

含义：

- `-4`：IPv4
- `-M icmp_echo`：ICMP Echo 探测
- `-R 100`：每秒 100 包
- `-N 20`：最多接收 20 条结果

### 第四步：把输出写进文件

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -O csv -o tcp80.csv 192.168.56.0/24
```

## 6. 初级使用手册

这一部分适合“已经能跑，但还没形成习惯”的阶段。

### 6.1 主机存活探测

IPv4 示例：

```bat
D:\xmap-master\xmap.bat -4 -M icmp_echo -R 500 -o alive_ipv4.csv 192.168.56.0/24
```

IPv6 示例：

```bat
D:\xmap-master\xmap.bat -6 -M icmp_echo -U low -x 64 -o alive_ipv6.csv 2001:db8:56::/64
```

说明：

- `-x 64` 表示扫描到 `/64` 这一层
- `-U low` 用低位 IID 方式补齐 IPv6 目标

### 6.2 TCP 端口探测

单端口：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -R 500 192.168.56.0/24
```

多端口：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 22,80,443,8080-8081 -R 500 192.168.56.0/24
```

看某个模块能输出哪些字段：

```bat
D:\xmap-master\xmap.bat --list-output-fields -M tcp_syn
```

当前 `tcp_syn` 常见字段包括：

- `saddr`
- `sport`
- `dport`
- `clas`
- `success`
- `repeat`
- `timestamp_str`

其中：

- `clas = synack` 往往表示端口开放
- `clas = rst` 往往表示端口关闭或被拒绝

### 6.3 UDP 探测

最基础的 UDP 探测：

```bat
D:\xmap-master\xmap.bat -4 -M udp -p 53 -R 200 192.168.56.0/24
```

如果要带 payload：

```bat
D:\xmap-master\xmap.bat -4 -M udp -p 53 --probe-args=hex:12340100000100000000000003777777076578616d706c6503636f6d0000010001 192.168.56.0/24
```

如果要按端口自动加载 payload 文件：

```bat
D:\xmap-master\xmap.bat -4 -M udp -p 53,123,161 --probe-args=dir:/mnt/d/你的目录/payloads 192.168.56.0/24
```

说明：

- `/mnt/d/你的目录/payloads` 是 WSL 里的路径
- 你可以把本地 payload 放在某个 Windows 目录里，再换算成 `/mnt/...` 路径传给 XMap
- 文件名一般按端口命名，比如 `53.pkt`、`123.hex`

### 6.4 结果保存为 JSON

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 443 -O json -o tcp443.json 192.168.56.0/24
```

适合后续：

- Python 脚本处理
- jq 过滤
- 导入日志平台

### 6.5 过滤重复或失败结果

很多人第一次用 XMap 会疑惑“为什么输出这么多”。原因之一是输出模块默认并不只保留成功且唯一的结果。

想只保留成功且非重复响应，可以加：

```bat
--output-filter="success = 1 && repeat = 0"
```

完整示例：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -O csv -f saddr,sport,dport,clas,timestamp_str --output-filter="success = 1 && repeat = 0" -o tcp80_clean.csv 192.168.56.0/24
```

### 6.6 指定输出字段

如果你不想导出所有字段，可以只保留关注的几项。

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -f saddr,sport,dport,clas,success 192.168.56.0/24
```

查看字段列表：

```bat
D:\xmap-master\xmap.bat --list-output-fields -M icmp_echo
D:\xmap-master\xmap.bat --list-output-fields -M udp
D:\xmap-master\xmap.bat --list-output-fields -M tcp_syn
```

## 7. 进阶使用手册

这一部分适合“已经能扫，开始追求效率和可复现性”的阶段。

### 7.1 速率控制

可以用每秒发包数控制：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -R 2000 192.168.56.0/24
```

也可以按带宽控制：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -B 10M 192.168.56.0/24
```

建议：

- 先用 `-R`
- 需要更贴近链路上限时再考虑 `-B`
- 靶场刚开始先低速验证，不要一上来打满

### 7.2 限制结果规模

可以限制：

- 最多探测多少目标：`-n`
- 最多发多少包：`-k`
- 最多运行多久：`-t`
- 最多收多少结果：`-N`

示例：

```bat
D:\xmap-master\xmap.bat -4 -M icmp_echo -R 1000 -n 1000 -N 100 -t 30 192.168.56.0/24
```

### 7.3 多探针与重试

```bat
D:\xmap-master\xmap.bat -4 -M udp -p 161 --probes=3 --retries=2 -R 300 192.168.56.0/24
```

适合：

- UDP 响应不稳定
- 你想提高命中率

代价：

- 发包量会上升
- 结果去重和过滤更重要

### 7.4 批量目标文件

如果目标很多，可以放进文件：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -I targets.txt
```

`targets.txt` 示例：

```text
192.168.56.10
192.168.56.11
192.168.56.12
```

如果是大量网段，也可以使用白名单：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -w whitelist.txt
```

### 7.5 黑白名单

黑名单适合排除不想碰的地址段，白名单适合只限定在允许范围里。

示例：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -w my_scope.txt -b my_exclude.txt
```

建议你在自己的靶场里也保持这个习惯，因为它能减少误扫。

### 7.6 IPv6 IID 策略

如果你做 IPv6，最常用的是：

- `low`：低位后缀，容易理解
- `rand`：随机后缀，更分散
- `zero`：固定全零，适合某些规则化地址测试

示例：

```bat
D:\xmap-master\xmap.bat -6 -M icmp_echo -x 64 -U rand 2001:db8:56::/64
```

### 7.7 使用 JSON 输出做后处理

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 22,80,443 -O json -o services.json 192.168.56.0/24
```

后续可以用自己的脚本聚合：

- 按 `saddr` 聚合主机
- 按 `dport` 统计开放端口
- 按 `clas` 区分 `synack` 与 `rst`

### 7.8 元数据和日志

你可以单独保存元数据和状态：

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 443 -m meta.json -u status.csv -l xmap.log 192.168.56.0/24
```

用途：

- `meta.json`：记录扫描元信息
- `status.csv`：看进度
- `xmap.log`：保存日志

### 7.9 线程与资源

可以用：

```bat
-T 4
```

来控制发送线程数。更高不一定更快，尤其在 WSL 和普通网卡环境里。

建议：

- 先默认
- 如果 CPU 很空、速率上不去，再逐步调高

### 7.10 使用配置文件

XMap 支持从配置文件读参数：

```bat
D:\xmap-master\xmap.bat -C /mnt/d/你的目录/my-xmap.conf
```

你可以参考项目里的示例配置：

```text
D:\xmap-master\conf\xmap.conf
```

因为 Windows 目录会映射到 WSL 的 `/mnt/...`，所以你可以把自己的配置文件放到当前目录，再用对应的 `/mnt/...` 路径引用。

## 8. 推荐的实战流程

如果你是在自己的靶场里做一次正式探测，我建议按这个顺序来：

1. 先用菜单或 `--help` 确认模块
2. 用 `--dryrun` 检查参数
3. 小网段、低速率试跑
4. 用 `--list-output-fields` 确认字段
5. 加 `-f` 和 `--output-filter` 收敛输出
6. 再扩大范围或提高速率
7. 把 `-m`、`-u`、`-l` 一起打开，方便复盘

## 9. 常见模板

### 模板 1：看主机是否在线

```bat
D:\xmap-master\xmap.bat -4 -M icmp_echo -R 500 -f saddr,clas,success,timestamp_str --output-filter="success = 1 && repeat = 0" -o alive.csv 192.168.56.0/24
```

### 模板 2：看 TCP 80/443 是否开放

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80,443 -R 1000 -f saddr,dport,clas,success --output-filter="success = 1 && repeat = 0" -o web_ports.csv 192.168.56.0/24
```

### 模板 3：做 UDP 服务试探

```bat
D:\xmap-master\xmap.bat -4 -M udp -p 53,123,161 -R 300 -f saddr,dport,clas,icmp_str,success --output-filter="repeat = 0" -o udp_scan.csv 192.168.56.0/24
```

### 模板 4：IPv6 低速摸底

```bat
D:\xmap-master\xmap.bat -6 -M icmp_echo -x 64 -U low -R 100 -N 50 -o ipv6_probe.csv 2001:db8:56::/64
```

### 模板 5：先排错不发包

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 --dryrun 192.168.56.0/24
```

## 10. 常见问题

### 10.1 双击脚本后一闪而过

现在的 `xmap.bat` 已经做了菜单和暂停；双击后应该停留在菜单界面。

### 10.2 `-M`、`-O` 这类参数之前不工作

这个问题已经在当前版本的 `xmap.bat` 里修复。现在批处理会直接调用 WSL 里的 `xmap`，不再经过 PowerShell 参数转发。

### 10.3 输出文件找不到

先确认你是在哪个目录执行命令的。当前目录会映射到 WSL 的对应 `/mnt/...` 路径，所以最稳妥的做法是：

```bat
cd /d D:\你的结果目录
D:\xmap-master\xmap.bat ...
```

### 10.4 想引用本地文件，路径该怎么写

如果是传给 WSL 里的 XMap 读取的文件，优先使用对应的 `/mnt/...` 路径。

例如当前目录下有：

```text
payloads\53.pkt
my-xmap.conf
```

那么容器里对应为：

```text
/mnt/d/你的目录/payloads/53.pkt
/mnt/d/你的目录/my-xmap.conf
```

### 10.5 为什么结果比预期多

因为默认输出不一定只保留成功且非重复结果。优先试试：

```bat
--output-filter="success = 1 && repeat = 0"
```

### 10.6 扫描速度上不去

常见原因：

- WSL 到靶场网段的路由或连通性限制
- 当前网卡或驱动限制
- 线程和速率参数还没调到合适区间
- 靶场链路本身带宽不高

先从低速确认正确性，再慢慢调高。

## 11. 建议你先记住的 8 条命令

```bat
D:\xmap-master\xmap.bat --help
D:\xmap-master\xmap.bat --list-probe-modules
D:\xmap-master\xmap.bat --list-output-modules
D:\xmap-master\xmap.bat --list-iid-modules
D:\xmap-master\xmap.bat --list-output-fields -M tcp_syn
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 --dryrun 192.168.56.0/24
D:\xmap-master\xmap.bat -4 -M icmp_echo -R 100 -N 20 192.168.56.0/24
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80 -O csv -o result.csv 192.168.56.0/24
```

## 12. 一句话总结

新手用法的核心是：

- 先 `--help`
- 再 `--dryrun`
- 再小范围低速试跑
- 再用 `-f` 和 `--output-filter` 把结果收干净

进阶用法的核心是：

- 控制速率
- 控制范围
- 控制字段
- 控制输出
- 保留日志和元数据

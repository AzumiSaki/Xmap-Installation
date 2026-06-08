# XMap + Nmap 联动工作流
提示：首先要确认电脑里是否通过默认途径安装了nmap，然后再将串联脚本拖至xmap的工作文件夹里面

最推荐的理解方式只有一句：

- `xmap` 负责快筛
- `nmap` 负责精查

也就是说，不要把它们当成二选一，而是前后配合。

## 1. 推荐工作流

最顺手的顺序是：

1. 先用 `xmap` 做主机发现
2. 再用 `xmap` 做一轮快速端口摸底
3. 把结果整理成目标列表
4. 再用 `nmap` 对重点目标做服务确认
5. 对单个重点主机再做深入枚举

## 3. 先用 xmap 找活主机

你这台机器当前更推荐先看这两个网段：

- `192.168.164.0/24`
- `192.168.74.0/24`

### 扫 `192.168.164.0/24`

```bat
D:\xmap-master\xmap.bat -4 -M icmp_echo -R 100 -f saddr,clas,success,timestamp_str --output-filter="success = 1 && repeat = 0" -o alive_164.csv 192.168.164.0/24
```

### 扫 `192.168.74.0/24`

```bat
D:\xmap-master\xmap.bat -4 -M icmp_echo -R 100 -f saddr,clas,success,timestamp_str --output-filter="success = 1 && repeat = 0" -o alive_74.csv 192.168.74.0/24
```

## 4. 把存活结果整理成 nmap 目标列表

### 从 `alive_164.csv` 提取目标

```powershell
Import-Csv .\alive_164.csv | Select-Object -ExpandProperty saddr -Unique | Set-Content .\alive_164_targets.txt
```

### 从 `alive_74.csv` 提取目标

```powershell
Import-Csv .\alive_74.csv | Select-Object -ExpandProperty saddr -Unique | Set-Content .\alive_74_targets.txt
```

这样你就能得到：

- `alive_164_targets.txt`
- `alive_74_targets.txt`

后面 `nmap` 直接吃这个列表就行。

## 5. 再用 xmap 做一轮快速端口摸底

### Web 端口

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 80,443,8080,8443 -R 100 -f saddr,dport,clas,success,timestamp_str --output-filter="success = 1 && repeat = 0" -o web_ports_164.csv 192.168.164.0/24
```

### 管理端口

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 22,23,3389,5900,5985,5986 -R 100 -f saddr,dport,clas,success,timestamp_str --output-filter="success = 1 && repeat = 0" -o admin_ports_164.csv 192.168.164.0/24
```

### 数据库端口

```bat
D:\xmap-master\xmap.bat -4 -M tcp_syn -p 1433,1521,3306,5432,6379,27017 -R 100 -f saddr,dport,clas,success,timestamp_str --output-filter="success = 1 && repeat = 0" -o db_ports_164.csv 192.168.164.0/24
```

如果你要扫 `192.168.74.0/24`，把输出文件名和网段改成 `74` 版本就行。

## 6. 用 nmap 对活主机做确认

这里我默认用：

- `-sT`
- `-sV`
- `--version-light`

这样对 Windows 下直接调用 `nmap.exe` 更稳，也不强依赖管理员权限。

### 对活主机做 Web 端口确认

```bat
D:\nmap\nmap.exe -iL .\alive_164_targets.txt -Pn -sT -sV --version-light -p 80,443,8080,8443 -oA nmap_web_164
```

### 对活主机做管理端口确认

```bat
D:\nmap\nmap.exe -iL .\alive_164_targets.txt -Pn -sT -sV --version-light -p 22,23,3389,5900,5985,5986 -oA nmap_admin_164
```

### 对活主机做数据库端口确认

```bat
D:\nmap\nmap.exe -iL .\alive_164_targets.txt -Pn -sT -sV --version-light -p 1433,1521,3306,5432,6379,27017 -oA nmap_db_164
```

如果你要扫 `192.168.74.0/24`，把输入列表和输出名换成 `74` 即可：

- `alive_74_targets.txt`
- `nmap_web_74`
- `nmap_admin_74`
- `nmap_db_74`

## 7. 对单个重点主机做深入确认

当你已经从 `xmap` 或 `nmap` 里找到重点主机后，再对单机深入。

### Web 类目标

```bat
D:\nmap\nmap.exe -Pn -sT -sV -sC -p 80,443,8080,8443 -oA nmap_host_web_192.168.164.10 192.168.164.10
```

### 管理口目标

```bat
D:\nmap\nmap.exe -Pn -sT -sV -sC -p 22,23,3389,5900,5985,5986 -oA nmap_host_admin_192.168.164.10 192.168.164.10
```

### 数据库目标

```bat
D:\nmap\nmap.exe -Pn -sT -sV -sC -p 1433,1521,3306,5432,6379,27017 -oA nmap_host_db_192.168.164.10 192.168.164.10
```

把 `192.168.164.10` 换成你真正感兴趣的主机即可。

## 8. 最推荐的实战顺序

如果你现在就要开始，最建议按这 4 步走。

### 第一步：用 xmap 找活主机

```bat
D:\xmap-master\xmap.bat -4 -M icmp_echo -R 100 -f saddr,clas,success,timestamp_str --output-filter="success = 1 && repeat = 0" -o alive_164.csv 192.168.164.0/24
```

### 第二步：导出 nmap 目标列表

```powershell
Import-Csv .\alive_164.csv | Select-Object -ExpandProperty saddr -Unique | Set-Content .\alive_164_targets.txt
```

### 第三步：用 nmap 看 Web 服务

```bat
D:\nmap\nmap.exe -iL .\alive_164_targets.txt -Pn -sT -sV --version-light -p 80,443,8080,8443 -oA nmap_web_164
```

### 第四步：挑一台重点主机做深入确认

```bat
D:\nmap\nmap.exe -Pn -sT -sV -sC -p 80,443,8080,8443 -oA nmap_host_web_192.168.164.10 192.168.164.10
```

## 9. 什么时候更偏向 xmap，什么时候更偏向 nmap

### 更适合先用 xmap

- 你要先扫整个网段
- 你要先知道哪些主机活着
- 你要先快速看常见端口有没有开
- 你要先做一轮大范围筛选

### 更适合切到 nmap

- 你已经缩小到一批重点主机
- 你想看服务版本
- 你想看默认脚本结果
- 你想更细地确认主机上到底跑了什么

## 10. 我的推荐结论

对你现在这套靶场环境，最实用的不是“只用一个”。

更推荐的是：

- `xmap` 做第一轮快筛
- `nmap` 做第二轮精查

一句话版本：

```text
xmap 先拉网，nmap 再下刀。
```

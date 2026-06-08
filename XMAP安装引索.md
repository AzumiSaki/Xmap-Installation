# XMap 安装说明

这份说明面向“刚下载下来就准备安装”的场景，默认目录是 `D:\xmap-master`，默认安装方式是我们已经准备好的：

- [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>)
- [INSTALL_XMAP.ps1](</D:/xmap-master/INSTALL_XMAP.ps1>)

当前这套本地部署不是原生 Windows 版，而是：

- Windows 上双击或运行 `INSTALL_XMAP.bat`
- 安装脚本自动准备 `WSL Ubuntu`
- 在 WSL 里编译并安装 `xmap`
- 以后通过 [xmap.bat](</D:/xmap-master/xmap.bat>) 从 Windows 侧启动

## 1. 最简单的安装方法

如果你只是想尽快装好，按这个顺序做：

1. 把源码解压或放到一个固定目录，比如 `D:\xmap-master`
2. 双击 [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>)
3. 等安装脚本自动执行完成
4. 安装完成后，双击 [xmap.bat](</D:/xmap-master/xmap.bat>) 或运行 `D:\xmap-master\xmap.bat --version`

如果一切正常，你最后会看到类似下面的完成信息：

```text
Install complete.
Next steps:
  1. Open D:\xmap-master\OPEN_QUICK_TABLE.bat
  2. Or run D:\xmap-master\xmap.bat
  3. Use menu option 7 to paste a scan command
```

## 2. 安装前需要满足什么

这套一键安装默认需要这些条件：

- Windows 10 或 Windows 11
- 能使用 `wsl`
- 能联网下载 Ubuntu 包和编译依赖
- 磁盘里有足够空间给 WSL 和编译产物

如果机器上还没有启用 WSL，安装脚本会报错并提示你先做这一步：

```powershell
wsl --install
```

这条命令通常需要：

- 以管理员身份打开终端
- 根据系统提示重启一次电脑

重启后，再重新双击 [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>) 就可以继续。

## 3. 一键安装脚本到底做了什么

安装入口分成两层：

- [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>)：给 Windows 双击用
- [INSTALL_XMAP.ps1](</D:/xmap-master/INSTALL_XMAP.ps1>)：真正的安装逻辑

### 3.1 `INSTALL_XMAP.bat` 的作用

这个文件主要做 3 件事：

1. 优先找 `pwsh`，找不到就退回到 `powershell`
2. 执行 `INSTALL_XMAP.ps1`
3. 无论成功还是失败，都把结果显示出来并 `pause`

这就是为什么你双击它以后，窗口不会像普通 `.bat` 一样直接闪退。

### 3.2 `INSTALL_XMAP.ps1` 的作用

这个脚本是完整安装器，主要流程如下：

1. 确认当前源码目录，也就是脚本所在目录
2. 检查 `wsl.exe` 是否存在
3. 检查 WSL 当前是否可用
4. 检查名为 `xmap-ubuntu` 的 WSL 发行版是否已经存在
5. 如果不存在，就创建一个新的 `xmap-ubuntu`
6. 进入 WSL，安装编译依赖
7. 把 Windows 路径转换成 WSL 路径
8. 在源码目录里执行 `cmake .`、`make -j$(nproc)`、`make install`
9. 用 `/usr/local/sbin/xmap --version` 做最终验证

安装成功后，以后真正运行的是：

```text
WSL 里的 /usr/local/sbin/xmap
```

而 Windows 上的 [xmap.bat](</D:/xmap-master/xmap.bat>) 只是启动器。

## 4. WSL 发行版是怎么创建的

默认发行版名字是：

```text
xmap-ubuntu
```

安装器会优先尝试一种更平滑的方式：

1. 如果本机有 `docker`
2. 就用 `public.ecr.aws/ubuntu/ubuntu:24.04` 这个 Ubuntu 镜像
3. 导出 rootfs
4. 用 `wsl --import` 导入成 `xmap-ubuntu`

如果本机没有 Docker，安装器就退回到：

```powershell
wsl --install Ubuntu-24.04 --name xmap-ubuntu --no-launch --web-download
```

所以你可以这样理解：

- 有 Docker：更像“快速导入现成 Ubuntu 根文件系统”
- 没 Docker：走 WSL 官方安装路径

这两个分支最后的目标是一样的，都是为了得到一个可用的 `xmap-ubuntu`。

## 5. 安装器会装哪些依赖

安装器会在 WSL 里执行：

```text
apt-get update
apt-get install -y build-essential cmake libgmp3-dev gengetopt libpcap-dev flex byacc libjson-c-dev pkg-config libunistring-dev iproute2 iputils-ping net-tools
```

这些依赖的作用大致是：

- `build-essential`：编译基础工具链
- `cmake`：生成和管理构建过程
- `libpcap-dev`：抓包和底层网络相关开发库
- `gengetopt`：命令行参数处理代码生成
- `flex`、`byacc`：词法/语法相关构建工具
- `libjson-c-dev`：JSON 输出相关
- `libgmp3-dev`、`libunistring-dev`：项目依赖库
- `iproute2`、`iputils-ping`、`net-tools`：便于基础网络排查

## 6. 安装后文件和运行关系

装好以后，几个关键文件的关系是这样的：

- [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>)：双击安装入口
- [INSTALL_XMAP.ps1](</D:/xmap-master/INSTALL_XMAP.ps1>)：实际安装逻辑
- [xmap.bat](</D:/xmap-master/xmap.bat>)：日常运行入口
- [XMAP_使用说明.md](</D:/xmap-master/XMAP_使用说明.md>)：总说明书
- [XMAP_QUICK_TABLE.md](</D:/xmap-master/XMAP_QUICK_TABLE.md>)：中文速查表
- [XMAP_READY_COMMANDS.md](</D:/xmap-master/XMAP_READY_COMMANDS.md>)：可直接粘贴的现成命令

实际安装位置是：

- Windows 源码目录：`D:\xmap-master`
- WSL 发行版：`xmap-ubuntu`
- WSL 可执行文件：`/usr/local/sbin/xmap`

## 7. 怎么确认是否安装成功

推荐用下面这些方法确认：

### 方法 1：看安装器最后输出

如果看到：

```text
Install complete.
```

通常就说明主流程成功了。

### 方法 2：检查 WSL 发行版

```powershell
wsl -l -v
```

你应该能看到：

```text
xmap-ubuntu
```

### 方法 3：检查 xmap 版本

```bat
D:\xmap-master\xmap.bat --version
```

正常的话会返回类似：

```text
xmap Development Build. Commit UNKNOWN
```

### 方法 4：看帮助

```bat
D:\xmap-master\xmap.bat --help
```

如果帮助能正常输出，说明启动器和 WSL 后端已经接上了。

## 8. 一键安装脚本的可选参数

除了双击 `.bat`，你也可以直接运行 PowerShell 脚本。

默认命令：

```powershell
& 'D:\xmap-master\INSTALL_XMAP.ps1'
```

### 8.1 指定发行版名字

```powershell
& 'D:\xmap-master\INSTALL_XMAP.ps1' -DistroName 'xmap-ubuntu'
```

一般不需要改，除非你想同时保留多套环境。

### 8.2 指定 WSL 安装目录

```powershell
& 'D:\xmap-master\INSTALL_XMAP.ps1' -InstallRoot 'D:\WSL\xmap-ubuntu'
```

默认情况下，它会放到：

```text
%LOCALAPPDATA%\XMap\wsl\xmap-ubuntu
```

### 8.3 强制重建发行版

```powershell
& 'D:\xmap-master\INSTALL_XMAP.ps1' -ForceRecreate
```

这个参数会：

- 注销已有的 `xmap-ubuntu`
- 重新创建发行版
- 重新安装依赖
- 重新编译安装

只有在环境明显坏掉、你明确要重装时才建议使用。

## 9. 不用 `.bat` 时怎么安装

如果你不想用 [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>)，也可以手动安装。

### 9.1 在 Ubuntu 上手动安装

如果你本来就在 Ubuntu 里，最直接。

先安装依赖：

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libgmp3-dev gengetopt libpcap-dev flex byacc libjson-c-dev pkg-config libunistring-dev iproute2 iputils-ping net-tools
```

然后进入源码目录编译安装：

```bash
cd /path/to/xmap-master
cmake .
make -j"$(nproc)"
sudo make install
```

安装完成后验证：

```bash
/usr/local/sbin/xmap --version
/usr/local/sbin/xmap --help
```

如果你想直接用命令名启动，也可以：

```bash
xmap --version
```

只要 `/usr/local/sbin` 已经在当前环境的 `PATH` 里就行；如果不在，就显式写全路径。

### 9.2 在 Windows 上手动安装

`xmap` 不建议走原生 Windows 编译。对你现在这套环境，Windows 上的正确思路是：

1. 先装 WSL
2. 在 WSL Ubuntu 里装依赖
3. 在 WSL 里编译安装 `xmap`
4. 以后用 `wsl -d xmap-ubuntu -- xmap ...` 或 `wsl -d xmap-ubuntu -- /usr/local/sbin/xmap ...`

先在管理员 PowerShell 里启用 WSL：

```powershell
wsl --install
```

如果系统要求重启，就先重启。

然后安装一个 Ubuntu 发行版，推荐：

```powershell
wsl --install Ubuntu-24.04
```

装好后，第一次打开 Ubuntu，让它完成初始化。

接着把源码放在 Windows 目录里，比如：

```text
D:\xmap-master
```

进入 WSL：

```powershell
wsl -d Ubuntu-24.04
```

在 WSL 里安装依赖：

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libgmp3-dev gengetopt libpcap-dev flex byacc libjson-c-dev pkg-config libunistring-dev iproute2 iputils-ping net-tools
```

再进入 Windows 挂载目录对应的位置：

```bash
cd /mnt/d/xmap-master
```

编译安装：

```bash
cmake .
make -j"$(nproc)"
sudo make install
```

验证：

```bash
/usr/local/sbin/xmap --version
```

如果你以后不想用 [xmap.bat](</D:/xmap-master/xmap.bat>)，那就直接这样运行：

```powershell
wsl -d Ubuntu-24.04 -- /usr/local/sbin/xmap --help
wsl -d Ubuntu-24.04 -- /usr/local/sbin/xmap --version
```

如果你已经自己创建了别的发行版，比如我们之前用的：

```text
xmap-ubuntu
```

那就把命令里的 `Ubuntu-24.04` 改成 `xmap-ubuntu`。

### 9.3 Windows 下“不用 bat 但也想方便一点”的方式

如果你不想用 `.bat`，但也不想每次都敲很长一串 `wsl -d ...`，你可以自己在 PowerShell 里定义一个临时别名：

```powershell
function xmap { wsl -d xmap-ubuntu -- /usr/local/sbin/xmap $args }
```

定义完以后，本次 PowerShell 会话里就可以直接：

```powershell
xmap --version
xmap --help
xmap -4 -M icmp_echo -R 100 192.168.164.0/24
```

如果你想长期保留，再把这段写进你的 PowerShell profile。

## 10. 常见报错怎么理解

### 9.1 `wsl.exe not found`

意思是系统找不到 WSL。

处理方式：

1. 以管理员身份打开 PowerShell 或 Windows Terminal
2. 执行 `wsl --install`
3. 按要求重启
4. 重试 [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>)

### 9.2 `WSL is not ready on this machine`

意思是：

- `wsl` 命令存在
- 但 WSL 组件还没真正准备好

通常也是先完成：

```powershell
wsl --install
```

然后重启系统。

### 9.3 `The distro was installed, but root shell is not ready yet`

意思是 Ubuntu 已经被安装了，但首次初始化还没跑完。

处理方式：

```powershell
wsl -d xmap-ubuntu
```

让它先完成首次启动，再关掉窗口，重新执行安装器。

### 9.4 `apt-get update` 或 `apt-get install` 失败

通常是网络问题、镜像源问题，或者你的机器当前没有外网。

这时先确认：

- WSL 能否联网
- Windows 本机能否联网
- 公司/校园网络是否限制了更新源

### 9.5 `cmake` 或 `make` 失败

这种情况多半和源码目录、构建缓存或依赖状态有关。

建议处理顺序：

1. 先重新运行一次 [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>)
2. 如果还是失败，再考虑使用 `-ForceRecreate`
3. 再不行，再看具体编译报错定位

### 9.6 安装器成功了，但 `xmap.bat` 运行失败

先检查：

```powershell
wsl -l -v
D:\xmap-master\xmap.bat --version
```

如果 `wsl` 正常，但 `xmap.bat` 不正常，通常是启动器和 WSL 路径映射的问题，需要再单独排查。

## 11. 安装完成后下一步做什么

安装成功后，推荐按这个顺序上手：

1. 打开 [OPEN_QUICK_TABLE.bat](</D:/xmap-master/OPEN_QUICK_TABLE.bat>)
2. 看 [XMAP_QUICK_TABLE.md](</D:/xmap-master/XMAP_QUICK_TABLE.md>)
3. 双击 [xmap.bat](</D:/xmap-master/xmap.bat>)
4. 在菜单里先看 `Help`、`Probe List`
5. 需要实际运行时，用菜单 `7` 粘贴参数

如果你更习惯看模板：

1. 打开 [OPEN_TEMPLATES.bat](</D:/xmap-master/OPEN_TEMPLATES.bat>)
2. 选择 [XMAP_PARAM_TEMPLATES](</D:/xmap-master/XMAP_PARAM_TEMPLATES>)
3. 按场景挑模板
4. 只改 `<TARGET>`、`<RATE>`、`<PORTS>`、`<OUTFILE>`

## 12. 给“刚下载下来”的最短建议

如果你只想记最短版本，就记这几句：

1. 双击 [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>)
2. 如果提示没开 WSL，就先管理员终端跑 `wsl --install` 并重启
3. 装好后双击 [xmap.bat](</D:/xmap-master/xmap.bat>)
4. 不知道怎么扫，就先看 [OPEN_QUICK_TABLE.bat](</D:/xmap-master/OPEN_QUICK_TABLE.bat>)

## 13. 相关文件入口

- 安装说明：本文件 [XMAP_INSTALL_GUIDE.md](</D:/xmap-master/XMAP_INSTALL_GUIDE.md>)
- 安装脚本： [INSTALL_XMAP.bat](</D:/xmap-master/INSTALL_XMAP.bat>) 和 [INSTALL_XMAP.ps1](</D:/xmap-master/INSTALL_XMAP.ps1>)
- 主说明书： [XMAP_使用说明.md](</D:/xmap-master/XMAP_使用说明.md>)
- 中文速查表： [XMAP_QUICK_TABLE.md](</D:/xmap-master/XMAP_QUICK_TABLE.md>)
- 参数模板目录： [XMAP_PARAM_TEMPLATES](</D:/xmap-master/XMAP_PARAM_TEMPLATES>)

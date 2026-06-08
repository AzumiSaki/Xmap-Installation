# XMap Ubuntu安装

## 1. 打开终端

后面的命令都在终端里执行。

## 2. 进入源码目录

如果你的源码目录在：

```text
/home/yourname/xmap-master
```

那就执行：

```bash
cd /home/yourname/xmap-master
```

如果你不知道当前目录对不对，可以先执行：

```bash
pwd
ls
```

只要你能看到 `README.md`、`CMakeLists.txt`、`src`、`lib` 这些文件或目录，就说明进对地方了。

## 3. 安装依赖

直接复制下面这段：

```bash
sudo apt-get update
sudo apt-get install -y build-essential cmake libgmp3-dev gengetopt libpcap-dev flex byacc libjson-c-dev pkg-config libunistring-dev iproute2 iputils-ping net-tools
```

如果系统提示输入密码，就输入当前 Ubuntu 用户密码。

## 4. 编译

还在源码目录里的前提下，执行：

```bash
cmake .
make -j"$(nproc)"
```

如果你想保守一点，也可以直接：

```bash
make
```

## 5. 安装

执行：

```bash
sudo make install
```

默认安装位置是：

```text
/usr/local/sbin/xmap
```

## 6. 验证

先看版本：

```bash
/usr/local/sbin/xmap --version
```

再看帮助：

```bash
/usr/local/sbin/xmap --help
```

如果这两条都正常输出，就说明装好了。

## 7. 第一次运行建议

先别急着大范围跑，先做最小检查：

```bash
/usr/local/sbin/xmap --list-probe-modules
/usr/local/sbin/xmap --list-output-modules
/usr/local/sbin/xmap --list-iid-modules
```

再做一个最小测试：

```bash
/usr/local/sbin/xmap -4 -M icmp_echo -R 20 -N 3 127.0.0.1
```

## 8. 如果想直接敲 `xmap`

先试：

```bash
xmap --version
```

如果提示找不到命令，就先继续用全路径：

```bash
/usr/local/sbin/xmap --version
```

如果你想把 `/usr/local/sbin` 加到 `PATH`，执行：

```bash
echo 'export PATH="/usr/local/sbin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

然后再试：

```bash
xmap --version
```

## 9. 常见问题

### 9.1 `apt-get` 失败

通常是网络或软件源问题。先检查：

```bash
ping -c 2 archive.ubuntu.com
```

### 9.2 `cmake` 失败

先确认你是不是在源码目录里：

```bash
pwd
ls
```

### 9.3 `make install` 权限不够

记得带 `sudo`：

```bash
sudo make install
```

### 9.4 装完后 `xmap` 命令找不到

这通常只是 `PATH` 没配好，先用：

```bash
/usr/local/sbin/xmap --version
```

## 10. 最短版

如果你只想记最短流程，就照着这几条：

```bash
cd /path/to/xmap-master
sudo apt-get update
sudo apt-get install -y build-essential cmake libgmp3-dev gengetopt libpcap-dev flex byacc libjson-c-dev pkg-config libunistring-dev iproute2 iputils-ping net-tools
cmake .
make -j"$(nproc)" && sudo make install
/usr/local/sbin/xmap --version
```

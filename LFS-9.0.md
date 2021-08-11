
# 第 2 章 准备宿主系统

## 2.2. 宿主系统要求

```
cat > version-check.sh << "EOF"
#!/bin/bash
# Simple script to list version numbers of critical development tools
export LC_ALL=C
bash --version | head -n1 | cut -d" " -f2-4
MYSH=$(readlink -f /bin/sh)
echo "/bin/sh -> $MYSH"
echo $MYSH | grep -q bash || echo "ERROR: /bin/sh does not point to bash"
unset MYSH

echo -n "Binutils: "; ld --version | head -n1 | cut -d" " -f3-
bison --version | head -n1

if [ -h /usr/bin/yacc ]; then
  echo "/usr/bin/yacc -> `readlink -f /usr/bin/yacc`";
elif [ -x /usr/bin/yacc ]; then
  echo yacc is `/usr/bin/yacc --version | head -n1`
else
  echo "yacc not found" 
fi

bzip2 --version 2>&1 < /dev/null | head -n1 | cut -d" " -f1,6-
echo -n "Coreutils: "; chown --version | head -n1 | cut -d")" -f2
diff --version | head -n1
find --version | head -n1
gawk --version | head -n1

if [ -h /usr/bin/awk ]; then
  echo "/usr/bin/awk -> `readlink -f /usr/bin/awk`";
elif [ -x /usr/bin/awk ]; then
  echo awk is `/usr/bin/awk --version | head -n1`
else 
  echo "awk not found" 
fi

gcc --version | head -n1
g++ --version | head -n1
ldd --version | head -n1 | cut -d" " -f2-  # glibc version
grep --version | head -n1
gzip --version | head -n1
cat /proc/version
m4 --version | head -n1
make --version | head -n1
patch --version | head -n1
echo Perl `perl -V:version`
python3 --version
sed --version | head -n1
tar --version | head -n1
makeinfo --version | head -n1  # texinfo version
xz --version | head -n1

echo 'int main(){}' > dummy.c && g++ -o dummy dummy.c
if [ -x dummy ]
  then echo "g++ compilation OK";
  else echo "g++ compilation failed"; fi
rm -f dummy.c dummy
EOF

bash version-check.sh
```

```
yum list bash binutils bison bzip2 coreutils diffutils findutils gawk gcc glic grep gzip m4 make patch perl python3 sed tar texinfo xz 
```

## 2.4. 创建新分区

```
cfdisk
---
根分区（/）      /dev/sda8     25GB
/boot分区     /dev/sda4       300MB
SWAP交换分区    /dev/sda5       4GB
---
```

## 2.5. 在分区上创建文件系统

```
mkfs -v -t ext4 /dev/sda8
mkfs -v -t ext4 /dev/sda4
mkswap /dev/sda5    #如果你已经有了现成的 swap 分区,不需要重新格式化。如果是新建的 swap 分区，需要用命令初始化
```

## 2.6. 设置 $LFS 变量

```
echo 'source lfsrc' >> .bash_profile
echo 'export LFS=/mnt/lfs' > lfsrc
```

## 2.7. 挂载新分区

```
mkidr -pv $LFS
mount -v -t ext4 /dev/sda8 $LFS
mkdir -v $LFS/boot
mount -v -t ext4 /dev/sda4 $LFS/boot

vim /etc/fstab
    ---
    /dev/sda8 /mnt/lfs ext4 defaults 1 1
    /dev/sda4 /mnt/lfs/boot ext4 defaults 0 0
    ---
```

# 第 3 章 软件包和补丁

## 3.1. 简介

> 我们无法保证下载的地址是一直有效的。如果在本书发布后下载地址变了，大部分软件包可以用 Google （<http://www.google.com/>） 解决。如果连搜索也失败了，那不妨试一试 <http://www.linuxfromscratch.org/lfs/packages.html#packages> 中提到的其他下载地址。

```
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources  #设置目录的写权限和粘滞模式。「粘滞模式」是指，即便多个用户对某个目录有写权限，但仅有文件的所有者，能在粘滞目录中删除该文件。
```

> 一个简单的一口气下载所有软件包和补丁的方法是使用 wget-list 作为 wget 的输入。
> LCTT译注：由于这些文件都分布在国外的不同站点上，因此有些下载的会很慢。非常感谢中国科学技术大学镜像站提供的LFS软件包：<http://mirrors.ustc.edu.cn/lfs/lfs-packages/9.0/>。可以使用我们制作的 wget-list-ustc <https://github.com/LCTT/LFS-BOOK/blob/9.0-translating/wget-list-ustc> 方便下载。

```
wget https://raw.githubusercontent.com/LCTT/LFS-BOOK/9.0-translating/wget-list-ustc
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources
```

> 从 LFS-7.0 开始，多了一个单独的文件 md5sums，可以在正式开始前校验所有的文件是否都正确。

```
wget http://mirrors.ustc.edu.cn/lfs/lfs-packages/9.0/md5sums
pushd $LFS/sources
md5sum -c md5sums
popd
```

# 第 4 章 最后的准备工作

## 4.2. 创建目录 $LFS/tools

```
mkdir -v $LFS/tools
ln -sv $LFS/tools /
```

## 4.3. 添加 LFS 用户

> 当以 root 用户登录时，犯一个小错误可能会破坏或摧毁整个系统。因此，建议在本章中以非特权用户编译软件包。

```
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources
su - lfs
```

## 4.4. 设置环境

> 通过为 bash shell 创建两个开机启动的文件，设置合适的工作环境。

```
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
```

> 当以 lfs 用户身份登录时，初始 shell 通常是一个 login 的 shell，它先读取宿主机的 /etc/profile 文件（很可能包括一些设定和环境变量），然后是 .bash_profile 文件。.bash_profile 中的命令 exec env -i.../bin/bash 用一个除了 HOME，TERM 和 PS1 变量外，其他环境完全为空的新 shell 代替运行中的 shell。这能确保不会有潜在的和意想不到的危险环境变量，从宿主机泄露到构建环境中。这样做主要是为了确保环境的干净。
> 新的 shell 实例是一个 non-login 的 shell，不会读取 /etc/profile 或者 .bash_profile 文件，而是读取 .bashrc。现在，创建 .bashrc 文件：

```
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF
```

> 最后，启用刚才创建的用户配置，为构建临时工具完全准备好环境：

```
source ~/.bash_profile
```

# 第 5 章 构建临时系统

## 简介

> 本章构造一个最小的 Linux 系统。
> 构建这个最小系统有两个步骤。第一步，是构建一个与宿主系统无关的新工具链（编译器、汇编器、链接器、库和一些有用的工具）。第二步则是使用该工具链，去构建其它的基础工具。
> 本章中编译得到的文件将被安装在目录 $LFS/tools 中，以确保在下一章中安装的文件和宿主系统生成的目录相互分离。

## 5.2. 工具链技术说明

> 纵览 第 5 章 的目标是生成一个临时的系统，这个系统中包含一个已知的较好工具集，并且工具集可以独立于宿主系统。通过使用 chroot，其余各章中的命令将被包含在此环境中，以保证目标 LFS 系统能够洁净且无故障地生成。

## 5.3. 通用编译指南

>> 重要
>
> 再次强调构建的过程：

1. 把所有源文件和补丁放到 chroot 环境可访问的目录，例如 /mnt/lfs/sources/。但是千万不能把源文件放在 /mnt/lfs/tools/ 中。
2. 进入到源文件目录。
3. 对于每个软件包：
    a. 用 tar 程序解压要编译的软件包。在第五章中，确保解压软件包时你使用的是 lfs 用户。
    b. 进入到解压后创建的目录中。
    c. 根据指南说明编译软件包。
    d. 回到源文件目录。
    e. 除非特别说明，删除解压出来的目录。

## 5.4. Binutils-2.32 - 第 1 遍

### 5.4.1. 安装交叉编译的 Binutils

```
cd $LFS/sources
tar xvf binutils-2.32.tar.xz
cd binutils-2.32
```

> 如果是在 x86_64 上构建，创建符号链接，以确保工具链的完整性：
```
case $(uname -m) in
  x86_64) mkdir -v /tools/lib && ln -sv lib /tools/lib64 ;;
esac
```

> Binutils 手册建议，在源码目录之外一个专门的编译目录里面编译 Binutils：
```
mkdir -v build
cd       build

time {
../configure --prefix=/tools            \
             --with-sysroot=$LFS        \
             --with-lib-path=/tools/lib \
             --target=$LFS_TGT          \
             --disable-nls              \
             --disable-werror           \
&& make && make install; 
} 
```

```
cd $LFS/sources
rm -rf binutils-2.32
```

## 5.5. GCC-9.2.0 - 第 1 遍

### 5.5.1. 安装交叉编译的 GCC

```
cd $LFS/sources
tar xvf gcc-9.2.0.tar.xz
cd gcc-9.2.0
```

> 现在 GCC 需要 GMP、MPFR 和 MPC 软件包。在你的主机发行版中可能并不包括这些软件包，它们将和 GCC 一起编译。将每个解压软件包到 GCC 的目录下，并重命名解压后得到的目录，以便 GCC 编译过程中能自动使用这些软件：
> 首先从源目录中解压 gcc 的源码包，然后进入创建的目录中。接着才可以执行下面的指令。

```
tar -xf ../mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc
```

> 下面的指令将会修改 GCC 默认的动态链接器的位置，安装到 /tools 目录中的。并将 /usr/include 从 GCC 的 include 检索路径中移除。
```
for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done
```

> 最后，在 x86_64 的主机上，为 64 位的库设置默认目录名至「lib」：
```
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
 ;;
esac
```

> GCC 手册建议在源目录之外一个专门的编译目录中编译 GCC：
```
mkdir -v build
cd       build

../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++
```

```
make && make install
```

```
cd $LFS/sources
rm -rf gcc-9.2.0
```

## 5.6. Linux-5.2.8 API 头文件

### 5.6.1. 安装 Linux API 头文件

```
cd $LFS/sources
tar xvf linux-5.2.8.tar.xz
cd linux-5.2.8
```

> 确认这里没有陈旧的文件且不依赖于之前的操作：
```
make mrproper
```

> 从源代码中提取用户可见的内核头文件。把他们保存在一个临时本地文件夹中然后复制到所需的位置
```
make INSTALL_HDR_PATH=dest headers_install
cp -rv dest/include/* /tools/include
```

```
cd $LFS/sources
rm -rf linux-5.2.8
```

## 5.7. Glibc-2.30

### 5.7.1. 安装 Glibc

```
cd $LFS/sources
tar xvf glibc-2.30.tar.xz 
cd glibc-2.30
```

> Glibc 手册建议在源文件夹之外的一个专用文件夹中编译 Glibc：
```
mkdir -v build
cd       build
```

```
../configure                             \
      --prefix=/tools                    \
      --host=$LFS_TGT                    \
      --build=$(../scripts/config.guess) \
      --enable-kernel=3.2                \
      --with-headers=/tools/include
```

```
make && make install
```

>> 小心
> 到了这里，必须停下来确认新工具链的基本功能(编译和链接)都是像预期的那样正常工作。运行下面的命令进行全面的检查：

```
echo 'int main(){}' > dummy.c
$LFS_TGT-gcc dummy.c
readelf -l a.out | grep ': /tools'
```

> 如果一切工作正常的话，这里应该没有错误，最后一个命令的输出形式会是：
>
> `[Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]`

> 注意 32 位机器上对应的解释器名字是 /tools/lib/ld-linux.so.2。
> 如果输出不是像上面那样或者根本就没有输出，那么可能某些地方出错了。调查并回溯这些步骤，找出问题所在并改正它。在继续之前必须解决这个问题。

> 一旦一切都顺利，清理测试文件：
```
rm -v dummy.c a.out
```

```
cd $LFS/sources
rm -rf glibc-2.30
```

## 5.8. GCC-9.2.0 中的 Libstdc++

### 5.8.1. 安装目标 Libstdc++

>> 注意
> Libstdc++ 是 GCC 源文件的一部分。你首先应该解压 GCC 的压缩包，然后进入 gcc-9.2.0 文件夹。

```
cd $LFS/sources
tar xvf gcc-9.2.0.tar.xz
cd gcc-9.2.0
```

> 为 Libstdc++ 另外创建一个用于构建的文件夹并进入该文件夹：：

```
mkdir -v build
cd       build
```

```
../libstdc++-v3/configure           \
    --host=$LFS_TGT                 \
    --prefix=/tools                 \
    --disable-multilib              \
    --disable-nls                   \
    --disable-libstdcxx-threads     \
    --disable-libstdcxx-pch         \
    --with-gxx-include-dir=/tools/$LFS_TGT/include/c++/9.2.0
```

```
make && make install
```

```
cd $LFS/sources
rm -rf gcc-9.2.0
```

## 5.9. Binutils-2.32 - 第 2 遍

### 5.9.1. 安装 Binutils

```
cd $LFS/sources
tar xvf binutils-2.32.tar.xz
cd binutils-2.32
```

> 再次新建一个单独的编译文件夹：

```
mkdir -v build
cd       build
```

```
CC=$LFS_TGT-gcc                \
AR=$LFS_TGT-ar                 \
RANLIB=$LFS_TGT-ranlib         \
../configure                   \
    --prefix=/tools            \
    --disable-nls              \
    --disable-werror           \
    --with-lib-path=/tools/lib \
    --with-sysroot
```

```
make && make install
```

> 为下一章的「Re-adjusting」阶段准备链接器：

```
make -C ld clean
make -C ld LIB_PATH=/usr/lib:/lib
cp -v ld/ld-new /tools/bin
```

```
cd $LFS/sources
rm -rf binutils-2.32
```

## 5.10. GCC-9.2.0 - 第 2 遍

### 5.10.1. 安装 GCC

```
cd $LFS/sources
tar xvf gcc-9.2.0.tar.xz
cd gcc-9.2.0
```

> 我们第一次编译 GCC 的时候安装了一些内部系统头文件。其中的一个 limits.h 会反过来包括对应的系统头文件 limits.h，在我们的例子中，是 /tools/include/limits.h 。但是，第一次编译 gcc 的时候 /tools/include/limits.h 并不存在，因此 GCC 安装的内部头文件只是部分的自包含文件，并不包括系统头文件的扩展功能。这足以编译临时 libc，但是这次编译 GCC 要求完整的内部头文件。使用和正常情况下 GCC 编译系统使用的相同的命令创建一个完整版本的内部头文件：

```
cat gcc/limitx.h gcc/glimits.h gcc/limity.h > \
  `dirname $($LFS_TGT-gcc -print-libgcc-file-name)`/include-fixed/limits.h
```

> 再一次更改 GCC 的默认动态链接器的位置，使用安装在 /tools 的那个。

```
for file in gcc/config/{linux,i386/linux{,64}}.h
do
  cp -uv $file{,.orig}
  sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' \
      -e 's@/usr@/tools@g' $file.orig > $file
  echo '
#undef STANDARD_STARTFILE_PREFIX_1
#undef STANDARD_STARTFILE_PREFIX_2
#define STANDARD_STARTFILE_PREFIX_1 "/tools/lib/"
#define STANDARD_STARTFILE_PREFIX_2 ""' >> $file
  touch $file.orig
done
```

> 如果是在 x86_64 环境上构建，为 64 位库改变默认目录名至「lib」：

```
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
```

> 和第一次编译 GCC 一样，它要求 GMP、MPFR 和 MPC 软件包。解压 tar 包并把它们重名为到所需的文件夹名称：

```
tar -xf ../mpfr-4.0.2.tar.xz
mv -v mpfr-4.0.2 mpfr
tar -xf ../gmp-6.1.2.tar.xz
mv -v gmp-6.1.2 gmp
tar -xf ../mpc-1.1.0.tar.gz
mv -v mpc-1.1.0 mpc
```

> 再次创建独立的编译文件夹：

```
mkdir -v build
cd       build
```

```
CC=$LFS_TGT-gcc                                    \
CXX=$LFS_TGT-g++                                   \
AR=$LFS_TGT-ar                                     \
RANLIB=$LFS_TGT-ranlib                             \
../configure                                       \
    --prefix=/tools                                \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --enable-languages=c,c++                       \
    --disable-libstdcxx-pch                        \
    --disable-multilib                             \
    --disable-bootstrap                            \
    --disable-libgomp
```

```
make && make install
```

> 作为画龙点睛，这里创建一个符号链接。很多程序和脚本执行 cc 而不是 gcc 来保证程序的通用性，并且在所有的 Unix 类型的系统上都能用，而非仅局限于安装了 GCC 的 Unix 类型的系统。运行 cc 使得系统管理员不用考虑要安装那种 C 编译器：

```
ln -sv gcc /tools/bin/cc
```

>> 小心
> 到了这里，必须停下来确认新工具链的基本功能（编译和链接）都是像预期的那样正常工作。运行下面的命令进行全面的检查：
```
echo 'int main(){}' > dummy.c
cc dummy.c
readelf -l a.out | grep ': /tools'
```

> 如果一切工作正常的话，这里应该没有错误，最后一个命令的输出形式会是：
>
> `[Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]`

> 注意 32 位机器的动态链接是 /tools/lib/ld-linux.so.2。
> 如果输出不是像上面那样或者根本就没有输出，那么可能某些地方出错了。调查并回溯这些步骤，找出问题所在并改正它。在继续之前必须解决这个问题。首先，使用 gcc 而不是 cc 再次进行全面的检查。如果能运行，就符号链接 /tools/bin/cc 就不见了。像上面介绍的那样新建符号链接。下一步，确认 PATH 是正确的。这能通过运行 echo $PATH 检验，验证 /tools/bin 在列表的前面。如果 PATH 是错误的，这意味着你可能不是以 lfs 用户的身份登录或者在前面 第 4.4 节 「设置环境」 中某些地方出现了错误。

> 一旦一切都顺利，清理测试文件：
```
rm -v dummy.c a.out
```

```
cd $LFS/sources
rm -rf gcc-9.2.0
```

## 5.11. Tcl-8.6.9

### 5.11.1. 安装 Tcl

> 此软件包和后面两个包（Expect 和 DejaGNU）用来为 GCC 和 Binutils 还有其他的一些软件包的测试套件提供运行支持。是仅仅为了测试目的而安装的三个软件包。

```
cd $LFS/sources
tar xvf tcl8.6.9-src.tar.gz
cd tcl8.6.9
```

```
cd unix
./configure --prefix=/tools
```

```
make && make install
chmod -v u+w /tools/lib/libtcl8.6.so
make install-private-headers
ln -sv tclsh8.6 /tools/bin/tclsh
```

> Tcl 测试套件在宿主机某些特定条件下会失败，原因很难推测。不过测试套件失败并不奇怪，也不是什么严重的错误。

```
cd $LFS/sources
rm -rf tcl8.6.9
```

### 5.11.2. Tcl 软件包内容

    安装的程序:           tclsh (link to tclsh8.6) and tclsh8.6
    安装的库:             libtcl8.6.so, libtclstub8.6.a
    简要介绍
        tclsh8.6            Tcl 命令终端
        tclsh               符号链接到 tclsh8.6
        libtcl8.6.so        Tcl 库
        libtclstub8.6.a     Tcl Stub 库

## 5.12. Expect-5.45.4

### 5.12.1. 安装 Expect

```
cd $LFS/sources
tar xvf expect5.45.4.tar.gz
cd expect5.45.4
```

```
cp -v configure{,.orig}
sed 's:/usr/local/bin:/bin:' configure.orig > configure
```

```
./configure --prefix=/tools       \
            --with-tcl=/tools/lib \
            --with-tclinclude=/tools/include
```

```
make && make SCRIPTS="" install
```

> 请注意 Expect 测试套件已知在某些宿主机特定情况下有过失败的情况，我们还没有完全把握。不过，在这里测试套件运行失败并不奇怪，也不认为是关键问题。

```
cd $LFS/sources
rm -rf expect5.45.4
```

### 5.12.2. Expect 软件包内容

    安装的程序:           expect
    安装的库:             libexpect-5.45.so
    简要介绍
        expect              基于脚本和其他交互式程序通信。
        libexpect-5.45.so   包含一些函数允许 Expect 用作 Tcl 扩展或直接用于 C/C++（不用 Tcl）。

## 5.13. DejaGNU-1.6.2

### 5.13.1. 安装 DejaGNU

```
cd $LFS/sources
tar xvf dejagnu-1.6.2.tar.gz
cd dejagnu-1.6.2
```

```
./configure --prefix=/tools
```

```
make install
# make check
```

```
cd $LFS/sources
rm -rf dejagnu-1.6.2
```

### 5.13.2. DejaGNU 软件包内容

    安装的程序:           runtest
    简要介绍
        runtest   一个封装脚本用于定位合适的 expect 终端然后执行 DejaGNU。

## 5.14. M4-1.4.18

### 5.14.1. 安装 M4

```
cd $LFS/sources
tar xvf m4-1.4.18.tar.xz
cd m4-1.4.18
```

> 首先，对应 glibc-2.28 的需求做一些修复：

```
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
```

```
./configure --prefix=/tools
```

```
make && make install
```

```
cd $LFS/sources
rm -rf m4-1.4.18
```

## 5.15. Ncurses-6.1

### 5.15.1. 安装 Ncurses

```
cd $LFS/sources
tar xvf ncurses-6.1.tar.gz
cd ncurses-6.1
```

> 在安装之前，须要确保 gawk 在第一次配置时已经找到：

```
sed -i s/mawk// configure
```

```
./configure --prefix=/tools \
            --with-shared   \
            --without-debug \
            --without-ada   \
            --enable-widec  \
            --enable-overwrite
```

```
make && make install
ln -s libncursesw.so /tools/lib/libncurses.so
```

```
cd $LFS/sources
rm -rf ncurses-6.1
```

## 5.16. Bash-5.0

### 5.16.1. 安装 Bash

```
cd $LFS/sources
tar xvf bash-5.0.tar.gz
cd bash-5.0
```

```
./configure --prefix=/tools --without-bash-malloc
```

```
make && make install
ln -sv bash /tools/bin/sh
```

```
cd $LFS/sources
rm -rf bash-5.0
```

## 5.17. Bison-3.4.1

### 5.17.1. 安装 Bison

```
cd $LFS/sources
tar xvf bison-3.4.1.tar.xz
cd bison-3.4.1
```

```
./configure --prefix=/tools
```

```
make && make install
```

```
cd $LFS/sources
rm -rf bison-3.4.1
```

## 5.18. Bzip2-1.0.8

### 5.18.1. 安装 Bzip2

```
cd $LFS/sources
tar xvf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
```

> Bzip2 软件包里没有 configure 配置脚本。

```
make && make PREFIX=/tools install
```

```
cd $LFS/sources
rm -rf bzip2-1.0.8
```

## 5.19. Coreutils-8.31

### 5.19.1. 安装 Coreutils

```
cd $LFS/sources
tar xvf coreutils-8.31.tar.xz
cd coreutils-8.31
```

```
./configure --prefix=/tools --enable-install-program=hostname
make && make install
```

```
cd $LFS/sources
rm -rf coreutils-8.31
```

## 5.20. Diffutils-3.7

### 5.20.1. 安装 Diffutils

```
cd $LFS/sources
tar xvf diffutils-3.7.tar.xz
cd diffutils-3.7
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf diffutils-3.7
```

## 5.21. File-5.37

### 5.21.1. 安装 File

```
cd $LFS/sources
tar xvf file-5.37.tar.gz
cd file-5.37
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf file-5.37
```

## 5.22. Findutils-4.6.0

### 5.22.1. 安装 Findutils

```
cd $LFS/sources
tar xvf findutils-4.6.0.tar.gz
cd findutils-4.6.0
```

> 首先，对应 glibc-2.28 的需求做一些修复：

```
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf findutils-4.6.0
```

## 5.23. Gawk-5.0.1

### 5.23.1. 安装 Gawk

```
cd $LFS/sources
tar xvf gawk-5.0.1.tar.xz
cd gawk-5.0.1
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf gawk-5.0.1
```

## 5.24. Gettext-0.20.1

### 5.24.1. 安装 Gettext

```
cd $LFS/sources
tar xvf gettext-0.20.1.tar.xz
cd gettext-0.20.1
```

```
./configure --disable-shared
make
cp -v gettext-tools/src/{msgfmt,msgmerge,xgettext} /tools/bin
```

```
cd $LFS/sources
rm -rf gettext-0.20.1
```

## 5.25. Grep-3.3

### 5.25.1. 安装 Grep

```
cd $LFS/sources
tar xvf grep-3.3.tar.xz
cd grep-3.3
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf grep-3.3
```

## 5.26. Gzip-1.10

### 5.26.1. 安装 Gzip

```
cd $LFS/sources
tar xvf gzip-1.10.tar.xz
cd gzip-1.10
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf gzip-1.10
```

## 5.27. Make-4.2.1

### 5.27.1. 安装 Make

```
cd $LFS/sources
tar xvf make-4.2.1.tar.gz
cd make-4.2.1
```

> 首先，解决一个 glibc-2.27 或更高版本带来的问题：

```
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c
```

```
./configure --prefix=/tools --without-guile
make && make install
```

```
cd $LFS/sources
rm -rf make-4.2.1
```

## 5.28. Patch-2.7.6

### 5.28.1. 安装 Patch

```
cd $LFS/sources
tar xvf patch-2.7.6.tar.xz
cd patch-2.7.6
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf patch-2.7.6
```

## 5.29. Perl-5.30.0

### 5.29.1. 安装 Perl

```
cd $LFS/sources
tar xvf perl-5.30.0.tar.xz
cd perl-5.30.0
```

```
sh Configure -des -Dprefix=/tools -Dlibs=-lm -Uloclibpth -Ulocincpth
make
cp -v perl cpan/podlators/scripts/pod2man /tools/bin
mkdir -pv /tools/lib/perl5/5.30.0
cp -Rv lib/* /tools/lib/perl5/5.30.0
```

```
cd $LFS/sources
rm -rf perl-5.30.0
```

## 5.30. Python-3.7.4

### 5.30.1. 安装 Python

>> 注意
> 有两个名称以 “python” 开头的包文件。注意要解压的是 Python-3.7.4.tar.xz（首字母大写的那个）。

```
cd $LFS/sources
tar xvf Python-3.7.4.tar.xz
cd Python-3.7.4
```

> 这个软件包首先构建 Python 解释器，然后是一些标准的 Python 模块。构建模块的主要脚本是用 Python 编写的，并使用宿主机 /usr/include 和 /usr/lib 目录的硬编码路径。以此防止他们被使用，输入：

```
sed -i '/def add_multiarch_paths/a \        return' setup.py
```

>> 注意
> 译注：PDF 文档在复制上述命令时，需注意「\」到「return」之间要保留 2 个 Tab、或 8 个空格的缩进。

```
./configure --prefix=/tools --without-ensurepip
make && make install
```

```
cd $LFS/sources
rm -rf Python-3.7.4
```

## 5.31. Sed-4.7

### 5.31.1. 安装 Sed

```
cd $LFS/sources
tar xvf sed-4.7.tar.xz
cd sed-4.7
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf sed-4.7
```

## 5.32. Tar-1.32

### 5.32.1. 安装 Tar

```
cd $LFS/sources
tar xvf tar-1.32.tar.xz
cd tar-1.32
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf tar-1.32
```

## 5.33. Texinfo-6.6

### 5.33.1. 安装 Texinfo

```
cd $LFS/sources
tar xvf texinfo-6.6.tar.xz
cd texinfo-6.6
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf texinfo-6.6
```

## 5.34. Xz-5.2.4

### 5.34.1. 安装 Xz

```
cd $LFS/sources
tar xvf xz-5.2.4.tar.xz
cd xz-5.2.4
```

```
./configure --prefix=/tools
make && make install
```

```
cd $LFS/sources
rm -rf xz-5.2.4
```

## 5.35. 清理无用内容

> 本小节里的步骤是可选的，但如果你的 LFS 分区容量比较小，知道有些不必要的内容可以被删除也是挺好的。目前编译好的可执行文件和库大概会有 70MB 左右不需要的调试符号。可以通过下面的命令移除这些符号：

```
strip --strip-debug /tools/lib/*
/usr/bin/strip --strip-unneeded /tools/{,s}bin/*
```

> 注意不要对库文件使用 --strip-unneeded 选项。静态库会被损坏导致整个工具链将会需要全部重新编译。

> 更节省更多空间，还可以删除帮助文档：
```
rm -rf /tools/{,share}/{info,man,doc}
```

> 删除不需要的文件：

```
find /tools/{lib,libexec} -name \*.la -delete
```

> 这个时候，你应该在 $LFS 分区中为下个阶段编译安装 Glibc 和 GCC 预留至少 3GB 剩余空间。如果你可以编译安装 Glibc，那其他的就不会有问题了。

## 5.36. 改变属主

>> 注意
> 
> 本书余下部分的命令都必须以 root 用户身份执行而不再是 lfs 用户。另外，再次确认下 $LFS 变量在 root 用户环境下也有定义。
> 
> 通过下面的命令将 $LFS/tools 目录的属主改为 root 用户：

```
# 从lfs用户切换到root用户然后执行以下命令：
chown -R root:root $LFS/tools
```

>> 小心
> 
> 如果你想保留临时工具用来构建新的 LFS 系统，现在就要备份好。本书随后第六章中的指令将对当前的工具做些调整，导致在构建新系统时会失效。

# 第 6 章 安装基本的系统软件

## 6.1. 简介

> 在本章中，我们会进入构建环境开始认真地构建 LFS 系统了。我们将 chroot 到之前准备好的临时迷你 Linux 系统，做一些最后的准备工作，然后就开始安装软件包。
> 
> 安装软件很简单。尽管很多时候安装指令能更短而且更具通用性，但我们还是选择为每个软件包都提供完整的指令，以减小引起错误的可能性。了解 Linux 系统如何工作的关键就是知道每个软件包的作用以及为什么你（或系统）需要它。
>
>不建议在编译时使用优化。第一次构建 LFS 系统还是推荐不要使用自定义优化。这样构建出来的系统一样会运行得很快，于此同时还很稳定。
> 
> 本章里安装软件包的顺序需要严格遵守，这是为了保证不会有程序意外地依赖与 /tools 路径的硬链相关的目录。同样的理由，不要同时编译不同的软件包。并行地编译也许能节省一点时间（特别是在双 CPU 电脑上），但是它可能会导致程序里存在包含到 /tools 目录的硬链接，这样的话在这个目录移除后程序就不能正常工作了。

### 6.1.1. 关于库

> 并不推荐构建和安装静态库。
> 
> 第六章的程序，我们移除或禁止了大部分静态库的安装。通常通过在 configure 命令中使用 --disable-static 项，便可以做到。有些情况下，可能用到其他代替的办法。当然也有少数情况，特别是 glibc 和 gcc 使用的静态库在软件包的构建过程中是必不可少的。

## 6.2. 准备虚拟内核文件系统

> 内核会挂载几个文件系统用于自己和用户空间程序交换信息。这些文件系统是虚拟的，并不占用实际磁盘空间，它们的内容会放在内存里。
>
> 开始先创建将用来挂载文件系统的目录：

```
mkdir -pv $LFS/{dev,proc,sys,run}
```

### 6.2.1. 创建初始设备节点

> 在内核引导系统的时候，它依赖于几个设备节点，特别是 console 和 null 两个设备。设备点必须创建在硬盘上以保证在 udevd 启动前是可用的，特别是在使用 init=/bin/bash 启动 Linux 时。
> 
> 运行以下命令创建设备节点：

```
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3
```

### 6.2.2. 挂载和激活 /dev

> 通常激活 /dev 目录下设备的方式是在 /dev 目录挂载一个虚拟文件系统（比如 tmpfs），然后允许在检测到设备或打开设备时在这个虚拟文件系统里动态创建设备节点。这个通常是在启动过程中由 udev 完成。由于我们的新系统还没有 udev，也没有被引导，有必要手动挂载和激活 /dev 这可以通过绑定挂载宿主机系统的 /dev 目录来实现。绑定挂载是一种特殊的挂载模式，它允许在另外的位置创建某个目录或挂载点的镜像。
> 
> 运行下面的命令来实现：

```
mount -v --bind /dev $LFS/dev
```

### 6.2.3. 挂载虚拟文件系统

> 现在挂载剩下的虚拟内核文件系统：

```
mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
```

> 在某些宿主机系统里，/dev/shm 是一个指向 /run/shm 的符号链接。这个 /run 下的 tmpfs 文件系统已经在之前挂载了，所以在这里只需要创建一个目录。

```
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
```

## 6.3. 软件包管理

> 为什么 LFS 或 BLFS 手册里不采用任何软件包管理器的一些原因：
> - 使用软件包管理偏离了本手册的主要目标——教大家 Linux 系统是如何构建出来的。
> - 存在很多软件包管理的解决方案，每一个都有自己的长处和缺点。很难选择一种适合所有人的方式。

### 6.3.2. 软件包管理技术

#### 6.3.2.1. 所有一切都在我脑袋里！

> 是的，这也算一种软件包管理技术。有些人觉得不需要管理软件包，是因为他们非常熟悉软件包，知道每个包都安装了哪些文件。也有些用户不需要管理软件包，是因为他们会在某个软件包有更改后重建整个系统。

#### 6.3.2.2. 在独立目录里安装

> 这是一种简单的软件包管理方式，不需要其他额外的软件来管理软件的安装。每一个软件包都被装到一个独立的目录里。例如，软件包 foo-1.1 安装到目录 /usr/pkg/foo-1.1 中并创建一个符号链接 /usr/pkg/foo 指向 /usr/pkg/foo-1.1。在安装新版本 foo-1.2 的时候，它会被装到目录 /usr/pkg/foo-1.2 中，然后用指向新版本的软链替代之前的符号链接。

> 类似 PATH、LD_LIBRARY_PATH、MANPATH、INFOPATH 和 CPPFLAGS 之类的环境变量变量需要包含 /usr/pkg/foo 目录。在管理大量软件包时，这种方式就不可行了。

#### 6.3.2.3. 符号链接方式软件包管理

> 这是前一种软件包管理技术的变种。每个软件包的安装方式都和之前的方式类似。但不是建立目录的符号链接，而是把每个文件都链接到 /usr 目录结构里。这样就不需要扩展环境变量了。通过自动创建这些可由用户自行创建的软链，许多软件包管理器就采用了这种方式进行管理的。其中比较流行的有 Stow、Epkg、Graft 和 Depot。

> 正确的方式是使用 DESTDIR 策略来伪装软件包的安装过程。这种方式需要像下面这样操作：
>
> ```
> ./configure --prefix=/usr
> make
> make DESTDIR=/usr/pkg/libfoo/1.1 install
> ```
>
> 大多数软件包支持这种方式，但也有一些例外。对于不兼容的软件包，你可能需要自己手动安装，或许你会发现将这些有问题的包安装到 /opt 目录下会更简单些。

#### 6.3.2.4. 基于时间戳

> 在这种方式里，在安装之前会创建一个时间戳文件。在安装之后，用一行简单的 find 命令加上合适的参数就可以生成在时间戳文件创建之后所安装的所有文件列表。有一个采用这种方式的包管理器叫做 install-log。
>
> 这种方式的优点是非常简单，但是它有两个缺陷。比如，在安装过程中，所安装文件采用的是其它时间戳而不是当前时间，那这些文件将不能被软件包管理器跟踪到。还有，这种方式只能在一次安装一个软件包的情况下使用。如果在不同的终端里同时安装两个不同的软件包，此时的安装日志就不可靠了。

#### 6.3.2.5. 追踪安装脚本

> 在这种方式里，安装脚本所使用的命令都会被记录下来。有两种技术，一种是：
>
> 设定环境变量 LD_PRELOAD 指向一个在安装前预加载的库。在安装过程中，这个库会追踪软件包安装脚本里所包含的各种执行文件比如 cp、install、mv，以及追踪会修改文件系统的系统调用。要让这种方式有效的话，所有的执行文件需要动态链接到没有 suid 或 sgid 标志位的库。预加载这个库可能会引起安装过程中一些意外的副作用。因此，建议做一些测试以保证软件包管理器不会造成破坏并且记录了所有适当的文件。
>
> 第二种技术是使用 strace 命令，它会记录下安装脚本执行过程中所有的系统调用。

#### 6.3.2.6. 创建软件包存档

> 在这种方式里，像之前的符号链接软件包管理方式里所描述的那样，软件包被伪装安装到一个独立的目录树里。在安装完成后，会将已安装文件打包成一个软件包存档。然后这个存档会用来在本地机器或其他机器上安装软件包。
>
> 这种方式为商业发行版中的大多数包管理器所采用。例子有 RPM（顺带提一下，这也是 Linux 标准规范 中指定的包管理器），pkg-utils，Debian 的 apt，和 Gentoo 的 Portage 系统。如何在 LFS 系统里采用这种包管理方式的简单描述，请参看 http://www.linuxfromscratch.org/hints/downloads/files/fakeroot.txt.
>
> 创建带有依赖关系的软件包存档非常复杂，已经超出 LFS 手册范围了。
>
> Slackware 使用一个基于 tar 的系统来创建软件包存档。这套系统不像那些更复杂的包管理器，有意地不处理包依赖关系。关于 Slackware 包管理器的详细信息，请参看 http://www.slackbook.org/html/package-management.html。

#### 6.3.2.7. 基于用户的软件包管理

> 这种方式，是 LFS 特有的，由 Matthias Benkmann 所设计，可以在 Hints Project 中能找到。在这种方式里，每个软件包都由一个单独的用户安装到标准的位置。文件属于某个软件包可以通过检查用户 ID 轻松识别出来。关于这种方式的利弊比较复杂，就不再本节中赘述了。详细的信息请参看 http://www.linuxfromscratch.org/hints/downloads/files/more_control_and_pkg_man.txt。

### 6.3.3. 在多个系统上部署 LFS

> LFS 系统的一个优点是没有那种需要依赖其在磁盘系统中的位置的文件。克隆一份 LFS 到和宿主机器相似配置的机器上，简单到只要对包含根目录的 LFS 分区（对于一个基本的 LFS 构建不压缩的话大概有 250MB）使用 tar 命令打包，然后通过网络传输或光盘拷贝到新机器上展开即可。在这之后，需要调整一些配置文件。需要更新的配置文件包括： /etc/hosts, /etc/fstab, /etc/passwd, /etc/group, /etc/shadow, /etc/ld.so.conf, /etc/sysconfig/rc.site, /etc/sysconfig/network, 和 /etc/sysconfig/ifconfig.eth0。
>
> 根据系统硬件和原始内核配置文件的差异，可能还需要重新编译一下内核。
>
>> 注意
>>
>> 据报告，当这样的复制发生在两个相近却又不完全相同的架构时会发生问题。例如，Intel 系统的指令集就和 AMD 处理器的不同，还有一些较新版的处理器可能会有一些在较早版本中不能支持的指令。
>
> 最后，通过 第 8.4 节 「使用 GRUB 设置启动过程」 中介绍的方法来使新系统可以引导。

## 6.4. 进入 Chroot 环境

> 以 root 用户运行下面的命令进入此环境，从现在开始，就只剩下准备的那些临时工具了：

```
chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h
```

> 给 env 命令传递 -i 选项会清除这个 chroot 切换进去的环境中的所有变量。随后，只需重新设定 HOME、TERM、PS1 、和 PATH 变量。TERM=$TERM 将会把 TERM 设定成 chroot 外环境相同的值。许多程序需要这个变量才能正常工作，比如 vim 和 less。如果还需设定其他变量，如 CFLAGS 或 CXXFLAGS，正好在这一起设置了。
>
> 在这之后，LFS 变量就不再需要了，因为后面所有工作都将被限定在 LFS 文件系统中。因为我们已经告诉 Bash 终端 $LFS 就是当前的根目录（/）目录。
>
> 注意要将 /tools/bin 放在 PATH 变量的最后。意思是在每个软件的最后版本编译安装好后就不再使用临时工具了。这还需要让 shell 不要「记住」每个可执行文件的位置——这样的话，还要给 bash 加上 +h 选项来关闭其哈希功能。
>
> 注意一下 bash 的提示符是 I have no name! 这是正常的，因为这个时候 /etc/passwd 文件还没有被创建。
>
>> 注意
>>
>> 非常重要，从本章开始，后续章节中的命令都要在 chroot 环境下运行。如果因为某种原因（比如说重启）离开了这个环境，请保证要按照 第 6.2.2 节 「挂载和激活 /dev」 和 第 6.2.3 节 「挂载虚拟文件系统」 中所说的那样挂载虚拟内核文件系统，并在继续构建之前重新运行 chroot 进入环境。

## 6.5. 创建目录

> 创建一个标准的目录树：

```
mkdir -pv /{bin,boot,etc/{opt,sysconfig},home,lib/firmware,mnt,opt}
mkdir -pv /{media/{floppy,cdrom},sbin,srv,var}
install -dv -m 0750 /root
install -dv -m 1777 /tmp /var/tmp
mkdir -pv /usr/{,local/}{bin,include,lib,sbin,src}
mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
mkdir -v  /usr/{,local/}share/{misc,terminfo,zoneinfo}
mkdir -v  /usr/libexec
mkdir -pv /usr/{,local/}share/man/man{1..8}

case $(uname -m) in
 x86_64) mkdir -v /lib64 ;;
esac

mkdir -v /var/{log,mail,spool}
ln -sv /run /var/run
ln -sv /run/lock /var/lock
mkdir -pv /var/{opt,cache,lib/{color,misc,locate},local}
```

> 一般目录默认会按 755 的权限创建，但是这并不适用于所有的目录。在上面的命令里，有两个改动——一个是 root 的 home 目录，另一个是存放临时文件的目录。
>
> 第一个模式改动能保证不是所有人都能进入 /root 目录——同样一般用户也需要为他/她的 home 目录设置这样的模式。第二个模式改动能保证所有用户对目录 /tmp 和 /var/tmp 都是可写的，但又不能移除其他用户的文件。后面的这个限制是由所谓的「粘滞位」实现的，即位掩码 1777 中的最高位（1）。

### 6.5.1. 关于 FHS 兼容性

> 这个目录树是基于文件系统目录结构标准（FHS）（参看 https://refspecs.linuxfoundation.org/fhs.shtml）。FHS 标准还规定了要有 /usr/local/games 和 /usr/share/games 目录。我们只创建了我们需要的目录。然而，如果你更喜欢严格遵守 FHS 标准，创建这些目录也无妨。

## 6.6. 创建必要的文件和符号链接

> 有些程序里会使用写死的路径调用其它暂时还未安装的程序。为了满足这种类型程序的需要，我们将创建一些符号链接，在完成本章内容后这些软件会安装好，并替代之前的符号链接：

```
ln -sv /tools/bin/{bash,cat,chmod,dd,echo,ln,mkdir,pwd,rm,stty,touch} /bin
ln -sv /tools/bin/{env,install,perl,printf}         /usr/bin
ln -sv /tools/lib/libgcc_s.so{,.1}                  /usr/lib
ln -sv /tools/lib/libstdc++.{a,so{,.6}}             /usr/lib

ln -sv bash /bin/sh
```

> 由于历史原因，Linux 在文件 /etc/mtab 中维护一个已挂载文件系统的列表。而现代内核改为在内部维护这个列表，并通过 /proc 文件系统输出给用户。为了满足一些依赖 /etc/mtab 文件的应用程序，我们要创建下面的符号链接：


```
ln -sv /proc/self/mounts /etc/mtab
```

> 创建 /etc/passwd 文件：

```
cat > /etc/passwd << "EOF"
root:x:0:0:root:/root:/bin/bash
bin:x:1:1:bin:/dev/null:/bin/false
daemon:x:6:6:Daemon User:/dev/null:/bin/false
messagebus:x:18:18:D-Bus Message Daemon User:/var/run/dbus:/bin/false
nobody:x:99:99:Unprivileged User:/dev/null:/bin/false
EOF
```

> 创建 /etc/group 文件：

```
cat > /etc/group << "EOF"
root:x:0:
bin:x:1:daemon
sys:x:2:
kmem:x:3:
tape:x:4:
tty:x:5:
daemon:x:6:
floppy:x:7:
disk:x:8:
lp:x:9:
dialout:x:10:
audio:x:11:
video:x:12:
utmp:x:13:
usb:x:14:
cdrom:x:15:
adm:x:16:
messagebus:x:18:
input:x:24:
mail:x:34:
kvm:x:61:
wheel:x:97:
nogroup:x:99:
users:x:999:
EOF
```
> 这里创建的用户组没有参照任何标准——它们一部分是为了满足本章中配置 udev 的需要，还有一部分来自一些现存 Linux 发行版的通用设定。另外，某些测试套件也依赖特定用户或组。而 Linux 标准规范 （LSB，参见 http://www.linuxbase.org）只要求以组 ID（GID）为 0 创建用户组 root 以及以 GID 为 1 创建用户组 bin。系统管理员可以自由分配其它所有用户组名字和 GID，因为优秀的程序不会依赖 GID 数字，而是使用组名。

> 为了移除「I have no name!」的提示符，可以打开一个新 shell。由于完整的 Glibc 已经在 第 5 章 里装好了，而且已经创建好了 /etc/passwd 和 /etc/group 文件，用户名和组名就可以正常解析了：

```
exec /tools/bin/bash --login +h
```
> 注意这里使用了 +h 参数。这样会告诉 bash 不要使用它内建的路径哈希功能。而不加这个参数的话，bash 将会记住曾经执行过程序的路径。为了在新编译安装好程序后就能马上使用，参数 +h 将在本章中一直使用。
>
> 程序 login、agetty 和 init（还有一些其它的）会使用一些日志文件来记录信息，比如谁在什么时候登录了系统。不过，在日志文件不存在的时候这些程序一般不会写入。下面初始化一下日志文件并加上合适的权限：

```
touch /var/log/{btmp,lastlog,faillog,wtmp}
chgrp -v utmp /var/log/lastlog
chmod -v 664  /var/log/lastlog
chmod -v 600  /var/log/btmp
```
> 文件 /var/log/wtmp 会记录所有的登录和登出动作。文件 /var/log/lastlog 会记录每个用户的最后一次登录时间。文件 /var/log/faillog 会记录失败的登录尝试。文件 /var/log/btmp 会记录非法的登录尝试。
>
>> 注意
>>
>> 文件 /run/utmp 会记录当前已登录的用户。这个文件会在启动脚本中动态创建。

## 6.7. Linux-5.2.8 API 头文件

### 6.7.1. Linux API 头文件的安装

```
cd $LFS/sources
tar xvf linux-5.2.8.tar.xz
cd linux-5.2.8
```

> 确保在之前的动作里没有留下旧文件和依赖关系：
```
make mrproper
```

> 现在要从源代码里解压出用户需要的内核头文件。因为解压过程会删除目标目录下所有文件，所以我们会先输出到一个本地中间目录后再拷贝到需要的地方。而且里面还有一些隐藏文件是给内核开发人员用的，而 LFS 不需要，所以会将它们从中间目录里删除。
```
make INSTALL_HDR_PATH=dest headers_install
find dest/include \( -name .install -o -name ..install.cmd \) -delete
cp -rv dest/include/* /usr/include
```

```
cd $LFS/sources
rm -rf linux-5.2.8
```

### 6.7.2. Linux API 头文件内容
    安装的头文件:
        /usr/include/asm/*.h, /usr/include/asm-generic/*.h, /usr/include/drm/*.h, /usr/include/linux/*.h, /usr/include/misc/*.h, /usr/include/mtd/*.h, /usr/include/rdma/*.h, /usr/include/scsi/*.h, /usr/include/sound/*.h, /usr/include/video/*.h, 和 /usr/include/xen/*.h
    安装的目录:
        /usr/include/asm, /usr/include/asm-generic, /usr/include/drm, /usr/include/linux, /usr/include/misc, /usr/include/mtd, /usr/include/rdma, /usr/include/scsi, /usr/include/sound, /usr/include/video, 和 /usr/include/xen
    简要介绍
        /usr/include/asm/*.h            Linux API ASM 头文件
        /usr/include/asm-generic/*.h    Linux API ASM 通用头文件
        /usr/include/drm/*.h            Linux API DRM 头文件
        /usr/include/linux/*.h          Linux API Linux 头文件
        /usr/include/misc/*.h           Linux API misc 头文件
        /usr/include/mtd/*.h            Linux API MTD 头文件
        /usr/include/rdma/*.h           Linux API RDMA 头文件
        /usr/include/scsi/*.h           Linux API SCSI 头文件
        /usr/include/sound/*.h          Linux API 音频头文件
        /usr/include/video/*.h          Linux API 视频头文件
        /usr/include/xen/*.h            Linux API Xen 头文件

## 6.8. Man-pages-5.02

### 6.8.1. 安装 Man-pages

```
cd $LFS/sources
tar xvf man-pages-5.02.tar.xz
cd man-pages-5.02
```

```
make install
```

```
cd $LFS/sources
rm -rf man-pages-5.02
```

## 6.9. Glibc-2.30

### 6.9.1. 安装 Glibc

```
cd $LFS/sources
tar xvf glibc-2.30.tar.xz
cd glibc-2.30
```
> 有些 Glibc 程序会用到和 FHS 不兼容的 /var/db 目录来存储它们的运行时数据。打上如下的补丁让这些程序在 FHS 兼容的位置存储它们的运行时数据。
```
patch -Np1 -i ../glibc-2.30-fhs-1.patch
```

> 修复 linux-5.2 内核引入的问题：
```
sed -i '/asm.socket.h/a# include <linux/sockios.h>' \
   sysdeps/unix/sysv/linux/bits/socket.h
```

> 顺应 LSB 规范创建一个符号链接。此外，x86_64 情况下，为了使动态加载器正确运作，再创建一个兼容性的符号链接：
```
case $(uname -m) in
    i?86)   ln -sfv ld-linux.so.2 /lib/ld-lsb.so.3
    ;;
    x86_64) ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64
            ln -sfv ../lib/ld-linux-x86-64.so.2 /lib64/ld-lsb-x86-64.so.3
    ;;
esac
```

> Glibc 文档里建议在 Glibc 特定编译目录下编译：
```
mkdir -v build
cd       build

CC="gcc -ffile-prefix-map=/tools=/usr" \
../configure --prefix=/usr                          \
             --disable-werror                       \
             --enable-kernel=3.2                    \
             --enable-stack-protector=strong        \
             --with-headers=/usr/include            \
             libc_cv_slibdir=/lib

make
```

>> 重要
>>
>> 在本小节里，运行 Glibc 的测试套件是很关键的。在任何情况下都不要跳过这个测试。 
```
case $(uname -m) in
  i?86)   ln -sfnv $PWD/elf/ld-linux.so.2        /lib ;;
  x86_64) ln -sfnv $PWD/elf/ld-linux-x86-64.so.2 /lib ;;
esac

make check
```

> 修补
```
touch /etc/ld.so.conf

sed '/test-installation/s@$(PERL)@echo not running@' -i ../Makefile
```

> 安装
```
make install

cp -v ../nscd/nscd.conf /etc/nscd.conf
mkdir -pv /var/cache/nscd
```

> 安装能完美覆盖测试所需语言环境的最小集合：
```
mkdir -pv /usr/lib/locale
localedef -i POSIX -f UTF-8 C.UTF-8 2> /dev/null || true
localedef -i cs_CZ -f UTF-8 cs_CZ.UTF-8
localedef -i de_DE -f ISO-8859-1 de_DE
localedef -i de_DE@euro -f ISO-8859-15 de_DE@euro
localedef -i de_DE -f UTF-8 de_DE.UTF-8
localedef -i el_GR -f ISO-8859-7 el_GR
localedef -i en_GB -f UTF-8 en_GB.UTF-8
localedef -i en_HK -f ISO-8859-1 en_HK
localedef -i en_PH -f ISO-8859-1 en_PH
localedef -i en_US -f ISO-8859-1 en_US
localedef -i en_US -f UTF-8 en_US.UTF-8
localedef -i es_MX -f ISO-8859-1 es_MX
localedef -i fa_IR -f UTF-8 fa_IR
localedef -i fr_FR -f ISO-8859-1 fr_FR
localedef -i fr_FR@euro -f ISO-8859-15 fr_FR@euro
localedef -i fr_FR -f UTF-8 fr_FR.UTF-8
localedef -i it_IT -f ISO-8859-1 it_IT
localedef -i it_IT -f UTF-8 it_IT.UTF-8
localedef -i ja_JP -f EUC-JP ja_JP
localedef -i ja_JP -f SHIFT_JIS ja_JP.SIJS 2> /dev/null || true
localedef -i ja_JP -f UTF-8 ja_JP.UTF-8
localedef -i ru_RU -f KOI8-R ru_RU.KOI8-R
localedef -i ru_RU -f UTF-8 ru_RU.UTF-8
localedef -i tr_TR -f UTF-8 tr_TR.UTF-8
localedef -i zh_CN -f GB18030 zh_CN.GB18030
localedef -i zh_HK -f BIG5-HKSCS zh_HK.BIG5-HKSCS
```

> 另外，安装适合你自己国家/地区、语言和字符集的语言环境。
```
localedef -i zh_CN -f UTF-8 zh_CN.UTF-8
```

> 或者，也可以一次性安装在 glibc-2.30/localedata/SUPPORTED 文件里列出的所有语言环境（包括以上列出的所有语言环境以及其它更多），执行下面这个非常耗时的命令：
>
> ```
> make localedata/install-locales
> ```

### 6.9.2. 配置 Glibc

#### 6.9.2.1. 添加 nsswitch.conf

由于 Glibc 的默认状态在网络环境下工作的并不好，所以需要创建 /etc/nsswitch.conf 文件。

创建新的 /etc/nsswitch.conf 通过以下命令：

```
cat > /etc/nsswitch.conf << "EOF"
# Begin /etc/nsswitch.conf

passwd: files
group: files
shadow: files

hosts: files dns
networks: files

protocols: files
services: files
ethers: files
rpc: files

# End /etc/nsswitch.conf
EOF
```

#### 6.9.2.2. 添加时区数据

> 安装并启动时区数据：
```
tar -xf ../../tzdata2019b.tar.gz

ZONEINFO=/usr/share/zoneinfo
mkdir -pv $ZONEINFO/{posix,right}

for tz in etcetera southamerica northamerica europe africa antarctica  \
          asia australasia backward pacificnew systemv; do
    zic -L /dev/null   -d $ZONEINFO       ${tz}
    zic -L /dev/null   -d $ZONEINFO/posix ${tz}
    zic -L leapseconds -d $ZONEINFO/right ${tz}
done

cp -v zone.tab zone1970.tab iso3166.tab $ZONEINFO
zic -d $ZONEINFO -p America/New_York
unset ZONEINFO
```

> 确定本地时区：
```
tzselect
```
> 在询问了几个关于位置的问题后，脚本会输出所在时区的名字（比如 America/Edmonton)）。在 /usr/share/zoneinfo 文件中也有其它一些可用时区，比如 Canada/Eastern 或 EST5EDT，这些时区并没有被脚本列出来但也是可以使用的。
>
> 创建 /etc/localtime 文件：
```
ln -sfv /usr/share/zoneinfo/<xxx> /etc/localtime
```
> 将命令中的 <xxx> 替换成你所在实际时区的名字（比如 Canada/Eastern）。

#### 6.9.2.3. 配置动态库加载器

> 运行下面的命令创建一个新文件 /etc/ld.so.conf
```
cat > /etc/ld.so.conf << "EOF"
# Begin /etc/ld.so.conf
/usr/local/lib
/opt/lib

EOF
```

> 动态库加载器也可以查找目录并包含里面配置文件的内容。
```
cat >> /etc/ld.so.conf << "EOF"
# Add an include directory
include /etc/ld.so.conf.d/*.conf

EOF
mkdir -pv /etc/ld.so.conf.d
```

```
cd $LFS/sources
rm -rf glibc-2.30
```

## 6.10. 调整工具链

> 首先，备份 /tools 链接器，然后用我们在第五章调整过的链接器代替它。我们还会创建一个链接，链接到 /tools/$(uname -m)-pc-linux-gnu/bin 的副本：
```
mv -v /tools/bin/{ld,ld-old}
mv -v /tools/$(uname -m)-pc-linux-gnu/bin/{ld,ld-old}
mv -v /tools/bin/{ld-new,ld}
ln -sv /tools/bin/ld /tools/$(uname -m)-pc-linux-gnu/bin/ld
```

> 改 GCC 参数文件，让它指向新的动态连接器。
```
gcc -dumpspecs | sed -e 's@/tools@@g'                   \
    -e '/\*startfile_prefix_spec:/{n;s@.*@/usr/lib/ @}' \
    -e '/\*cpp:/{n;s@$@ -isystem /usr/include@}' >      \
    `dirname $(gcc --print-libgcc-file-name)`/specs
```

> 确保已调整的工具链的基本功能（编译和链接）都能如期进行
```
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
```
> 如果没有任何错误，上条命令的输出应该是（不同的平台上的动态链接器可能名字不同）：
>
> `[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]`

> 现在确保我们已经设置好了启动文件：
```
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
```
> 上一条命令的输出应该是：
> ```
> /usr/lib/../lib/crt1.o succeeded
> /usr/lib/../lib/crti.o succeeded
> /usr/lib/../lib/crtn.o succeeded
> ```

> 确保链接器能找到正确的头文件：
```
grep -B1 '^ /usr/include' dummy.log
```
> 这条命令应该返回如下输出：
> ```
> #include <...> search starts here:
> /usr/include
> ```

> 接下来，确认新的链接器已经在使用正确的搜索路径：
```
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
```

> 应该忽略指向带有 '-linux-gnu' 的路径，上条命令的输出应该是：
> ```
> SEARCH_DIR("/usr/lib")
> SEARCH_DIR("/lib")
> ```

> 然后我们要确定我们使用的是正确的 libc：
```
grep "/lib.*/libc.so.6 " dummy.log
```
> 上条命令的输出应该为：
> ```
> attempt to open /lib/libc.so.6 succeeded
> ```

> 最后，确保 GCC 使用的是正确的动态链接器：
```
grep found dummy.log
```

> 上条命令的结果应该是（不同的平台上链接器名字可以不同）：
> ```
> found ld-linux-x86-64.so.2 at /lib/ld-linux-x86-64.so.2
> ```
> 如果显示的结果不一样或者根本没有显示，那就出了大问题。检查并回溯之前的步骤，找到出错的地方并改正。最有可能的原因是参数文件的调整出了问题。在进行下一步之前所有的问题都要解决。

> 确保一切正常之后，清除测试文件：
```
rm -v dummy.c a.out dummy.log
```

## 6.11. Zlib-1.2.11

### 6.11.1. 安装 Zlib

```
cd $LFS/sources
tar xvf zlib-1.2.11.tar.xz
cd zlib-1.2.11
```

```
./configure --prefix=/usr
make
make check
make install
```

> 共享库需要移动到 /lib，因此需要重建 .so 里面的 /usr/lib 文件：
```
mv -v /usr/lib/libz.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libz.so) /usr/lib/libz.so
```

```
cd $LFS/sources
rm -rf zlib-1.2.11
```

## 6.12. File-5.37

### 6.12.1. 安装 File

```
cd $LFS/sources
tar xvf file-5.37.tar.gz
cd file-5.37
```

```
./configure --prefix=/usr
make
make check
make install
```

```
cd $LFS/sources
rm -rf file-5.37
```

## 6.13. Readline-8.0

### 6.13.1. 安装 Readline

```
cd $LFS/sources
tar xvf readline-8.0.tar.gz
cd readline-8.0
```

```
sed -i '/MV.*old/d' Makefile.in
sed -i '/{OLDSUFF}/c:' support/shlib-install
```

```
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/readline-8.0

make SHLIB_LIBS="-L/tools/lib -lncursesw"

make SHLIB_LIBS="-L/tools/lib -lncursesw" install
```

> 移动动态库到更合适的位置并修正一些文件权限和符号链接：
```
mv -v /usr/lib/lib{readline,history}.so.* /lib
chmod -v u+w /lib/lib{readline,history}.so.*
ln -sfv ../../lib/$(readlink /usr/lib/libreadline.so) /usr/lib/libreadline.so
ln -sfv ../../lib/$(readlink /usr/lib/libhistory.so ) /usr/lib/libhistory.so
```

> 如果需要的话，安装帮助文档：
```
install -v -m644 doc/*.{ps,pdf,html,dvi} /usr/share/doc/readline-8.0
```

```
cd $LFS/sources
rm -rf readline-8.0
```

## 6.14. M4-1.4.18

### 6.14.1. 安装 M4

```
cd $LFS/sources
tar xvf m4-1.4.18.tar.xz
cd m4-1.4.18
```

> 对应 glibc-2.28 的需求做一些修复：
```
sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' lib/*.c
echo "#define _IO_IN_BACKUP 0x100" >> lib/stdio-impl.h
```

```
./configure --prefix=/usr
make
make check
make install
```

```
cd $LFS/sources
rm -rf m4-1.4.18
```

## 6.15. Bc-2.1.3

### 6.15.1. 安装 Bc

```
cd $LFS/sources
tar xvf bc-2.1.3.tar.gz
cd bc-2.1.3
```

```
PREFIX=/usr CC=gcc CFLAGS="-std=c99" ./configure.sh -G -O3
make
make test
make install
```

```
cd $LFS/sources
rm -rf bc-2.1.3
```

## 6.16. Binutils-2.32

### 6.16.1. 安装 Binutils

```
cd $LFS/sources
tar xvf binutils-2.32.tar.xz
cd binutils-2.32
```

> 通过一个简单测试验证在 chroot 环境下 PTY 工作正常：
```
expect -c "spawn ls"
```
> 这个命令应该输出以下内容：
> ```
> spawn ls
> ```

> 删除一项测试，以保证不会影响到测试的完成：
```
sed -i '/@\tincremental_copy/d' gold/testsuite/Makefile.in
```

> Binutils 的文档建议在一个专用的编译目录中编译 Binutils：
```
mkdir -v build
cd       build
```

```
../configure --prefix=/usr       \
             --enable-gold       \
             --enable-ld=default \
             --enable-plugins    \
             --enable-shared     \
             --disable-werror    \
             --enable-64-bit-bfd \
             --with-system-zlib

make tooldir=/usr

make -k check

make tooldir=/usr install
```

>> 重要
>
> 本章节中的 Binutils 测试套件至关重要，任何情况下都不能跳过。

```
cd $LFS/sources
rm -rf binutils-2.32
```

## 6.17. GMP-6.1.2

### 6.17.1. 安装 GMP

```
cd $LFS/sources
tar xvf gmp-6.1.2.tar.xz
cd gmp-6.1.2
```

```
./configure --prefix=/usr    \
            --enable-cxx     \
            --disable-static \
            --docdir=/usr/share/doc/gmp-6.1.2

make
make html
make check 2>&1 | tee gmp-check-log
```

> 确认测试套件中所有的 190 个测试都通过了。通过输入下面的命令检查结果：
```
awk '/# PASS:/{total+=$3} ; END{print total}' gmp-check-log
```

```
make install
make install-html
```

```
cd $LFS/sources
rm -rf gmp-6.1.2
```

## 6.18. MPFR-4.0.2

### 6.18.1. 安装 MPFR

```
cd $LFS/sources
tar xvf mpfr-4.0.2.tar.xz
cd mpfr-4.0.2
```

```
./configure --prefix=/usr        \
            --disable-static     \
            --enable-thread-safe \
            --docdir=/usr/share/doc/mpfr-4.0.2

make
make html

make check

make install
make install-html
```

```
cd $LFS/sources
rm -rf mpfr-4.0.2
```

## 6.19. MPC-1.1.0

### 6.19.1. 安装 MPC

```
cd $LFS/sources
tar xvf mpc-1.1.0.tar.gz
cd mpc-1.1.0
```

```
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/mpc-1.1.0

make
make html

make check

make install
make install-html
```

```
cd $LFS/sources
rm -rf mpc-1.1.0
```

## 6.20. Shadow-4.7

### 6.20.1. 安装 Shadow

```
cd $LFS/sources
tar xvf shadow-4.7.tar.xz
cd shadow-4.7
```

>> 注意
>
> 如果你喜欢强制使用更强的密码，在编译 Shadow 之前可以根据 http://www.linuxfromscratch.org/blfs/view/9.0/postlfs/cracklib.html 安装 CrackLib。然后在下面的 configure 命令中增加 --with-libcrack。

> 禁用对 groups 程序以及相应 man 手册的安装，Coreutils 已经提供了更棒的版本。同时也避免了安装已由 第 6.8 节 「Man-pages-5.02」 安装过的手册页：
```
sed -i 's/groups$(EXEEXT) //' src/Makefile.in
find man -name Makefile.in -exec sed -i 's/groups\.1 / /'   {} \;
find man -name Makefile.in -exec sed -i 's/getspnam\.3 / /' {} \;
find man -name Makefile.in -exec sed -i 's/passwd\.5 / /'   {} \;
```

> 比起默认的 crypt 方法，用更安全的 SHA-512 方法加密密码，它允许密码长度超过 8 个字符。也需要把 Shadow 默认使用的用户邮箱由陈旧的 /var/spool/mail 位置改为正在使用的 /var/mail 位置：
```
sed -i -e 's@#ENCRYPT_METHOD DES@ENCRYPT_METHOD SHA512@' \
       -e 's@/var/spool/mail@/var/mail@' etc/login.defs
```

>> 注意
>
> 如果你选择编译支持 Cracklib 的 Shadow，运行下面的命令：
>
> `sed -i 's@DICTPATH.*@DICTPATH\t/lib/cracklib/pw_dict@' etc/login.defs`

> 用 useradd 1000 生成第一个组号：
```
sed -i 's/1000/999/' etc/useradd
```

```
./configure --sysconfdir=/etc --with-group-name-max-length=32
make
make install
```
> 移动位置错误的程序到正确的位置：
```
mv -v /usr/bin/passwd /bin
```

```
cd $LFS/sources
rm -rf shadow-4.7
```

### 6.20.2. 配置 Shadow

> 启用 shadow 密码：
```
pwconv
```

> 启用 shadow 组密码：
```
grpconv
```

### 6.20.3. 设置 root 密码

> 为用户 root 设置密码：
```
passwd root
```

### 6.20.4. Shadow 软件包内容

    安装的程序:
        chage, chfn, chgpasswd, chpasswd, chsh, expiry, faillog, gpasswd, groupadd, groupdel, groupmems, groupmod, grpck, grpconv, grpunconv, lastlog, login, logoutd, newgidmap, newgrp, newuidmap, newusers, nologin, passwd, pwck, pwconv, pwunconv, sg (链接到 newgrp), su, useradd, userdel, usermod, vigr (链接到 vipw), 和 vipw
    安装目录:
        /etc/default
    简要介绍
        chage             用来更改强制性密码更新的最大天数
        chfn              用来更改用户的全名以及其它信息
        chgpasswd         用来以批处理模式更新组密码
        chpasswd          用来以批处理模式更新用户密码
        chsh              用来更改用户登录时默认使用的 shell
        expiry            检查并强制执行当前密码过期策略
        faillog           用来检查登录失败的日志文件，设置锁定用户的最大失败次数，或者重置失败次数
        gpasswd           用来给组增加、删除成员以及管理员
        groupadd          用指定的名称创建组
        groupdel          用指定的名称删除组
        groupmems         允许用户管理他/她自己的组成员列表而不需要超级用户权限。
        groupmod          用于更改指定组的名称或 GID
        grpck             验证组文件 /etc/group 和 /etc/gshadow 的完整性
        grpconv           从普通组文件创建或升级为 shadow 组文件
        grpunconv         从 /etc/group 更新到 /etc/gshadow 然后删除前者
        lastlog           报告所有用户或指定用户的最近一次登录
        login             用于系统让用户登录进来
        logoutd           用于强制限制登录时间和端口的守护进程
        newgidmap         用于设置用户命名空间的 gid 映射
        newgrp            用于在一次登录会话中更改当前 GID
        newuidmap         用于设置用户命名空间的 uid 映射
        newusers          用于批量创建或更新用户账户
        nologin           显示一个账户不可用的信息；它用于来作为不可登录的账户的默认 shell
        passwd            用来更改用户或组账户的密码
        pwck              验证密码文件 /etc/passwd 和 /etc/shadow 的完整性
        pwconv            从普通密码文件创建或升级 shadow 密码文件
        pwunconv          从 /etc/passwd 更新到 /etc/shadow 然后删除前者
        sg                当用户的 GID 被设置为指定组的 GID 时执行一个特定命令
        su                用替换的用户和组 ID 运行 Shell
        useradd           用指定的名称新建用户或更新新用户的默认信息
        userdel           删除指定的用户账户
        usermod           用于更改指定用户的登录名称、UID、shell、初始组、home 目录，等
        vigr              编辑 /etc/group 或 /etc/gshadow 文件
        vipw              编辑 /etc/passwd 或 /etc/shadow 文件

## 6.21. GCC-9.2.0

### 6.21.1. 安装 GCC

```
cd $LFS/sources
tar xvf gcc-9.2.0.tar.xz
cd gcc-9.2.0
```

> 如果是在 x86_64 上实施构建，更改 64 位库的默认目录名为「lib」：
```
case $(uname -m) in
  x86_64)
    sed -e '/m64=/s/lib64/lib/' \
        -i.orig gcc/config/i386/t-linux64
  ;;
esac
```

> GCC 的文档建议在源代码目录之外一个专用的编译目录中编译 GCC：
```
mkdir -v build
cd       build
```

```
SED=sed                               \
../configure --prefix=/usr            \
             --enable-languages=c,c++ \
             --disable-multilib       \
             --disable-bootstrap      \
             --with-system-zlib

make
```
>> 重要
>
>本章节中 GCC 的测试套件至关重要，任何情况下都不能跳过。

```
ulimit -s 32768
chown -Rv nobody . 
su nobody -s /bin/bash -c "PATH=$PATH make -k check"
../contrib/test_summary
```

```
make install

rm -rf /usr/lib/gcc/$(gcc -dumpmachine)/9.2.0/include-fixed/bits/

chown -v -R root:root \
    /usr/lib/gcc/*linux-gnu/9.2.0/include{,-fixed}

ln -sv ../usr/bin/cpp /lib

ln -sv gcc /usr/bin/cc

install -v -dm755 /usr/lib/bfd-plugins
ln -sfv ../../libexec/gcc/$(gcc -dumpmachine)/9.2.0/liblto_plugin.so \
        /usr/lib/bfd-plugins/
```

> 最终的工具链已经准备就绪，确认编译和链接都能像预期那样正常工作。完整性检查：
```
echo 'int main(){}' > dummy.c
cc dummy.c -v -Wl,--verbose &> dummy.log
readelf -l a.out | grep ': /lib'
```
> 如果没有任何错误，上条命令的输出应该是（不同的平台上的动态链接器可能名字不同）：
>
> `[Requesting program interpreter: /lib64/ld-linux-x86-64.so.2]`

> 确保我们已经设置好了启动文件：
```
grep -o '/usr/lib.*/crt[1in].*succeeded' dummy.log
```
> 上一条命令的输出应该是：
> ```
> /usr/lib/gcc/x86_64-pc-linux-gnu/9.2.0/../../../../lib/crt1.o succeeded
> /usr/lib/gcc/x86_64-pc-linux-gnu/9.2.0/../../../../lib/crti.o succeeded
> /usr/lib/gcc/x86_64-pc-linux-gnu/9.2.0/../../../../lib/crtn.o succeeded
> ```

> 确保链接器能找到正确的头文件：
```
grep -B4 '^ /usr/include' dummy.log
```

> 这条命令应该返回如下输出：
> ```
> #include <...> search starts here:
>  /usr/lib/gcc/x86_64-pc-linux-gnu/9.2.0/include
>  /usr/local/include
>  /usr/lib/gcc/x86_64-pc-linux-gnu/9.2.0/include-fixed
>  /usr/include
> ```

> 确认新的链接器已经在使用正确的搜索路径：
```
grep 'SEARCH.*/usr/lib' dummy.log |sed 's|; |\n|g'
```

> 应该忽略指向带有 '-linux-gnu' 的路径，上条命令的输出应该是：
```
SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib64")
SEARCH_DIR("/usr/local/lib64")
SEARCH_DIR("/lib64")
SEARCH_DIR("/usr/lib64")
SEARCH_DIR("/usr/x86_64-pc-linux-gnu/lib")
SEARCH_DIR("/usr/local/lib")
SEARCH_DIR("/lib")
SEARCH_DIR("/usr/lib");
```

> 确定我们使用的是正确的 libc：
```
grep "/lib.*/libc.so.6 " dummy.log
```
> 上条命令的输出应该为：
> 
> `attempt to open /lib/libc.so.6 succeeded`
> 

> 确保 GCC 使用的是正确的动态链接器：
```
grep found dummy.log
```
> 上条命令的结果应该是（不同的平台上链接器名字可以不同）：
>
> `found ld-linux-x86-64.so.2 at /lib/ld-linux-x86-64.so.2`

> 如果显示的结果不一样或者根本没有显示，那就出了大问题。检查并回溯之前的步骤，找到出错的地方并改正。最有可能的原因是参数文件的调整出了问题。在进行下一步之前所有的问题都要解决。


> 确保一切正常之后，清除测试文件：
```
rm -v dummy.c a.out dummy.log
```

> 最后，移动位置放错的文件：
```
mkdir -pv /usr/share/gdb/auto-load/usr/lib
mv -v /usr/lib/*gdb.py /usr/share/gdb/auto-load/usr/lib
```

```
cd $LFS/sources
rm -rf gcc-9.2.0
```

## 6.22. Bzip2-1.0.8

### 6.22.1. 安装 Bzip2

```
cd $LFS/sources
tar xvf bzip2-1.0.8.tar.gz
cd bzip2-1.0.8
```

```
patch -Np1 -i ../bzip2-1.0.8-install_docs-1.patch
sed -i 's@\(ln -s -f \)$(PREFIX)/bin/@\1@' Makefile
sed -i "s@(PREFIX)/man@(PREFIX)/share/man@g" Makefile
```

```
make -f Makefile-libbz2_so
make clean
make && make PREFIX=/usr install

cp -v bzip2-shared /bin/bzip2
cp -av libbz2.so* /lib
ln -sv ../../lib/libbz2.so.1.0 /usr/lib/libbz2.so
rm -v /usr/bin/{bunzip2,bzcat,bzip2}
ln -sv bzip2 /bin/bunzip2
ln -sv bzip2 /bin/bzcat
```

```
cd $LFS/sources
rm -rf bzip2-1.0.8
```

## 6.23. Pkg-config-0.29.2

### 6.23.1. 安装 Pkg-config

```
cd $LFS/sources
tar xvf pkg-config-0.29.2.tar.gz
cd pkg-config-0.29.2
```

```
./configure --prefix=/usr              \
            --with-internal-glib       \
            --disable-host-tool        \
            --docdir=/usr/share/doc/pkg-config-0.29.2

make && make check && make install
```

```
cd $LFS/sources
rm -rf pkg-config-0.29.2
```


## 6.24. Ncurses-6.1

### 6.24.1. 安装 Ncurses

```
cd $LFS/sources
tar xvf ncurses-6.1.tar.gz
cd ncurses-6.1
```

> 不要安装静态库，它不受配置控制：
```
sed -i '/LIBTOOL_INSTALL/d' c++/Makefile.in
```

```
./configure --prefix=/usr           \
            --mandir=/usr/share/man \
            --with-shared           \
            --without-debug         \
            --without-normal        \
            --enable-pc-files       \
            --enable-widec

make && make install
```

> 移动共享库到期望的 /lib 文件夹，重建符号链接：
```
mv -v /usr/lib/libncursesw.so.6* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libncursesw.so) /usr/lib/libncursesw.so
```

> 很多应用程序仍然希望编辑器能找到非宽字符的 Ncurses 库。通过符号链接和链接器脚本欺骗这样的应用链接到宽字符库：
```
for lib in ncurses form panel menu ; do
    rm -vf                    /usr/lib/lib${lib}.so
    echo "INPUT(-l${lib}w)" > /usr/lib/lib${lib}.so
    ln -sfv ${lib}w.pc        /usr/lib/pkgconfig/${lib}.pc
done
```

> 确保在编译时会查找 -lcurses 的旧应用程序仍然可以编译：
```
rm -vf                     /usr/lib/libcursesw.so
echo "INPUT(-lncursesw)" > /usr/lib/libcursesw.so
ln -sfv libncurses.so      /usr/lib/libcurses.so
```

> 如果需要的话，安装 Ncurses 的帮助文档：
```
mkdir -v       /usr/share/doc/ncurses-6.1
cp -v -R doc/* /usr/share/doc/ncurses-6.1
```

```
cd $LFS/sources
rm -rf ncurses-6.1
```

## 6.25. Attr-2.4.48

### 6.25.1. 安装 Attr

```
cd $LFS/sources
tar xvf attr-2.4.48.tar.gz
cd attr-2.4.48
```

```
./configure --prefix=/usr     \
            --bindir=/bin     \
            --disable-static  \
            --sysconfdir=/etc \
            --docdir=/usr/share/doc/attr-2.4.48

make && make check && make install
```

> 需要移动共享库到 /lib，因此需要重建 .so 中的 /usr/lib 文件：
```
mv -v /usr/lib/libattr.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libattr.so) /usr/lib/libattr.so
```

```
cd $LFS/sources
rm -rf attr-2.4.48
```

## 6.26. Acl-2.2.53

### 6.26.1. 安装 Acl

```
cd $LFS/sources
tar xvf acl-2.2.53.tar.gz
cd acl-2.2.53
```

```
./configure --prefix=/usr         \
            --bindir=/bin         \
            --disable-static      \
            --libexecdir=/usr/lib \
            --docdir=/usr/share/doc/acl-2.2.53

make && make install
```

> 需要移动共享库到 /lib，因此需要重建 /usr/lib 中的 .so 文件：
```
mv -v /usr/lib/libacl.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libacl.so) /usr/lib/libacl.so
```

```
cd $LFS/sources
rm -rf acl-2.2.53
```

## 6.27. Libcap-2.27

### 6.27.1. 安装 Libcap

```
cd $LFS/sources
tar xvf libcap-2.27.tar.xz
cd libcap-2.27
```

> 避免安装静态库：
```
sed -i '/install.*STALIBNAME/d' libcap/Makefile
```

```
make && make RAISE_SETFCAP=no lib=lib prefix=/usr install

chmod -v 755 /usr/lib/libcap.so.2.27
```

> 需要移动共享库到 /lib，因此需要重建 /usr/lib 中的 .so 文件：
```
mv -v /usr/lib/libcap.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libcap.so) /usr/lib/libcap.so
```

```
cd $LFS/sources
rm -rf libcap-2.27
```

## 6.28. Sed-4.7

### 6.28.1. 安装 Sed

```
cd $LFS/sources
tar xvf sed-4.7.tar.xz
cd sed-4.7
```

> 首先修复 LFS 环境中的问题，然后移除一个失败的测试：
```
sed -i 's/usr/tools/'                 build-aux/help2man
sed -i 's/testsuite.panic-tests.sh//' Makefile.in
```

```
./configure --prefix=/usr --bindir=/bin

make && make html && make check && make install

install -d -m755           /usr/share/doc/sed-4.7
install -m644 doc/sed.html /usr/share/doc/sed-4.7
```

```
cd $LFS/sources
rm -rf sed-4.7
```

## 6.29. Psmisc-23.2

### 6.29.1. 安装 Psmisc

```
cd $LFS/sources
tar xvf psmisc-23.2.tar.xz
cd psmisc-23.2
```

```
./configure --prefix=/usr

make && make install
mv -v /usr/bin/fuser   /bin
mv -v /usr/bin/killall /bin
```

```
cd $LFS/sources
rm -rf psmisc-23.2
```

## 6.30. Iana-Etc-2.30

### 6.30.1. 安装 Iana-Etc

```
cd $LFS/sources
tar xvf iana-etc-2.30.tar.bz2
cd iana-etc-2.30
```

```
make && make install
```

```
cd $LFS/sources
rm -rf iana-etc-2.30
```

## 6.31. Bison-3.4.1

### 6.31.1. 安装 Bison

```
cd $LFS/sources
tar xvf bison-3.4.1.tar.xz
cd bison-3.4.1
```

```
sed -i '6855 s/mv/cp/' Makefile.in

./configure --prefix=/usr --docdir=/usr/share/doc/bison-3.4.1

make -j1 && make install
```

```
cd $LFS/sources
rm -rf bison-3.4.1
```

## 6.32. Flex-2.6.4

### 6.32.1. 安装 Flex

```
cd $LFS/sources
tar xvf flex-2.6.4.tar.gz
cd flex-2.6.4
```

```
sed -i "/math.h/a #include <malloc.h>" src/flexdef.h

HELP2MAN=/tools/bin/true \
./configure --prefix=/usr --docdir=/usr/share/doc/flex-2.6.4

make && make check && make install

ln -sv flex /usr/bin/lex
```

```
cd $LFS/sources
rm -rf flex-2.6.4
```

## 6.33. Grep-3.3

### 6.33.1. 安装 Grep

```
cd $LFS/sources
tar xvf grep-3.3.tar.xz
cd grep-3.3
```

```
./configure --prefix=/usr --bindir=/bin

make && make -k check && make install
```

```
cd $LFS/sources
rm -rf grep-3.3
```

## 6.34. Bash-5.0

### 6.34.1. 安装 Bash

```
cd $LFS/sources
tar xvf bash-5.0.tar.gz
cd bash-5.0
```

```
./configure --prefix=/usr                    \
            --docdir=/usr/share/doc/bash-5.0 \
            --without-bash-malloc            \
            --with-installed-readline

make
chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH HOME=/home make tests"
make install
mv -vf /usr/bin/bash /bin
exec /bin/bash --login +h
```

```
cd $LFS/sources
rm -rf bash-5.0
```

## 6.35. Libtool-2.4.6

### 6.35.1. 安装 Libtool

```
cd $LFS/sources
tar xvf libtool-2.4.6.tar.xz
cd libtool-2.4.6
```

```
./configure --prefix=/usr

make
make check
make install
```

```
cd $LFS/sources
rm -rf libtool-2.4.6
```

## 6.36. GDBM-1.18.1

### 6.36.1. 安装 GDBM

```
cd $LFS/sources
tar xvf gdbm-1.18.1.tar.gz
cd gdbm-1.18.1
```

```
./configure --prefix=/usr    \
            --disable-static \
            --enable-libgdbm-compat

make && make check && make install
```

```
cd $LFS/sources
rm -rf gdbm-1.18.1
```

## 6.37. Gperf-3.1

### 6.37.1. 安装 Gperf

```
cd $LFS/sources
tar xvf gperf-3.1.tar.gz
cd gperf-3.1
```

```
./configure --prefix=/usr --docdir=/usr/share/doc/gperf-3.1

make && make -j1 check && make install
```

```
cd $LFS/sources
rm -rf gperf-3.1
```

## 6.38. Expat-2.2.7

### 6.38.1. 安装 Expat

```
cd $LFS/sources
tar xvf expat-2.2.7.tar.xz
cd expat-2.2.7
```

```
sed -i 's|usr/bin/env |bin/|' run.sh.in

./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/expat-2.2.7

make && make check && make install

install -v -m644 doc/*.{html,png,css} /usr/share/doc/expat-2.2.7
```

```
cd $LFS/sources
rm -rf expat-2.2.7
```

## 6.39. Inetutils-1.9.4

### 6.39.1. 安装 Inetutils

```
cd $LFS/sources
tar xvf inetutils-1.9.4.tar.xz
cd inetutils-1.9.4
```

```
./configure --prefix=/usr        \
            --localstatedir=/var \
            --disable-logger     \
            --disable-whois      \
            --disable-rcp        \
            --disable-rexec      \
            --disable-rlogin     \
            --disable-rsh        \
            --disable-servers

make && make check && make install

mv -v /usr/bin/{hostname,ping,ping6,traceroute} /bin
mv -v /usr/bin/ifconfig /sbin
```

```
cd $LFS/sources
rm -rf inetutils-1.9.4
```

## 6.40. Perl-5.30.0

### 6.40.1. 安装 Perl

```
cd $LFS/sources
tar xvf perl-5.30.0.tar.xz
cd perl-5.30.0
```

```
echo "127.0.0.1 localhost $(hostname)" > /etc/hosts

export BUILD_ZLIB=False
export BUILD_BZIP2=0

sh Configure -des -Dprefix=/usr                 \
                  -Dvendorprefix=/usr           \
                  -Dman1dir=/usr/share/man/man1 \
                  -Dman3dir=/usr/share/man/man3 \
                  -Dpager="/usr/bin/less -isR"  \
                  -Duseshrplib                  \
                  -Dusethreads

make && make -k test && make install
unset BUILD_ZLIB BUILD_BZIP2
```

```
cd $LFS/sources
rm -rf perl-5.30.0
```

## 6.41. XML::Parser-2.44

### 6.41.1. 安装 XML::Parser

```
cd $LFS/sources
tar xvf XML-Parser-2.44.tar.gz
cd XML-Parser-2.44
```

```
perl Makefile.PL

make && make test && make install
```

```
cd $LFS/sources
rm -rf XML-Parser-2.44
```

## 6.42. Intltool-0.51.0

### 6.42.1. 安装 Intltool

```
cd $LFS/sources
tar xvf intltool-0.51.0.tar.gz
cd intltool-0.51.0
```

```
sed -i 's:\\\${:\\\$\\{:' intltool-update.in

./configure --prefix=/usr

make && make test && make install
install -v -Dm644 doc/I18N-HOWTO /usr/share/doc/intltool-0.51.0/I18N-HOWTO
```

```
cd $LFS/sources
rm -rf intltool-0.51.0
```

## 6.43. Autoconf-2.69

### 6.43.1. 安装 Autoconf

```
cd $LFS/sources
tar xvf autoconf-2.69.tar.xz
cd autoconf-2.69
```

```
sed '361 s/{/\\{/' -i bin/autoscan.in

./configure --prefix=/usr

make && make install
```

```
cd $LFS/sources
rm -rf autoconf-2.69
```

## 6.44. Automake-1.16.1

### 6.44.1. Automake 的安装

```
cd $LFS/sources
tar xvf automake-1.16.1.tar.xz
cd automake-1.16.1
```

```
./configure --prefix=/usr --docdir=/usr/share/doc/automake-1.16.1

make && make -j4 check && make install
```

```
cd $LFS/sources
rm -rf automake-1.16.1
```

## 6.45. Xz-5.2.4

### 6.45.1. 安装 Xz

```
cd $LFS/sources
tar xvf xz-5.2.4.tar.xz
cd xz-5.2.4
```

```
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/xz-5.2.4

make && make check && make install
mv -v   /usr/bin/{lzma,unlzma,lzcat,xz,unxz,xzcat} /bin
mv -v /usr/lib/liblzma.so.* /lib
ln -svf ../../lib/$(readlink /usr/lib/liblzma.so) /usr/lib/liblzma.so
```

```
cd $LFS/sources
rm -rf xz-5.2.4
```

## 6.46. Kmod-26

### 6.46.1. 安装 Kmod

```
cd $LFS/sources
tar xvf kmod-26.tar.xz
cd kmod-26
```

```
./configure --prefix=/usr          \
            --bindir=/bin          \
            --sysconfdir=/etc      \
            --with-rootlibdir=/lib \
            --with-xz              \
            --with-zlib

make && make install

for target in depmod insmod lsmod modinfo modprobe rmmod; do
  ln -sfv ../bin/kmod /sbin/$target
done

ln -sfv kmod /bin/lsmod
```

```
cd $LFS/sources
rm -rf kmod-26
```

## 6.47. Gettext-0.20.1

### 6.47.1. 安装 Gettext

```
cd $LFS/sources
tar xvf gettext-0.20.1.tar.xz
cd gettext-0.20.1
```

```
./configure --prefix=/usr    \
            --disable-static \
            --docdir=/usr/share/doc/gettext-0.20.1

make && make check && make install
chmod -v 0755 /usr/lib/preloadable_libintl.so
```

```
cd $LFS/sources
rm -rf gettext-0.20.1
```

## 6.48. Libelf 源自 Elfutils-0.177

### 6.48.1. 安装 Libelf

```
cd $LFS/sources
tar xvf elfutils-0.177.tar.bz2
cd elfutils-0.177
```

```
./configure --prefix=/usr

make
make check
make -C libelf install
install -vm644 config/libelf.pc /usr/lib/pkgconfig
```

```
cd $LFS/sources
rm -rf elfutils-0.177
```

## 6.49. Libffi-3.2.1

### 6.49.1. 安装 Libffi

```
cd $LFS/sources
tar xvf libffi-3.2.1.tar.gz
cd libffi-3.2.1
```

```
sed -e '/^includesdir/ s/$(libdir).*$/$(includedir)/' \
    -i include/Makefile.in

sed -e '/^includedir/ s/=.*$/=@includedir@/' \
    -e 's/^Cflags: -I${includedir}/Cflags:/' \
    -i libffi.pc.in

./configure --prefix=/usr --disable-static --with-gcc-arch=native

make && make check && make install
```

```
cd $LFS/sources
rm -rf libffi-3.2.1
```

## 6.50. OpenSSL-1.1.1c

### 6.50.1. 安装 OpenSSL

```
cd $LFS/sources
tar xvf openssl-1.1.1c.tar.gz
cd openssl-1.1.1c
```

```
sed -i '/\} data/s/ =.*$/;\n    memset(\&data, 0, sizeof(data));/' \
  crypto/rand/rand_lib.c

./config --prefix=/usr         \
         --openssldir=/etc/ssl \
         --libdir=lib          \
         shared                \
         zlib-dynamic

make && make test
sed -i '/INSTALL_LIBS/s/libcrypto.a libssl.a//' Makefile
make MANSUFFIX=ssl install
mv -v /usr/share/doc/openssl /usr/share/doc/openssl-1.1.1c
cp -vfr doc/* /usr/share/doc/openssl-1.1.1c
```

```
cd $LFS/sources
rm -rf openssl-1.1.1c
```

## 6.51. Python-3.7.4

### 6.51.1. 安装 Python 3

```
cd $LFS/sources
tar xvf Python-3.7.4.tar.xz
cd Python-3.7.4
```

```
./configure --prefix=/usr       \
            --enable-shared     \
            --with-system-expat \
            --with-system-ffi   \
            --with-ensurepip=yes

make && make install
chmod -v 755 /usr/lib/libpython3.7m.so
chmod -v 755 /usr/lib/libpython3.so
ln -sfv pip3.7 /usr/bin/pip3
```

> 如果需要，安装预格式化好的文档：
```
install -v -dm755 /usr/share/doc/python-3.7.4/html 

tar --strip-components=1  \
    --no-same-owner       \
    --no-same-permissions \
    -C /usr/share/doc/python-3.7.4/html \
    -xvf ../python-3.7.4-docs-html.tar.bz2
```

```
cd $LFS/sources
rm -rf Python-3.7.4
```

## 6.52. Ninja-1.9.0

### 6.52.1. 安装 Ninja

```
cd $LFS/sources
tar xvf ninja-1.9.0.tar.gz
cd ninja-1.9.0
```

```
export NINJAJOBS=4

sed -i '/int Guess/a \
  int   j = 0;\
  char* jobs = getenv( "NINJAJOBS" );\
  if ( jobs != NULL ) j = atoi( jobs );\
  if ( j > 0 ) return j;\
' src/ninja.cc
```

```
python3 configure.py --bootstrap

./ninja ninja_test
./ninja_test --gtest_filter=-SubprocessTest.SetWithLots

install -vm755 ninja /usr/bin/
install -vDm644 misc/bash-completion /usr/share/bash-completion/completions/ninja
install -vDm644 misc/zsh-completion  /usr/share/zsh/site-functions/_ninja
```

```
cd $LFS/sources
rm -rf ninja-1.9.0
```

## 6.53. Meson-0.51.1

### 6.53.1. 安装 Meson

```
cd $LFS/sources
tar xvf meson-0.51.1.tar.gz
cd meson-0.51.1
```

```
python3 setup.py build

python3 setup.py install --root=dest
cp -rv dest/* /
```

```
cd $LFS/sources
rm -rf meson-0.51.1
```

## 6.54. Coreutils-8.31

### 6.54.1. 安装 Coreutils

```
cd $LFS/sources
tar xvf coreutils-8.31.tar.xz
cd coreutils-8.31
```

```
patch -Np1 -i ../coreutils-8.31-i18n-1.patch

sed -i '/test.lock/s/^/#/' gnulib-tests/gnulib.mk

autoreconf -fiv
FORCE_UNSAFE_CONFIGURE=1 ./configure \
            --prefix=/usr            \
            --enable-no-install-program=kill,uptime


make
make NON_ROOT_USERNAME=nobody check-root
echo "dummy:x:1000:nobody" >> /etc/group
chown -Rv nobody . 

su nobody -s /bin/bash \
          -c "PATH=$PATH make RUN_EXPENSIVE_TESTS=yes check"

sed -i '/dummy/d' /etc/group
make install
mv -v /usr/bin/{cat,chgrp,chmod,chown,cp,date,dd,df,echo} /bin
mv -v /usr/bin/{false,ln,ls,mkdir,mknod,mv,pwd,rm} /bin
mv -v /usr/bin/{rmdir,stty,sync,true,uname} /bin
mv -v /usr/bin/chroot /usr/sbin
mv -v /usr/share/man/man1/chroot.1 /usr/share/man/man8/chroot.8
sed -i s/\"1\"/\"8\"/1 /usr/share/man/man8/chroot.8

mv -v /usr/bin/{head,nice,sleep,touch} /bin
```

```
cd $LFS/sources
rm -rf coreutils-8.31
```

## 6.55. Check-0.12.0

### 6.55.1. 安装 Check

```
cd $LFS/sources
tar xvf check-0.12.0.tar.gz
cd check-0.12.0
```

```
./configure --prefix=/usr

make && make check
make docdir=/usr/share/doc/check-0.12.0 install
sed -i '1 s/tools/usr/' /usr/bin/checkmk
```

```
cd $LFS/sources
rm -rf check-0.12.0
```

## 6.56. Diffutils-3.7

### 6.56.1. 安装 Diffutils

```
cd $LFS/sources
tar xvf diffutils-3.7.tar.xz
cd diffutils-3.7
```

```
./configure --prefix=/usr

make && make check && make install
```

```
cd $LFS/sources
rm -rf diffutils-3.7
```

## 6.57. Gawk-5.0.1

### 

```
cd $LFS/sources
tar xvf gawk-5.0.1.tar.xz
cd gawk-5.0.1
```

```
sed -i 's/extras//' Makefile.in
./configure --prefix=/usr
make && make check && make install
```

> 如果需要的话，安装帮助文档：
```
mkdir -v /usr/share/doc/gawk-5.0.1
cp    -v doc/{awkforai.txt,*.{eps,pdf,jpg}} /usr/share/doc/gawk-5.0.1
```

```
cd $LFS/sources
rm -rf gawk-5.0.1
```

## 6.58. Findutils-4.6.0

### 6.58.1. 安装 Findutils

```
cd $LFS/sources
tar xvf findutils-4.6.0.tar.gz
cd findutils-4.6.0
```

```
sed -i 's/test-lock..EXEEXT.//' tests/Makefile.in

sed -i 's/IO_ftrylockfile/IO_EOF_SEEN/' gl/lib/*.c
sed -i '/unistd/a #include <sys/sysmacros.h>' gl/lib/mountlist.c
echo "#define _IO_IN_BACKUP 0x100" >> gl/lib/stdio-impl.h

./configure --prefix=/usr --localstatedir=/var/lib/locate

make && make check && make install

mv -v /usr/bin/find /bin
sed -i 's|find:=${BINDIR}|find:=/bin|' /usr/bin/updatedb
```

```
cd $LFS/sources
rm -rf findutils-4.6.0
```

## 6.59. Groff-1.22.4

### 6.59.1. 安装 Groff

```
cd $LFS/sources
tar xvf groff-1.22.4.tar.gz
cd groff-1.22.4
```

```
PAGE=A4 ./configure --prefix=/usr

make -j1 && make install
```

```
cd $LFS/sources
rm -rf groff-1.22.4
```

## 6.60. GRUB-2.04

### 6.60.1. 安装 GRUB

```
cd $LFS/sources
tar xvf grub-2.04.tar.xz
cd grub-2.04
```

```
./configure --prefix=/usr          \
            --sbindir=/sbin        \
            --sysconfdir=/etc      \
            --disable-efiemu       \
            --disable-werror

make && make install
mv -v /etc/bash_completion.d/grub /usr/share/bash-completion/completions
```

```
cd $LFS/sources
rm -rf grub-2.04
```

## 6.61. Less-551

### 6.61.1. 安装 Less

```
cd $LFS/sources
tar xvf less-551.tar.gz
cd less-551
```

```
./configure --prefix=/usr --sysconfdir=/etc

make && make install
```

```
cd $LFS/sources
rm -rf less-551
```

## 6.62. Gzip-1.10

### 6.62.1. 安装 Gzip

```
cd $LFS/sources
tar xvf gzip-1.10.tar.xz
cd gzip-1.10
```

```
./configure --prefix=/usr
make && make check
```
> 已知有两个测试在 LFS 环境中会失败：help-version 和 zmore。

```
make install
mv -v /usr/bin/gzip /bin
```

```
cd $LFS/sources
rm -rf gzip-1.10
```

## 6.63. IPRoute2-5.2.0

### 6.63.1. 安装 IPRoute2

```
cd $LFS/sources
tar xvf iproute2-5.2.0.tar.xz
cd iproute2-5.2.0
```

```
sed -i /ARPD/d Makefile
rm -fv man/man8/arpd.8

sed -i 's/.m_ipt.o//' tc/Makefile

make && make DOCDIR=/usr/share/doc/iproute2-5.2.0 install
```

```
cd $LFS/sources
rm -rf iproute2-5.2.0
```

## 6.64. Kbd-2.2.0

### 6.64.1. 安装 Kbd

```
cd $LFS/sources
tar xvf kbd-2.2.0.tar.xz
cd kbd-2.2.0
```

```
patch -Np1 -i ../kbd-2.2.0-backspace-1.patch

sed -i 's/\(RESIZECONS_PROGS=\)yes/\1no/g' configure
sed -i 's/resizecons.8 //' docs/man/man8/Makefile.in

PKG_CONFIG_PATH=/tools/lib/pkgconfig ./configure --prefix=/usr --disable-vlock

make && make check && make install
```

> 如果需要的话，安装帮助文档：
```
mkdir -v       /usr/share/doc/kbd-2.2.0
cp -R -v docs/doc/* /usr/share/doc/kbd-2.2.0
```

```
cd $LFS/sources
rm -rf kbd-2.2.0
```

## 6.65. Libpipeline-1.5.1

### 6.65.1. 安装 Libpipeline

```
cd $LFS/sources
tar xvf libpipeline-1.5.1.tar.gz
cd libpipeline-1.5.1
```

```
./configure --prefix=/usr
make && make check && make install
```

```
cd $LFS/sources
rm -rf libpipeline-1.5.1
```

## 6.66. Make-4.2.1

### 6.66.1. 安装 Make

```
cd $LFS/sources
tar xvf make-4.2.1.tar.gz
cd make-4.2.1
```

```
sed -i '211,217 d; 219,229 d; 232 d' glob/glob.c

./configure --prefix=/usr

make && make PERL5LIB=$PWD/tests/ check && make install
```

```
cd $LFS/sources
rm -rf make-4.2.1
```

## 6.67. Patch-2.7.6

### 6.67.1. 安装 Patch

```
cd $LFS/sources
tar xvf patch-2.7.6.tar.xz
cd patch-2.7.6
```

```
./configure --prefix=/usr

make && make check && make install
```

```
cd $LFS/sources
rm -rf patch-2.7.6
```

## 6.68. Man-DB-2.8.6.1

### 6.68.1. 安装 Man-DB

```
cd $LFS/sources
tar xvf man-db-2.8.6.1.tar.xz
cd man-db-2.8.6.1
```

```
./configure --prefix=/usr                        \
            --docdir=/usr/share/doc/man-db-2.8.6.1 \
            --sysconfdir=/etc                    \
            --disable-setuid                     \
            --enable-cache-owner=bin             \
            --with-browser=/usr/bin/lynx         \
            --with-vgrind=/usr/bin/vgrind        \
            --with-grap=/usr/bin/grap            \
            --with-systemdtmpfilesdir=           \
            --with-systemdsystemunitdir=

make && make check && make install
```

```
cd $LFS/sources
rm -rf man-db-2.8.6.1
```

## 6.69. Tar-1.32

### 6.69.1. 安装 Tar

```
cd $LFS/sources
tar xvf tar-1.32.tar.xz
cd tar-1.32
```

```
FORCE_UNSAFE_CONFIGURE=1  \
./configure --prefix=/usr \
            --bindir=/bin

make && make check && make install
make -C doc install-html docdir=/usr/share/doc/tar-1.32
```

```
cd $LFS/sources
rm -rf tar-1.32
```

## 6.70. Texinfo-6.6

### 6.70.1. 安装 Texinfo

```
cd $LFS/sources
tar xvf texinfo-6.6.tar.xz
cd texinfo-6.6
```

```
./configure --prefix=/usr --disable-static

make && make check && make install
make TEXMF=/usr/share/texmf install-tex
```

> 重建 /usr/share/info/dir 文件:
```
pushd /usr/share/info
rm -v dir
for f in *
  do install-info $f dir 2>/dev/null
done
popd
```

```
cd $LFS/sources
rm -rf texinfo-6.6
```

## 6.71. Vim-8.1.1846

### 6.71.1. Vim 的安装

```
cd $LFS/sources
tar xvf vim-8.1.1846.tar.gz
cd vim-8.1.1846
```

> 首先，把配置文件 vimrc 从默认位置移动到 /etc：
```
echo '#define SYS_VIMRC_FILE "/etc/vimrc"' >> src/feature.h
```

```
./configure --prefix=/usr

make
```

> 为测试做准备，确保 nobody 用户拥有源码目录的写权限：
```
chown -Rv nobody .
```

> 现在用用户 nobody 执行测试：
```
su nobody -s /bin/bash -c "LANG=en_US.UTF-8 make -j1 test" &> vim-test.log
```
> 这个测试套件会输出一堆二进制数据到屏幕上。这会导致当前设置下的终端出现问题。把输出重定向到一个日志文件就可以解决这个问题。测试成功的话就会输出「ALL DONE」。

```
make install
```

> 许多用户习惯于使用 vi 而不是 vim。为了当人们在习惯性的输入 vi 时能执行 vim，需要给二进制文件和 man 页建立符号连接：
```
ln -sv vim /usr/bin/vi
for L in  /usr/share/man/{,*/}man1/vim.1; do
    ln -sv vim.1 $(dirname $L)/vi.1
done
```

> 默认情况下，Vim 的说明文档被安装在 /usr/share/vim 里。下面的这个符号链接使得可以通过 /usr/share/doc/vim-8.1.1846 访问该文档，让它的位置与其它软件包的文档位置保持一致：
```
ln -sv ../vim/vim81/doc /usr/share/doc/vim-8.1.1846
```

> 如果要把一个 X Window 系统安装在 LFS 系统上，可能得在安装完 X 系统后再重新编译 Vim。Vim 带有一个 GUI 版本，这个版本需要安装 X 和一些额外的库。想了解更多信息，请参考 Vim 文档和 BLFS http://www.linuxfromscratch.org/blfs/view/9.0/postlfs/vim.html 中 Vim 安装指导页。

### 6.71.2. 设置 Vim

> 创建一个默认的 vim 配置文件：
```
cat > /etc/vimrc << "EOF"
" Begin /etc/vimrc

" Ensure defaults are set before customizing settings, not after
source $VIMRUNTIME/defaults.vim
let skip_defaults_vim=1 

set nocompatible
set backspace=2
set mouse=
syntax on
if (&term == "xterm") || (&term == "putty")
  set background=dark
endif

" End /etc/vimrc
EOF
```
> 设置 set nocompatible 让 vim 比 vi 兼容模式更有用。删掉「no」以保留旧的 vi 特性。设置 set backspace=2 让退格跨越换行、自动缩进和插入的开始。syntax on 参数使 vim 能高亮显示语法。设置 set mouse 让你能在 chroot 和远程连接的时候用鼠标粘帖文本。最后，带有 set background=dark 的 if 语句矫正了 vim 对于某些终端模拟器的背景颜色的估算。这让某些写在黑色背景上的程序的高亮色能有更好的调色方案。

> 用下面的命令可以获得其它选项的文档：
> ```
> vim -c ':options'
> ```

```
cd $LFS/sources
rm -rf vim-8.1.1846
```

## 6.72. Procps-ng-3.3.15

### 6.72.1. 安装 Procps-ng

```
cd $LFS/sources
tar xvf procps-ng-3.3.15.tar.xz
cd procps-ng-3.3.15
```

```
./configure --prefix=/usr                            \
            --exec-prefix=                           \
            --libdir=/usr/lib                        \
            --docdir=/usr/share/doc/procps-ng-3.3.15 \
            --disable-static                         \
            --disable-kill

make

sed -i -r 's|(pmap_initname)\\\$|\1|' testsuite/pmap.test/pmap.exp
sed -i '/set tty/d' testsuite/pkill.test/pkill.exp
rm testsuite/pgrep.test/pgrep.exp
make check

make install
mv -v /usr/lib/libprocps.so.* /lib
ln -sfv ../../lib/$(readlink /usr/lib/libprocps.so) /usr/lib/libprocps.so
```

```
cd $LFS/sources
rm -rf procps-ng-3.3.15
```

## 6.73. Util-linux-2.34

### 6.73.1. FHS 兼容性注意事项

```
cd $LFS/sources
tar xvf util-linux-2.34.tar.xz
cd util-linux-2.34
```

```
mkdir -pv /var/lib/hwclock

./configure ADJTIME_PATH=/var/lib/hwclock/adjtime   \
            --docdir=/usr/share/doc/util-linux-2.34 \
            --disable-chfn-chsh  \
            --disable-login      \
            --disable-nologin    \
            --disable-su         \
            --disable-setpriv    \
            --disable-runuser    \
            --disable-pylibmount \
            --disable-static     \
            --without-python     \
            --without-systemd    \
            --without-systemdsystemunitdir

make

chown -Rv nobody .
su nobody -s /bin/bash -c "PATH=$PATH make -k check"

make install
```

```
cd $LFS/sources
rm -rf util-linux-2.34
```

## 6.74. E2fsprogs-1.45.3

### 6.74.1. 安装 E2fsprogs

```
cd $LFS/sources
tar xvf e2fsprogs-1.45.3.tar.gz
cd e2fsprogs-1.45.3
```

```
mkdir -v build
cd       build

../configure --prefix=/usr           \
             --bindir=/bin           \
             --with-root-prefix=""   \
             --enable-elf-shlibs     \
             --disable-libblkid      \
             --disable-libuuid       \
             --disable-uuidd         \
             --disable-fsck

make && make check && make install-libs

chmod -v u+w /usr/lib/{libcom_err,libe2p,libext2fs,libss}.a

gunzip -v /usr/share/info/libext2fs.info.gz
install-info --dir-file=/usr/share/info/dir /usr/share/info/libext2fs.info

makeinfo -o      doc/com_err.info ../lib/et/com_err.texinfo
install -v -m644 doc/com_err.info /usr/share/info
install-info --dir-file=/usr/share/info/dir /usr/share/info/com_err.info
```

```
cd $LFS/sources
rm -rf e2fsprogs-1.45.3
```

## 6.75. Sysklogd-1.5.1

### 6.75.1. 安装 Sysklogd

```
cd $LFS/sources
tar xvf sysklogd-1.5.1.tar.gz
cd sysklogd-1.5.1
```

```
sed -i '/Error loading kernel symbols/{n;n;d}' ksym_mod.c
sed -i 's/union wait/int/' syslogd.c

make && make BINDIR=/sbin install
```

```
cd $LFS/sources
rm -rf sysklogd-1.5.1
```

## 6.76. Sysvinit-2.95

### 6.76.1. 安装 Sysvinit

```
cd $LFS/sources
tar xvf sysvinit-2.95.tar.xz
cd sysvinit-2.95
```

```
patch -Np1 -i ../sysvinit-2.95-consolidated-1.patch

make && make install
```

```
cd $LFS/sources
rm -rf sysvinit-2.95
```

## 6.77. Eudev-3.2.8

### 6.77.1. 安装 Eudev

```
cd $LFS/sources
tar xvf eudev-3.2.8.tar.gz
cd eudev-3.2.8
```

```
./configure --prefix=/usr           \
            --bindir=/sbin          \
            --sbindir=/sbin         \
            --libdir=/usr/lib       \
            --sysconfdir=/etc       \
            --libexecdir=/lib       \
            --with-rootprefix=      \
            --with-rootlibdir=/lib  \
            --enable-manpages       \
            --disable-static

make

mkdir -pv /lib/udev/rules.d
mkdir -pv /etc/udev/rules.d

make check
make install

tar -xvf ../udev-lfs-20171102.tar.xz
make -f udev-lfs-20171102/Makefile.lfs install
```

```
cd $LFS/sources
rm -rf eudev-3.2.8
```
### 6.77.2. 配置 Eudev

```
udevadm hwdb --update
```

## 6.78. 关于调试符号

> 默认情况下大多数程序和库的编译带有调试符号。（类似 gcc 的 -g 选项。）这意味着当你调试一个包含调试信息的已编译的程序或库时，调试程序不仅能提供内存地址，还能提供变量和实例的名字。
> 因为大多数用户从来不会在他们的系统软件上使用调试器，没了这些调试符号可以省下很多磁盘空间。下一节将会告诉你如何剥离程序和库中所有的调试符号。

## 6.79. 再次清理无用内容

> 这个部分是可选的。
> 如果要在后续的 BLFS 中用 valgrind 或 gdb 做回归测试，那么调试信息还有用武之地。
```
save_lib="ld-2.30.so libc-2.30.so libpthread-2.30.so libthread_db-1.0.so"

cd /lib

for LIB in $save_lib; do
    objcopy --only-keep-debug $LIB $LIB.dbg 
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB 
done    

save_usrlib="libquadmath.so.0.0.0 libstdc++.so.6.0.27
             libitm.so.1.0.0 libatomic.so.1.2.0" 

cd /usr/lib

for LIB in $save_usrlib; do
    objcopy --only-keep-debug $LIB $LIB.dbg
    strip --strip-unneeded $LIB
    objcopy --add-gnu-debuglink=$LIB.dbg $LIB
done

unset LIB save_lib save_usrlib
```
> 在进行清理无用内容之前，格外注意确保要删除的二进制文件没有正在运行：
```
exec /tools/bin/bash
```

> 现在可以安心的清除二进制文件和库：
```
/tools/bin/find /usr/lib -type f -name \*.a \
   -exec /tools/bin/strip --strip-debug {} ';'

/tools/bin/find /lib /usr/lib -type f \( -name \*.so* -a ! -name \*dbg \) \
   -exec /tools/bin/strip --strip-unneeded {} ';'

/tools/bin/find /{bin,sbin} /usr/{bin,sbin,libexec} -type f \
    -exec /tools/bin/strip --strip-all {} ';'
```
> 该命令会报告有很大数目的文件不能识别它们的格式。你可以安全地忽略这些警告。这些警告表示这些文件是脚本而不是二进制文件。

## 6.80. 清理

> 最后，清除运行测试留下来的多余文件：
```
rm -rf /tmp/*
```

> 现在先注销，用以下新的 chroot 命令重新进入 chroot 环境。在此以后当需要进入 chroot 环境时，都是用这个新的 chroot 命令：
```
logout

chroot "$LFS" /usr/bin/env -i          \
    HOME=/root TERM="$TERM"            \
    PS1='(lfs chroot) \u:\w\$ '        \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin \
    /bin/bash --login
```
> 这样做的原因是不再需要 /tools 中的程序。因此你可以删除 /tools 目录。

> 如果通过手动或者重启卸载了虚拟内核文件系统，重新进入 chroot 的时候确保挂载了虚拟内核文件系统。在 第 6.2.2 节 「挂载和激活 /dev」 和 第 6.2.3 节 「挂载虚拟文件系统」 中介绍了该过程。

> 还有一些此章之前为了一些软件包的回归测试而留下的静态库。这些库来自 binutils、bzip2、e2fsprogs、flex、libtool 和 zlib。如果想删的话，现在就删：
```
rm -f /usr/lib/lib{bfd,opcodes}.a
rm -f /usr/lib/libbz2.a
rm -f /usr/lib/lib{com_err,e2p,ext2fs,ss}.a
rm -f /usr/lib/libltdl.a
rm -f /usr/lib/libfl.a
rm -f /usr/lib/libz.a
```

> 还有几个安装在 /usr/lib 和 /usr/libexec 目录下的文件，文件的扩展名为 .la。这些是「libtool 归档」文件，在 Linux 系统中通常不需要它们。这些都是没有必要的东西。想要删除的话，运行：
```
find /usr/lib /usr/libexec -name \*.la -delete
```

# 第 7 章 基本系统配置

## 7.1. 简介

启动 Linux 系统牵涉到好些任务。该过程须挂载虚拟和现实两个文件系统，初始化设备，激活 swap，检查文件系统是否完整，挂载所有的 swap 分区和文件，设置系统时钟，配属网络，起动系统需要的守护进程，并完成用户想要完成的那些自定义的任务。该过程必须有组织有纪律，以确保任务能被井然有序地实施，并尽可能快地执行。

### 7.1.1. System V

1983 年以来，System V 便是 Unix 和类 Unix （例如 Linux）系统中的经典启动过程。它包括小程序 init 用于启动诸如 login （由 getty 启动）这样的基础程序，并运行着名为 rc 的脚本。该脚本，控制着一众附加脚本的执行，而那些附加脚本便是实施系统初始化所需要的任务的脚本。

程序 init 由文件 /etc/inittab 控制着，并且被组织成用户能够运行的运行级别形式：

0 — 停止

1 — 单用户模式

2 — 多用户，无网络

3 — 完整的多用户模式

4 — 用户可定义

5 — 完整的多用户模式，附带显示管理

6 — 重启

常用的默认运行级为 3 或 5。

益处
- 公认的，容易理解的体系。

- 方便定制。

弊端
- 启动较慢。中等速度的 LFS 的系统，从内核的第一个消息至登录提示需花费 8-12 秒。网络连接一般在登录提示后约 2 秒内建立。

- 串联执行启动任务。与上一点有些关联。过程中的任何一个，比方说，文件系统检查有延迟，就会拖延整个启动的过程。

- 不支持控制组群（control groups，缩写为 cgroups）这样的新特性，根据每个用户公平地分享调度。

- 添加脚本需手动的、静态的排序决策。

## 7.2. LFS-Bootscripts-20190524
> 软件包 LFS-Bootscripts 包含一套在启动/关机时开始/停止 LFS 系统的脚本。自定义启动过程所需的配置文件和程序将在随后的段落中交代。

### 7.2.1. 安装 LFS-Bootscripts

```
cd $LFS/sources
tar xvf lfs-bootscripts-20190524.tar.xz
cd lfs-bootscripts-20190524
```

```
make install
```

```
cd $LFS/sources
rm -rf lfs-bootscripts-20190524
```

## 7.3. 设备与模块管理概述

使用 udev 方法，只有当内核检测到硬件接入，才会建立对应的节点文件。因为需要在系统启动的时候重新建立设备节点文件，所以将它存储在 devtmpfs 文件系统中（完全存在于内存中的虚拟文件系统）。设备节点文件无需太多的空间，所以占用的内存也很小。

## 7.4. 设备管理

### 7.4.1. 网络设备

一般来说，udev 根据获取到的固件/BIOS 信息或者一些像总线号、插槽号或 MAC 地址等物理信息来命名网络设备。之所以采用这样的命名方式，是为了确保网络设备可以得到一个持久化的名称，且这个名称不会随着设备的发现时间而改变。例如，在一台同时拥有 Intel 网卡和 Realtek 网卡的双网卡计算机上，Intel 网卡可能会被命名为 eth0 而 Realtek 网卡可能会被命名为 eth1。在某些情况下，可能是一次重启使网卡重新编号了。

在持久化命名方式中，典型的网络设备名称看起来可能像 enp5s0 或者 wlp3s0 。如果你不希望采用这种命名方式，则还可以采用传统命名或者自定义的命名方式。

#### 7.4.1.1. 在内核命令行上禁用持久命名

可以在内核命令行上添加 net.ifnames=0 来恢复传统命名方式，采用 eth0、eth1 等来命名。这种命名方式对于那些网络设备类型唯一的系统最为合适。笔记本电脑通常拥有多个以太网连接，常被命名为 eth0 和 wlan0，也同样适用这种命名方法。可通过修改 GRUB 配置文件命令行。参见 第 8.4.4 节 「创建 GRUB 配置文件」。

#### 7.4.1.2. 创建自定义 udev 规则

> 可以通过创建自定义 udev 规则来改变网络设备命名方式。这里有一个脚本可以创建初始规则，运行：
```
bash /lib/udev/init-net-rules.sh
```

> 现在，可以检查 /etc/udev/rules.d/70-persistent-net.rules 文件, 来确定具体哪个名称配对了哪一个网络设备：
```
cat /etc/udev/rules.d/70-persistent-net.rules
```

>> Note
>
> 在某些特定情形下,如当一个 MAC 地址被手动指定给一个网卡或者如 Qemu 或 Xen 这样的虚拟环境时,可能并不会生成上述的网络规则文件。这是由于手动指定的 MAC 地址并不是永久固定的。在这种情况下,不能采用持久化命名方式来确定设备名称。

这个文件应由一个注释段落开头。之后每个网卡都对应有两行信息。第一行以注释形式描述了该网卡的硬件信息（如果是 PCI 网卡，还有其 PCI 厂商标识和设备标识），如果对应的驱动程序存在，还应在随后的括号中注明。要注意，该注释行中的硬件标识和驱动程序都不能决定其接口名，仅做参考作用。第二行则是网卡的 udev 规则，根据该规则可以确定网卡的设备名称。

udev 规则总的来说是由逗号或空格分割的若干键值对组成的，规则中的每一个键的解释如下所示：

- SUBSYSTEM=="net" - 让 udev 忽略不是网卡的设备。

- ACTION=="add" - 让 udev 对增加 uevent 以外的操作，忽略该规则（删除 uevent 和改变 uevent 也会发生，但都不会导致网络接口重新命名）。

- DRIVERS=="?*" - 让 udev 忽略 VLAN 和桥接子接口。（由于这些子接口没有独立的驱动程序）。而且子接口的名称可能会与父接口的名字相冲突，因而会被忽略。

- ATTR{address} - 该键值表示网卡的 MAC 地址。

- ATTR{type}=="1" - 对于一些可能会产生多个虚拟接口的无线网卡驱动，该键用于确保规则只会应用于其首要接口。和之前的 VLAN 接口和桥接子接口的理由一样，次要接口会被忽略。

- NAME - 这个键中的值将是 udev 指定给接口的名称。

NAME 的健值相当重要。在进行操作之前，你已经为每一个网卡设备准备了一个名称，并且在之后的配置文件中使用对应的 NAME 键值。

## 7.5. 通用网络配置

### 7.5.1. 创建网络接口配置文件

> 确定网卡接口的名称：

`ip link` 或者 `ls /sys/class/net`

```
cd /etc/sysconfig/
cat > ifconfig.enp7s0 << "EOF"
ONBOOT=yes
IFACE=enp7s0
SERVICE=ipv4-static
IP=172.18.253.20
GATEWAY=172.18.253.1
PREFIX=24
BROADCAST=172.18.253.255
EOF
```
> 这里按照自己实际网络情况进行配置。

如果变量 ONBOOT 设置为「yes」则 System V 网络脚本将在系统启动期间激活网卡，如果设置为其他非「yes」值则不会自动激活网卡。但是你可以通过命令 ifup 和 ifdown 手动激活或者是禁用网卡。

变量 IFACE 用于定义接口的名称，例如 eth0。所有的网络设备配置文件都依赖于它。文件扩展名必须与该值匹配。

变量 SERVICE 定义了获取 IP 地址的方式。LFS-Bootscripts 包中有模块化的 IP 分配格式，且在文件夹 /lib/services/ 中建立文件以允许其他的 IP 获取方式。在 BLFS 书中，通常它被设置为动态主机配置协议（DHCP）。

变量 GATEWAY 应该包括默认的网关 IP 地址。如果不需要，应该直接将这行注释掉。

变量 PREFIX 表示子网所用的位数。IP 地址中每一个字节是 8 位。如果子网掩码是 255.255.255.0，那么就会使用最前面的 3 个字节（24位）表达网络号。如果子网掩码是 255.255.255.240，则使用最开始的 28 位。前缀如果大于 24 位，一般都用于 DSL 或者是有线 ISP。在此示例中（PREFIX=24），子网掩码是 255.255.255.0。根据你实际的指望调整此字段，如果省略此字段，则默认为 24。

如欲获得更多信息，请浏览 ifup 的 man 手册。

### 7.5.2. 创建 /etc/resolv.conf 文件

如果系统连接到互联网，则需要通过 DNS（域名服务）将域名和 IP 地址进行相互的转换。

```
cat > /etc/resolv.conf << "EOF"
# Begin /etc/resolv.conf

domain search
nameserver 114.114.114.114
nameserver 8.8.8.8

# End /etc/resolv.conf
EOF
```
如果你只想要填写一个 DNS 服务器，那么将文件中的第二行 nameserver 移除即可。该 IP 地址也可能是本地网络中的路由。

### 7.5.3. 配置系统主机名称

```
echo "lfs9.0" > /etc/hostname
```

lfs9.0 可以替换为你想要设置的名称。请不要输入完整域名（Fully Qualified Domain Name，FQDN），那应该是放在 /etc/hosts 文件中的信息。

### 7.5.4. 定制文件 /etc/hosts

文件 /etc/hosts 用于 IP 地址和完全限定域名（FQDN）及可能的别名的对应。

除非计算机在互联网中可见（例如拥有注册的域名且分配了有效的 IP 地址——大部分用户并不具备此条件），否则请确保 IP 地址位于有效的私有网络 IP 地址段。有效区间为：

```
私有网络地址范围      常规前缀
10.0.0.1 - 10.255.255.254           8
172.x.0.1 - 172.x.255.254           16
192.168.y.1 - 192.168.y.254         24
x 可以是 16-31 中的任何数字，y 可以是 0-255 中的任何数字。
```

有效的私有 IP 地址可以是 192.168.1.1，有效的完全限定域名可以是 lfs.example.org。

即使不需要使用网卡，也应该需要有效的完全限定域名。它的存在可以确保程序能正常运行。

通过以下命令建立 /etc/hosts 文件：

```
cat > /etc/hosts << "EOF"
# Begin /etc/hosts

127.0.0.1 localhost
# 127.0.1.1 <FQDN> <HOSTNAME>
# <192.168.1.1> <FQDN> <HOSTNAME> [alias1] [alias2 ...]
172.18.253.20 lfs9.0
::1       localhost ip6-localhost ip6-loopback
ff02::1   ip6-allnodes
ff02::2   ip6-allrouters

# End /etc/hosts
EOF
```

其中，<192.168.1.1>，< FQDN >，和 < HOSTNAME > 的值应该根据用户和实际需要进行更改（如果已经通过网络/系统管理员获得了 IP 地址，那么设备就可以连接到已存在的网络）。其中可选的别名可以忽略。


## 7.6. System V 启动脚本的运用与配置

### 7.6.1. System V 的启动脚本是如何工作的？

SysVinit（或称「init」）以运行级的方案运作。内含 7 个（数字 0-6）运行级，（事实上还有更多的运行级，但那些运行级情况特殊，且不常用。详情参见 init(8)），其中的每一个数字，都对应着一个计算机启动时的操作。默认的运行级是 3。下列为不同运行级所对应功能的描述：

0: 关闭计算机
1: 单用户模式
2: 多用户模式无网络
3: 多用户模式含网络
4: 预留模式，如无定制与 3 无异
5: 与 4 无异，常用作 GUI（X 的 xdm 或 KDE 的 kdm）的登录
6: 重启计算机


### 7.6.2. 配置 Sysvinit

在内核初始化的时候，无论是命令行指定运行的第一个程序，还是默认的 init。该程序会读入初始化文件 /etc/inittab。下面创建此文件：

```
cat > /etc/inittab << "EOF"
# Begin /etc/inittab

id:3:initdefault:

si::sysinit:/etc/rc.d/init.d/rc S

l0:0:wait:/etc/rc.d/init.d/rc 0
l1:S1:wait:/etc/rc.d/init.d/rc 1
l2:2:wait:/etc/rc.d/init.d/rc 2
l3:3:wait:/etc/rc.d/init.d/rc 3
l4:4:wait:/etc/rc.d/init.d/rc 4
l5:5:wait:/etc/rc.d/init.d/rc 5
l6:6:wait:/etc/rc.d/init.d/rc 6

ca:12345:ctrlaltdel:/sbin/shutdown -t1 -a -r now

su:S016:once:/sbin/sulogin

1:2345:respawn:/sbin/agetty --noclear tty1 9600
2:2345:respawn:/sbin/agetty tty2 9600
3:2345:respawn:/sbin/agetty tty3 9600
4:2345:respawn:/sbin/agetty tty4 9600
5:2345:respawn:/sbin/agetty tty5 9600
6:2345:respawn:/sbin/agetty tty6 9600

# End /etc/inittab
EOF
```

初始化文件的解释可以参考 inittab 的 man 手册页面。对于LFS，运行的核心命令是 rc。上面的初始化文件将指示 rc 运行 /etc/rc.d/rcS.d 目录中，所有以 S 开头的脚本，然后便是 /etc/rc.d/rc?.d 目录中，所有以 S 开头的脚本。目录中的问号由指定的 initdefault 值来决定。

为了方便，rc 会从 /lib/lsb/init-functions 中读取函数库。该库还会读取一个可选的配置文件 /etc/sysconfig/rc.site。任何在后续章节中描述到的系统配置文件中的参数，都可以放在这个文件中，允许将所有的系统参数合并到该文件中。

为了调试方便，函数脚本会将日志输出到 /run/var/bootlog 文件中。由于 /run 目录是个 tmpfs（临时文件系统），所以该文件在启动之后就不会持续存在了，但在启动过程的最后，这些内容会被添附到更为持久的 /var/log/boot.log 文件中。

#### 7.6.2.1. 改变运行级

想要改变运行级，可以使用命令 init <runlevel>，其中的 <runlevel> 便是想要切换到的运行级。举个例子，若是想要重启计算机，可以使用命令 init 6，这是 reboot 命令的别名。就像，init 0 是 halt 的别名一样。

/etc/rc.d 下有许多看起来像 rc?.d 的目录（其中的 ? 便是运行级）以及 rcsysinit.d，这些目录下包含了许多符号链接。它们有些以 K 开头，另一些的以 S 开头，首字母的后面都有两位数字。其中的 K 意味着停止（杀死）服务，S 意味着启动服务。而这些数字则决定了脚本的运行顺序，从 00 至 99——数字越小的将越先被执行。当 init 切换到另一个运行级时，相应的服务将会依据运行级启动或停止。

真正的脚本放在 /etc/rc.d/init.d 目录中。那些链接全部指向它们，真正工作的便是它们。K 开头的链接和 S 开头的链接指向的其实是 /etc/rc.d/init.d 目录中的同一个脚本。能这样的原因是脚本可以用不同的参数调用，例如 start，stop，restart，reload 和 status。当遇到的链接是 K 开头的话，便相应执行脚本的 stop 参数。当遇到的链接是 S 开头的话，便相应执行脚本的 start 参数。

还有一种情况刚才没有提及。那便是 rc0.d 和 rc6.d 目录中以 S 开头的链接是不会导致任何服务被启动的。它们只会调用 stop 参数去停止某些服务。这背后的隐含逻辑便是，当用户打算重起或是关闭系统时，无需去启动些什么。系统仅仅是需要被停止而已。

### 7.6.3. udev 启动脚本

启动脚本 /etc/rc.d/init.d/udev 启动 udevd，触发已经被内核创建好的「冷插拔（coldplug）」设备，并等待规则完成。该脚本还会解除 /sbin/hotplug 中默认的 uevent 处理。这是因为内核不再需要调用外部的二进制文件了。取而代之的是，udevd 会为内核引发的 uevent 去监听 netlink 的套接字。

初始化脚本 /etc/rc.d/init.d/udev_retry 负责重新触发子系统的事件，这些子系统的规则，可能会依赖于直到 mountfs 脚本运行后才挂载的文件系统（特别是 /usr 和 /var）。该脚本会在 mountfs 脚本后运行，所以这些规则（若是被重新触发）应该会在第二次的时候成功。这些被配置在 /etc/sysconfig/udev_retry 文件中；这个文件中，除了注释以外的任何单词（word），都会被认为是在重试时触发的子系统名称。想要找到设备的子系统，使用 udevadm info --attribute-walk <device>，其中的 <device> 是 /dev 或 /sys 中的绝对路径，例如，/dev/sr0 或是 /sys/class/rtc。

关于内核模块载入和 udev 的更多信息，请查看 第 7.3.2.3 节 「加载模块」。

### 7.6.4. 配置系统时钟

setclock 脚本从硬件时钟，或称 BIOS 或 CMOS（互补金属氧化物半导体）时钟中，读取时间。如果硬件时钟被设置为 UTC，该脚本会使用 /etc/localtime 文件（它会告知程序 hwclock 用户的时区）将硬件时钟的时间转换为本地时间。因为无法检测硬件时钟是否为 UTC，所以需要手动去配置。

```
cat > /etc/sysconfig/clock << "EOF"
# Begin /etc/sysconfig/clock

UTC=1

# Set this to any options you might need to give to hwclock,
# such as machine hardware clock type for Alphas.
CLOCKPARAMS=

# End /etc/sysconfig/clock
EOF
```

### 7.6.5. 配置 Linux 控制台

有时，希望在启动时创建文件。例如，/tmp/.ICE-unix 目录就可能需要创建。这可以通过在 /etc/sysconfig/createfiles 配置脚本中创建一个条目来达成。该文件的格式可以参考默认配置文件中的注释。

- 对于中文，日语，韩语以及一些其他的语言需要的字符，Linux 的控制台还无法通过配置是之正常显示。用户若要使用这些语言，需要安装 X Window 系统，用于扩充所需字符域的字体，以及合适的输入法（例如，支持语言十分广泛的 SCIM）。

>> 注意
>
> /etc/sysconfig/console 文件只负责 Linux 文本控制台的本地化。对于 X Window 系统，通过 ssh 的会话，以及串口的控制台的键盘布局和终端字体，以上的设定并不适用。

### 7.6.6. 在启动时创建文件

有时，希望在启动时创建文件。例如，/tmp/.ICE-unix 目录就可能需要创建。这可以通过在 /etc/sysconfig/createfiles 配置脚本中创建一个条目来达成。该文件的格式可以参考默认配置文件中的注释。

### 7.6.7. 配置 sysklogd 脚本
sysklogd 脚本调用 syslogd 程序作为 System V 初始化的一部分。-m 0 选项会关闭 syslogd默认每 20 分钟写一次日志的时间戳标记。如果你想要开启周期性的时间戳标记，编辑 /etc/sysconfig/rc.site 并定义变量 SYSKLOGD_PARMS 设为需要的值。例如，想要清除所有的参数，只需把变量设置为空值：

SYSKLOGD_PARMS=
运行 man syslogd，查看更多选项。

### 7.6.8. 文件 rc.site

可选的 /etc/sysconfig/rc.site 文件中包含着那些为每个 System V 启动脚本自动设置好的设定。这些设定也可以在 /etc/sysconfig/ 目录中的 hostname，console，和clock 文件中设置。如果这些设定值同时在以上的这些文件和 rc.site 中设定了，那么脚本中的设定值将会被优先采用。

rc.site 中还包含了另外一些可以自定义的启动过程的参数。设置 IPROMPT 变量会启用启动脚本的选择性运行。其他的选项，在文件的注释中有所描述。文件的默认版本如下所示：

```
# rc.site
# Optional parameters for boot scripts.

# Distro Information
# These values, if specified here, override the defaults
#DISTRO="Linux From Scratch" # The distro name
#DISTRO_CONTACT="lfs-dev@linuxfromscratch.org" # Bug report address
#DISTRO_MINI="LFS" # Short name used in filenames for distro config

# Define custom colors used in messages printed to the screen

# Please consult `man console_codes` for more information
# under the "ECMA-48 Set Graphics Rendition" section
#
# Warning: when switching from a 8bit to a 9bit font,
# the linux console will reinterpret the bold (1;) to
# the top 256 glyphs of the 9bit font.  This does
# not affect framebuffer consoles

# These values, if specified here, override the defaults
#BRACKET="\\033[1;34m" # Blue
#FAILURE="\\033[1;31m" # Red
#INFO="\\033[1;36m"    # Cyan
#NORMAL="\\033[0;39m"  # Grey
#SUCCESS="\\033[1;32m" # Green
#WARNING="\\033[1;33m" # Yellow

# Use a colored prefix
# These values, if specified here, override the defaults
#BMPREFIX="      "
#SUCCESS_PREFIX="${SUCCESS}  *  ${NORMAL} "
#FAILURE_PREFIX="${FAILURE}*****${NORMAL} "
#WARNING_PREFIX="${WARNING} *** ${NORMAL} "

# Manually seet the right edge of message output (characters)
# Useful when resetting console font during boot to override
# automatic screen width detection
#COLUMNS=120

# Interactive startup
#IPROMPT="yes" # Whether to display the interactive boot prompt
#itime="3"    # The amount of time (in seconds) to display the prompt

# The total length of the distro welcome string, without escape codes
#wlen=$(echo "Welcome to ${DISTRO}" | wc -c )
#welcome_message="Welcome to ${INFO}${DISTRO}${NORMAL}"

# The total length of the interactive string, without escape codes
#ilen=$(echo "Press 'I' to enter interactive startup" | wc -c )
#i_message="Press '${FAILURE}I${NORMAL}' to enter interactive startup"

# Set scripts to skip the file system check on reboot
#FASTBOOT=yes

# Skip reading from the console
#HEADLESS=yes

# Write out fsck progress if yes
#VERBOSE_FSCK=no

# Speed up boot without waiting for settle in udev
#OMIT_UDEV_SETTLE=y

# Speed up boot without waiting for settle in udev_retry
#OMIT_UDEV_RETRY_SETTLE=yes

# Skip cleaning /tmp if yes
#SKIPTMPCLEAN=no

# For setclock
#UTC=1
#CLOCKPARAMS=

# For consolelog (Note that the default, 7=debug, is noisy)
#LOGLEVEL=7

# For network
#HOSTNAME=mylfs

# Delay between TERM and KILL signals at shutdown
#KILLDELAY=3

# Optional sysklogd parameters
#SYSKLOGD_PARMS="-m 0"

# Console parameters
#UNICODE=1
#KEYMAP="de-latin1"
#KEYMAP_CORRECTIONS="euro2"
#FONT="lat0-16 -m 8859-15"
#LEGACY_CHARSET=
```

#### 7.6.8.1. 自定义启动和关闭的脚本

LFS 启动脚本会以相当效率的方式启动和关闭系统，不过你可以在 rc.site 文件中进行调整，来提升速度或是根据需求调整消息。若是有这样的需求，就去调整上面 /etc/sysconfig/rc.site 文件的设置吧！

在启动脚本 udev 运行时，会调用一次 udev settle，完成检测需要很长时间。这段时间根据当前系统的设备，可花可不花。如果你需要的仅仅是简单的分区和单个网卡，在启动的过程中，就没有必要等待这个命令执行。通过设置变量 OMIT_UDEV_SETTLE=y，可以跳过此命令。

启动脚本 udev_retry 默认也执行udev settle。该命令仅在 /var 目录是分开挂载的情况下需要。因为这种情况下时钟需要文件 /var/lib/hwclock/adjtime。其他的自定义设置可能也需要等待 udev 执行完成，但是在许多的安装中不需要。设置变量 OMIT_UDEV_RETRY_SETTLE=y 跳过命令。

默认情况下，文件系统检测静默执行。看上去就像是启动过程中的一个延迟。想要打开 fsck 的输出，设置变量。

重起时，你可能想完全的跳过文件系统检测 fsck。为此，可以创建 /fastboot 文件或是以 /sbin/shutdown -f -r now 命令重启系统。另一方面，你也可以通过创建 /forcefsck，或是在运行 shutdown 命令时，用 -F 参数代替-f，以此来强制检测整个文件系统。

设置变量 FASTBOOT=y 将禁用启动过程中的 fsck，直至你将其移除。不推荐长时间地使用该方式。

通常，/tmp 目录中的所有文件会在启动时删除。根据存在目录与文件的数量，该操作会导致启动过程中明显的延迟。如果要跳过移除文件的操作，设置变量 SKIPTMPCLEAN=y。

在关机的过程中，init 程序会向每一个已经启动的程序（例如，agetty）发送一个 TERM 信号，等一段时间（默认为 3 秒），然后给每个进程发送 KILL 信号。对没有被自身脚本关闭的进程，sendsignals 脚本会重复此过程。init 的延迟可以通过参数来设置。比方说，想去掉 init 的延迟，可以通过在关机或重启时使用 -t0 参数（如，/sbin/shutdown -t0 -r now）。sendsignals 脚本的延迟可以通过设置参数 KILLDELAY=0 跳过。

## 7.7. Bash Shell 启动文件

shell 程序 /bin/bash （下文称为「shell」）使用一系列的启动文件来帮助建立将要运行的环境。每一个文件都有特定的用途，它可能会影响登陆和交互环境。在 /etc 目录下的文件提供了全局的配置。如果等效的文件存在于用户文件夹，则可能会覆盖全局设置。

交互式登录 shell 在成功登录后启动，它使用 /bin/login 去读取 /etc/passwd。交互式非登录 shell 通过命令行（如 [prompt]$/bin/bash ）启动。非交互式 shell 通常是一段正在运行的 shell 脚本。它之所以是非交互的是因为它执行一段脚本却不需要用户在命令间输入指令。

更多信息，阅读 info bash 下 Bash Startup Files and Interactive Shells 章节。

当 shell 被作为交互登陆 shell 时，会读取文件 /etc/profile 和 ~/.bash_profile 。


```
cat > /etc/locale.conf << "EOF"
LANG=en_US.UTF-8
# LC_NUMERIC=zh_CN.UTF-8
# LC_TIME=zh_CN.UTF-8
# LC_MONETARY=zh_CN.UTF-8
# LC_PAPER=zh_CN.UTF-8
# LC_NAME=zh_CN.UTF-8
# LC_ADDRESS=zh_CN.UTF-8
# LC_TELEPHONE=zh_CN.UTF-8
# LC_MEASUREMENT=zh_CN.UTF-8
# LC_IDENTIFICATION=zh_CN.UTF-8
EOF
```

```
cat > /etc/profile << "EOF"
# Begin /etc/profile

export LANG=en_US.UTF-8
# export LC_NUMERIC=zh_CN.UTF-8
# export LC_TIME=zh_CN.UTF-8
# export LC_MONETARY=zh_CN.UTF-8
# export LC_PAPER=zh_CN.UTF-8
# export LC_NAME=zh_CN.UTF-8
# export LC_ADDRESS=zh_CN.UTF-8
# export LC_TELEPHONE=zh_CN.UTF-8
# export LC_MEASUREMENT=zh_CN.UTF-8
# export LC_IDENTIFICATION=zh_CN.UTF-8

# End /etc/profile
EOF
```

## 7.8. 创建 /etc/inputrc 文件

inputrc 文件的作用是告知系统应该以怎样的键盘布局处理键盘。此文件对于 readline —— 输入相关库，或者是一些 shell （例如 bash 等）来说十分重要。

对于大部分用户来说，都不使用那些奇奇怪怪的键盘映射，所以，可以通过以下的命令建立一个全局的 /etc/inputrc 以供所有用户使用。如果需要更改某一个用户的键盘映射，仅需要在那个用户的 HOME 目录下建立一个 .inputrc 文件，然后修改对应的键盘映射就可以了。

如果需要了解更多有关如何编辑 inputrc 文件的信息，可以查看 info bash 中 Readline Init File 一节。其实查看 info readline 也可以获得不少有用的东西。

下面显示的就是通用的 inputrc 文件，其中包含有 “#” 的都是注释行（需要注意的是，此文件不支持在设置后跟随注释）。使用以下命令创建此文件：

```
cat > /etc/inputrc << "EOF"
# Begin /etc/inputrc
# Modified by Chris Lynn <roryo@roryo.dynup.net>

# Allow the command prompt to wrap to the next line
set horizontal-scroll-mode Off

# Enable 8bit input
set meta-flag On
set input-meta On

# Turns off 8th bit stripping
set convert-meta Off

# Keep the 8th bit for display
set output-meta On

# none, visible or audible
set bell-style none

# All of the following map the escape sequence of the value
# contained in the 1st argument to the readline specific functions
"\eOd": backward-word
"\eOc": forward-word

# for linux console
"\e[1~": beginning-of-line
"\e[4~": end-of-line
"\e[5~": beginning-of-history
"\e[6~": end-of-history
"\e[3~": delete-char
"\e[2~": quoted-insert

# for xterm
"\eOH": beginning-of-line
"\eOF": end-of-line

# for Konsole
"\e[H": beginning-of-line
"\e[F": end-of-line

# End /etc/inputrc
EOF
```

## 7.9. 创建 /etc/shells 文件

shells 文件是当前系统所有可用 shell 的列表文件。应用程序通过读取它可以知道需要使用的 shell 是否有效。每行指定一个 shell 的绝对路径，即从根目录（/）开始的路径。

例如，当非特权用户想要使用 chsh 命令更改自己登录所用的 shell 时。如果命令没有在 /etc/shell 中找到，那么将会拒绝更改。

这个文件对于某些程序来说是必需的，比如 GDM 在找不到 /etc/shells 时就不会启用头像登录界面，还有 FTP 守护进程通常会禁止使用不在这个文件里列出终端的用户登录。

```
cat > /etc/shells << "EOF"
# Begin /etc/shells

/bin/sh
/bin/bash

# End /etc/shells
EOF
```

# 第 8 章 让 LFS 系统可引导

## 8.1. 简介

是时候该让 LFS 系统可以启动了。本章节将讨论以下内容：创建 fstab 文件、为新的 LFS 系统编译内核、安装 GRUB 引导器。如此，就可以在电脑启动的时候选择启动 LFS 系统了。

## 8.2. 创建 /etc/fstab 文件

/etc/fstab 文件的作用是让其它程序确定存储设备的默认挂载点、挂载参数和检查信息（例如完整性检测）。仿照以下格式新建一个文件系统列表（file system table，简称 fstab）文件：
```
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system  mount-point  type     options             dump  fsck
#                                                              order

/dev/sda8      /            ext4    defaults            1     1
/dev/sda4      /boot        ext4    defaults            0     2
/dev/sda5      swap         swap     pri=1               0     0
proc           /proc        proc     nosuid,noexec,nodev 0     0
sysfs          /sys         sysfs    nosuid,noexec,nodev 0     0
devpts         /dev/pts     devpts   gid=5,mode=620      0     0
tmpfs          /run         tmpfs    defaults            0     0
devtmpfs       /dev         devtmpfs mode=0755,nosuid    0     0

# End /etc/fstab
EOF
```

关于文件中六个字段的含义，请查看 man 5 fstab（译者注：fsck 列的数值来决定需要检查的文件系统的检查顺序。允许的数字是0, 1, 和2。根目录应当获得最高的优先权 1, 其它所有需要被检查的设备设置为 2。0 表示设备不会被 fsck 所检查）。

基于 MS-DOS 或者是来源于 Windows 的文件系统（例如：vfat，ntfs，smbfs，cifs，iso9660，udf）需要在挂载选项中添加「iocharset」，才能让非 ASCII 字符的文件名正确解析。此选项的值应该与语言区域设置的值相同，以便让内核能正确处理。此选项在相关字符集定义已为内核内建或是编译为模块时生效（在文件系统 -> 本地语言支持中查看）。此外，vfat 和 smbfs 还需启用「codepage」支持。例如，想要挂载 USB 闪存设备，zh-CN.GBK 用户需要在 /etc/fstab 中添加以下的挂载选项：

noauto,user,quiet,showexec,iocharset=gbk,codepage=936
对于 zh_CN.UTF-8 用户的对应选项是：

noauto,user,quiet,showexec,iocharset=utf8,codepage=936
需要注意的是，iocharset 默认值是 iso8859-1 （其保证文件系统大小写敏感），而 utf8 这个参数告知内核使用 UTF-8 转换文件名，以便可以在 UTF-8 语言环境中解释它们。

此外，还有可能在内核的配置过程中就指定一些文件系统的默认代码页和 iocharset 值。相关参数有「默认 NLS 选项 」（CONFIG_NLS_DEFAULT），「默认远程 NLS 选项」（CONFIG_SMB_NLS_DEFAULT)，「FAT 默认代码页」（CONFIG_FAT_DEFAULT_CODEPAGE），和「FAT 默认 IO 字符集」（CONFIG_FAT_DEFAULT_IOCHARSET）。不过，无法在内核编译阶段指定 ntfs 文件系统的设置。

另外，一些硬盘类型在遇到电源故障时，假如在 /etc/fstab 中使用 barrier=1 这个挂载选项，则会让 ext3 文件系统的数据更加安全。如需检查磁盘是否支持此选项，请运行 hdparm。例如：

hdparm -I /dev/sda | grep NCQ
如果有输出内容，则代表选项可用。

注意：基于 逻辑卷管理（LVM）的分区不可使用 barrier 选项。

## 8.3. Linux-5.2.8

### 8.3.1. 安装内核

```
cd $LFS/sources
tar xvf linux-5.2.8.tar.xz
cd linux-5.2.8
```

```
make mrproper
make defconfig
make menuconfig
```

注意要确保启用/禁用/设置下面这些特性，否则系统也许不能正常工作甚至根本无法启动：
```
Device Drivers  --->
  Generic Driver Options  --->
   [ ] Support for uevent helper [CONFIG_UEVENT_HELPER]
   [*] Maintain a devtmpfs filesystem to mount at /dev [CONFIG_DEVTMPFS]

Kernel hacking  --->
       Choose kernel unwinder (Frame pointer unwinder)  ---> [CONFIG_UNWINDER_FRAME_POINTER]
```

>> 注意
> 如果你主机的硬件用的是 UEFI，那么上面的‘make defconfig’应该会自动添加一些 EFI 相关的内核选项。
>
> 为了让你的 LFS 内核，在你的主机是 UEFI 引导环境的情况下，能够被引导，你的内核必须要有这项：
>
> ```
> Processor type and features  --->
>    [*]   EFI stub support  [CONFIG_EFI_STUB]
> ```

```
make && make modules_install
```

在内核编译完成后，还需要一个额外步骤来完成安装。有些文件需要拷贝到 /boot 目录下。

>> 小心
>
> 如果宿主系统拥有单独的 /boot 分区，那么文件就应该复制到那里。简单的解决方法就是在执行前将 /boot 绑定到宿主的 /mnt/lfs/boot。以宿主系统中的 root 用户运行：
>
> ```
> mount --bind /boot /mnt/lfs/boot
> ```

>>> LeionTong注：
>
> 本文档的宿主系统不包含单独的 /boot 分区，同时注意到，为LFS系统单独划分的 /boot 分区 (/dev/sda4) 已于章节2.7以宿主系统中的 root 用户身份挂载到了 $LFS/boot 目录下了。

内核映像文件所在的实际目录根据主机系统架构可能会不一样。下面的文件名你也可以改成你喜欢的，不过开头最好是 vmlinuz 才可以兼容下一节要讲的配置引导过程的自动设定。下面的命令假设主机是 x86 架构：
```
cp -iv arch/x86/boot/bzImage /boot/vmlinuz-5.2.8-lfs-9.0
```

System.map 是内核的符号文件。它映射了每一个内核 API 函数的入口，以及内核运行时的数据结构地址。是调查内核问题时的资源。运行下面的命令安装映射文件：
```
cp -iv System.map /boot/System.map-5.2.8
```

在之前命令 make menuconfig 里生成的内核配置文件 .config 包含了当前编译的内核的所有配置。最好能保存下来留作参考：
```
cp -iv .config /boot/config-5.2.8
```

安装 Linux 内核文档：
```
install -d /usr/share/doc/linux-5.2.8
cp -r Documentation/* /usr/share/doc/linux-5.2.8
```

需要注意一下内核源代码目录下的文件属主并不是 root。在以 root 用户解压包的时候（我们在 chroot 环境里做的），解压出来的文件会拥有生成这个包的电脑里用户和组。在安装其他包的时候这并不是问题，因为它们的源代码在安装完后就删除了。不过，Linux 内核的源代码经常会保留比较长时间。这样的话，就有可能会把软件包作者的用户 ID 对应到本机的某个用户上。从而这个用户就会拥有内核源代码的写权限。

>> 注意
>
> 在很多情况下，内核的配置信息需要在稍后安装来自于 BLFS 的软件包后更新。这和其他的软件包不同，在安装完成编译好的内核后不需要将内核源码树删除。
>
> 如果想要保留内核的源码树，在 linux-5.2.8 下运行 chown -R 0:0 来确保所有文件的所有者都 root。
```
cd $LFS/sources
cd linux-5.2.8
chown -R 0:0 *
```

>> 警告
>
> 一些内核文档里建议创建符号链接 /usr/src/linux 指向内核源代码目录。这是 2.6 及以前版本内核的特定要求，而在 LFS 系统里一定不要创建这个链接，因为这样的话，在你的基础 LFS 系统完成后安装某些软件包时可能引起问题。

>> 警告
>
> 系统 include 目录（/usr/include）下的头文件应该总是和编译 Glibc 时用到的头文件保持一致。就是在 第 6.7 节 「Linux-5.2.8 API 头文件」 里整理过的头文件。因此，它们不要替换成原始内核头文件或任何清理过的内核头文件。


### 8.3.2. 配置 Linux 模块加载顺序

有时候需要特别指定加载顺序。modprobe 或 insmod 在加载模块时会读取 /etc/modprobe.d/usb.conf。如果将 USB 设备（ehci_hcd、ohci_hcd 和 uhci_hcd） 编译为模块，则需要此文件，这样它们就会以正确的顺序加载。ehci_hcd 需要在 ohci_hcd 和 uhci_hcd 之前加载，否则在系统启动过程中将会输出警告。

运行以下命令建立 /etc/modprobe.d/usb.conf 文件：
```
install -v -m755 -d /etc/modprobe.d
cat > /etc/modprobe.d/usb.conf << "EOF"
# Begin /etc/modprobe.d/usb.conf

install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true

# End /etc/modprobe.d/usb.conf
EOF
```

## 8.4. 使用 GRUB 设置启动过程

### 8.4.1. 简介

>> 警告
>
> 对 GRUB 进行错误的配置可能会导致在没有外置启动设备（某些USB设备，某些 CD-ROM 等）的情况下无法正常的启动。你可能仅仅需要修改当前正在使用的引导器（比如：Grub-Legacy，GRUB2 或 LILO 等）的配置。

>>> LeionTong注：
>
> 介绍两种灵活的方法：
> 1. 如果宿主机上有 Windows 系统，可以使用 EasyBCD 的 NeoGrub 引导LFS系统。
> 2. 如果U盘里有 WinPE 系统，可以使用 Grub4Dos 或 Xorboot-UEFI 搭配 BootICE 来管理启动引导项。

>> 注意
>
> 想要在启用 UEFI 的宿主系统上引导 LFS，需要遵循上一节的描述在内核中构建 CONFIG_EFI_STUB 功能。也可以使用 GRUB2 来引导 LFS，这样就无需实施以上的额外操作了。但需要在宿主系统的 BIOS 中关闭 UEFI 模式和安全引导（Secure Boot）功能。详细参见文件 lfs-uefi.txt。

### 8.4.2. GRUB 命名约定

GRUB 对于硬盘和分区自有一套命名规则 (hdn,m)，其中 n 是硬盘数，m 是分区号。硬盘数 N 从 0 开始计数，分区数需要区别对待——主分区从 1 开始计数而扩展分区从 5 开始计数。需要注意的是，和早期版本相比，计数方式都有所变化。例如，分区 sda1 是 (hd0,1)，sdb3 是 (hd1,3)。Linux 下，并不将 CD-ROM 设备假想为硬盘。例如，就算已有 CD 设备挂载为 hdb，第二块硬盘挂载为 hdc，GRUB 依旧将第二块硬盘称为 (hd1)。

### 8.4.3. 配置配置文件

GRUB 会将一些数据写入硬盘的第一个物理扇区。这一部分不属于任何一个操作系统，在启动时，该部分数据激活，然后寻找 Grub 的模块，Grub 模块的默认位置为 /boot/grub/。

一种建议是使用一个独立的小分区（建议大小 100MB）专用于引导信息。那样的话，每一个发行版，不论是 LFS 还是其他的商业发行版，都能访问相同的引导文件而且任何已经启动的系统都能访问它。如果你选择这么做，你需要挂载这个独立分区，移动所有的文件从当前的 /boot 目录（比如说你上一节刚编译的 Linux 内核）到新的分区。你然后要卸载这个新分区，重新挂载它为 /boot。如果你这么做，一定要更新 /etc/fstab。

使用当前的 lfs 分区也没有什么问题，但是在配置多系统启动的时候有些不同。

从以上信息可知，需要确定根分区的磁盘位置（如果使用单独的分区，则需要知道引导分区的磁盘位置），以下假定根分区（或者是磁盘分区）是 sda8。

将 GRUB 文件安装到 /boot/grub 然后设置启动扇区：

>> 警告
>
> 以下命令将会覆盖已有的引导器。如无需要，请勿运行（比如已经有第三方引导器管理 MBR）。
> ```
> grub-install /dev/sda
> ```

LeionTong注：
按照章节2的分区规划，同时为兼容多系统引导，不破坏原有的启动引导记录，将 Grub 文件安装到 /boot 所在分区（/dev/sda4）。
```
grub-install /dev/sda4
```

>> 注意
>
> 如果系统是通过 UEFI 引导的，`grub-install` 将会尝试将文件安装至 x86_64-efi，但是这些文件并未在第 6 章中安装。如果是在这种情况下，在上述命令后面追加 `--target i386-pc`。

### 8.4.4. 创建 GRUB 配置文件

创建 /boot/grub/grub.cfg:
```
cat > /boot/grub/grub.cfg << "EOF"
# Begin /boot/grub/grub.cfg
set default=0
set timeout=5

insmod ext2
set root=(hd0,4)

menuentry "GNU/Linux, Linux 5.2.8-lfs-9.0" {
        linux   /vmlinuz-5.2.8-lfs-9.0 root=/dev/sda8 ro
}
EOF
```

>> 注意
>
> 从 GRUB 的角度看，内核文件相当于一个分区，所以假如你使用单独的 /boot 分区，请不要在 linux 行添加 /boot。此外还需要将 set root 行指向 /boot 所在的实际分区。

GRUB 功能十分强大，它提供了大量的用于从种类繁多的设备和操作系统、以及不同的分区类型启动的选项。此外还可以定制启动页、播放声音或者是鼠标等。很遗憾的是，这些功能超出本文的范畴，我们一概不予讨论。

>> 小心
>
> grub-mkconfig -o /boot/grub/grub.cfg 命令可以自动建立配置文件。它使用位于 /etc/grub.d/ 下的一组脚本且将会忽略用户的设置。这些命令主要用于那些非源码编译的发行版，所以不建议 LFS 用户使用此命令。如果你使用商业发行版，你可以试着运行这个命令（运行之前记得备份原来的 grub.cfg 文件）。

# 第 9 章 尾声

## 9.1. 最后的最后

干的很棒嘛！至此，全新的 LFS 系统就已经安装完成啦！我们衷心地祝愿，你亲手定制的崭新 Linux 系统能陪着你乘风破浪。

创建 /etc/lfs-release 是个好主意。该文件能帮助你（和我们，如果你需要我们帮助的话）确定你当前使用的 LFS 版本。
```
echo 9.0 > /etc/lfs-release
```

推荐遵守 Linux Standards Base (LSB)，建立文件以显示当前系统的完整信息。
```
cat > /etc/lsb-release << "EOF"
DISTRIB_ID="Linux From Scratch"
DISTRIB_RELEASE="9.0"
DISTRIB_CODENAME="Leion Tong, Love U!"
DISTRIB_DESCRIPTION="Linux From Scratch"
EOF
```
你可以在「DISTRIB_CODENAME」字段填写一些特别的字符来彰显「你的」系统的与众不同！

## 9.2. 为 LFS 用户数添砖加瓦

截至此刻，你已经读完了这本书。你想要为 LFS 用户数添砖加瓦吗？赶快点击鼠标访问 http://www.linuxfromscratch.org/cgi-bin/lfscounter.php 输入用户名和第一次使用的 LFS 版本注册成为 LFS 用户吧。

赶快重启到 LFS 吧！

## 9.3. 重启系统

至此，所有的软件都已安装完毕，是时候重启你的电脑了。然而，你也应该注意一些事情。通过学习本书建立起来的系统属于最小系统，这也就意味着可能会缺失一些你需要的功能。就是说你还需要做些事情。当重启进入你的新 LFS 中时，这是一个在当前的 chroot 环境中安装一些 BLFS 书中的额外软件包的好时机。以下给出了一些建议：

- 文本模式的浏览器，例如 Lynx，可以在虚拟终端中访问这本 BLFS 书，以进行后续的编译打包工作。

- GPM（GPM：一个支持控制台和 xterm 的鼠标服务） 软件包可以让你在虚拟终端中更方便的执行复制/粘贴工作。

- 如果静态 IP 配置不能很好的适用于你当前环境的网络配置，可以安装 dhcpcd 或者是 dhcp 的客户端部分来解决。

- 安装 sudo，以便在非 root 用户环境下编译软件包，且可以很轻松的在新系统中安装编译出来的软件。

- 如果你想要在舒适的 GUI 环境远程访问新系统，请安装 openssh 及其依赖包 openssl。

- 为了更加便利的从网络中下载文件，请安装 wget。

- 如果你有 GUID 分区表（GPT）类型的磁盘，你也许需要 gptfdisk 或是 parted 。

- 最后，检查以下的配置文件是不是都是正确的吧。

    - /etc/bashrc

    - /etc/dircolors

    - /etc/fstab

    - /etc/hosts

    - /etc/inputrc

    - /etc/profile

    - /etc/resolv.conf

    - /etc/vimrc

    - /root/.bash_profile

    - /root/.bashrc

    - /etc/sysconfig/ifconfig.eth0

辛苦了那么久，是该初次启动我们崭新的 LFS 系统的时候了！首先，请退出 chroot 环境：
```
logout
```

然后卸载虚拟文件系统：
```
umount -v $LFS/dev/pts
umount -v $LFS/dev
umount -v $LFS/run
umount -v $LFS/proc
umount -v $LFS/sys
```

卸载 LFS 文件系统本身：
```
umount -v $LFS
```

如果还建立了其它的挂载点，请在卸载 LFS 文件系统之前先卸载它们：
```
umount -v $LFS/home
umount -v $LFS/boot
umount -v $LFS
```

至此，重启系统吧：
```
shutdown -r now
```

这里假设 GRUB 引导器已经如前文所述安装完毕且配置正确，启动项也已经自动设置为 LFS 9.0。

重启后，LFS 便已经可以使用了，你可以安装一些其它的软件以满足自己的需求。

## 9.4. 接下来做什么呢？

十分感谢你耐心的阅读这本 LFS 书，我们十分期待本书能够为你构建系统带来一点点的帮助。

我猜，你现在一定很开心——LFS系统已经安装完成。「但是，下面该作些什么呢？」不用担心，我们早已经帮你准备好以下资源！

- 维护

  定期检查软件的 bug 和安全公告。因为在从源码构建出 LFS 之后，你便应该养成经常去查看这些报告的好习惯。有关查询的去处，网上倒是有一些不错的资源，这里列举几个：

  - CERT（计算机应急响应小组）

    CERT 有一个邮件列表，专门公示各种操作系统和应用程序的安全警报。订阅信息请点击此链接查看：http://www.us-cert.gov/cas/signup.html.

  - Bugtraq

    Bugtraq 是一个专门公示计算机安全的邮件列表。它公示新发现的安全问题，偶尔还会尽可能的提出修补方案。订阅信息请点击此链接查看：http://www.securityfocus.com/archive.

- Beyond Linux From Scratch

  Beyond Linux From Scratch（BLFS）涵盖了比 LFS 书多得多的应用程序。BLFS 项目主页是： http://www.linuxfromscratch.org/blfs/.

- LFS Hints

  LFS Hints 是由 LFS 社区的志愿者提交的教育文集。有关信息访问以下网址取得： http://www.linuxfromscratch.org/hints/list.html.

- 邮件列表

  有几个 LFS 相关的邮件列表，在你需要的时候可以订阅，也可通过它获得最新的发展动态，对项目作出力所能及的贡献等等。查看 第 1 章 - 邮件列表 可以获得更多的信息。

- The Linux Documentation Project（TLDP，Linux 文档项目）

  Linux 文档项目（TLDP）的目标是通过协作来完善 Linux 文档中的所有不足。TLDP 已经完成了大量的 HOWTO、指南和 man 帮助页。它的网站是：http://www.tldp.org/.


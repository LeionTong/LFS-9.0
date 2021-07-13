
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
mkfs -v -t ext2 /dev/sda4
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
    /dev/sda4 /mnt/lfs/boot ext2 defaults 0 0
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

`[Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]`

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

`[Requesting program interpreter: /tools/lib64/ld-linux-x86-64.so.2]`

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

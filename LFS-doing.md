
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
    d. 回退到源文件目录。
    e. 除非特别说明，删除解压出来的目录。

## 5.4. Binutils-2.32 - 第 1 遍

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

## 5.5. GCC-9.2.0 - 第 1 遍

```
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

make && make install
```


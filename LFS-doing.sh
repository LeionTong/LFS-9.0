
# 第 2 章 准备宿主系统
## 2.2. 宿主系统要求
bash version-check.sh
yum list bash binutils bison bzip2 coreutils diffutils findutils gawk gcc glic grep gzip m4 make patch perl python3 sed tar texinfo xz 

## 2.4. 创建新分区
cfdisk
根分区（/）      /dev/sda8     25GB
/boot分区     /dev/sda4       300MB
SWAP交换分区    /dev/sda5       4GB

## 2.5. 在分区上创建文件系统
mkfs -v -t ext4 /dev/sda8
mkfs -v -t ext2 /dev/sda4
mkswap /dev/sda5    #如果你已经有了现成的 swap 分区,不需要重新格式化。如果是新建的 swap 分区，需要用命令初始化

## 2.6. 设置 $LFS 变量
echo 'source lfsrc' >> .bash_profile
echo 'export LFS=/mnt/lfs' > lfsrc

## 2.7. 挂载新分区
mkidr -pv $LFS
mount -v -t ext4 /dev/sda8 $LFS
mkdir -v $LFS/boot
mount -v -t ext4 /dev/sda4 $LFS/boot

vim /etc/fstab
    ---
    /dev/sda8 /mnt/lfs ext4 defaults 1 1
    /dev/sda4 /mnt/lfs/boot ext2 defaults 0 0
    ---

# 第 3 章 软件包和补丁
## 3.1. 简介
> 我们无法保证下载的地址是一直有效的。如果在本书发布后下载地址变了，大部分软件包可以用 Google （http://www.google.com/） 解决。如果连搜索也失败了，那不妨试一试 http://www.linuxfromscratch.org/lfs/packages.html#packages 中提到的其他下载地址。
mkdir -v $LFS/sources
chmod -v a+wt $LFS/sources  #设置目录的写权限和粘滞模式。「粘滞模式」是指，即便多个用户对某个目录有写权限，但仅有文件的所有者，能在粘滞目录中删除该文件。

    > 一个简单的一口气下载所有软件包和补丁的方法是使用 wget-list 作为 wget 的输入。
    > LCTT译注：由于这些文件都分布在国外的不同站点上，因此有些下载的会很慢。非常感谢中国科学技术大学镜像站提供的LFS软件包：http://mirrors.ustc.edu.cn/lfs/lfs-packages/9.0/。可以使用我们制作的 wget-list-ustc https://github.com/LCTT/LFS-BOOK/blob/9.0-translating/wget-list-ustc 方便下载。

wget https://raw.githubusercontent.com/LCTT/LFS-BOOK/9.0-translating/wget-list-ustc
wget --input-file=wget-list --continue --directory-prefix=$LFS/sources

    > 从 LFS-7.0 开始，多了一个单独的文件 md5sums，可以在正式开始前校验所有的文件是否都正确。
wget http://mirrors.ustc.edu.cn/lfs/lfs-packages/9.0/md5sums
pushd $LFS/sources
md5sum -c md5sums
popd

# 第 4 章 最后的准备工作
## 4.2. 创建目录 $LFS/tools
mkdir -v $LFS/tools
ln -sv $LFS/tools /
## 4.3. 添加 LFS 用户
    > 当以 root 用户登录时，犯一个小错误可能会破坏或摧毁整个系统。因此，建议在本章中以非特权用户编译软件包。
groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
passwd lfs
chown -v lfs $LFS/tools
chown -v lfs $LFS/sources
su - lfs

## 4.4. 设置环境
    > 通过为 bash shell 创建两个开机启动的文件，设置合适的工作环境。
cat > ~/.bash_profile << "EOF"
exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
EOF
    > 当以 lfs 用户身份登录时，初始 shell 通常是一个 login 的 shell，它先读取宿主机的 /etc/profile 文件（很可能包括一些设定和环境变量），然后是 .bash_profile 文件。.bash_profile 中的命令 exec env -i.../bin/bash 用一个除了 HOME，TERM 和 PS1 变量外，其他环境完全为空的新 shell 代替运行中的 shell。这能确保不会有潜在的和意想不到的危险环境变量，从宿主机泄露到构建环境中。这样做主要是为了确保环境的干净。
    > 新的 shell 实例是一个 non-login 的 shell，不会读取 /etc/profile 或者 .bash_profile 文件，而是读取 .bashrc。现在，创建 .bashrc 文件：
cat > ~/.bashrc << "EOF"
set +h
umask 022
LFS=/mnt/lfs
LC_ALL=POSIX
LFS_TGT=$(uname -m)-lfs-linux-gnu
PATH=/tools/bin:/bin:/usr/bin
export LFS LC_ALL LFS_TGT PATH
EOF
    > 最后，启用刚才创建的用户配置，为构建临时工具完全准备好环境：
source ~/.bash_profile

# 第 5 章 构建临时系统
## 简介
    > 本章构造一个最小的 Linux 系统。
    > 构建这个最小系统有两个步骤。第一步，是构建一个与宿主系统无关的新工具链（编译器、汇编器、链接器、库和一些有用的工具）。第二步则是使用该工具链，去构建其它的基础工具。
    > 本章中编译得到的文件将被安装在目录 $LFS/tools 中，以确保在下一章中安装的文件和宿主系统生成的目录相互分离。
## 5.2. 工具链技术说明
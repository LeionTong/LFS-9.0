
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
cd $LFS/sources
wget http://mirrors.ustc.edu.cn/lfs/lfs-packages/9.0/md5sums
pushd $LFS/sources
md5sum -c md5sums
popd

>> 注意
>>
>> 非常重要，从本章开始，后续章节中的命令都要在 chroot 环境下运行。如果因为某种原因（比如说重启）离开了这个环境，请保证要按照 第 6.2.2 节 「挂载和激活 /dev」 和 第 6.2.3 节 「挂载虚拟文件系统」 中所说的那样挂载虚拟内核文件系统，并在继续构建之前重新运行 chroot 进入环境。

在宿主系统上以root身份执行以下命令以进入 chroot 环境：

```
mount -v --bind /dev $LFS/dev

mount -vt devpts devpts $LFS/dev/pts -o gid=5,mode=620
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run

if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi

chroot "$LFS" /tools/bin/env -i \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/bin:/usr/bin:/sbin:/usr/sbin:/tools/bin \
    /tools/bin/bash --login +h
```

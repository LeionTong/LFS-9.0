# CentOS 7升级gcc版本

> 升级：
```
yum install centos-release-scl
yum install devtoolset-8-gcc*
mv /usr/bin/gcc /usr/bin/gcc-4.8.5
ln -s /opt/rh/devtoolset-8/root/bin/gcc /usr/bin/gcc
mv /usr/bin/g++ /usr/bin/g++-4.8.5
ln -s /opt/rh/devtoolset-8/root/bin/g++ /usr/bin/g++
gcc --version
g++ --version
```


> 还原：

```
mv /usr/bin/gcc-4.8.5 /usr/bin/gcc
mv /usr/bin/g++-4.8.5 /usr/bin/g++
yum remove devtoolset-8-gcc*
yum remove centos-release-scl
```

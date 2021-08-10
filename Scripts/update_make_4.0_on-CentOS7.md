LFS-9.0要求 make 最低版本 4.0，CentOS7 系统默认带的 GNU Make 3.82，需要升级。

```
cd /tmp

wget http://mirrors.ustc.edu.cn/gnu/make/make-4.0.tar.gz
tar xf make-4.0.tar.gz 
cd make-4.0/
./configure 
make && make install

/usr/local/bin/make -v

mv /usr/bin/make{,-`make -v | awk 'NR==1{print $3}'`}
ln -sv /usr/local/bin/make /usr/bin/make

make -v
```
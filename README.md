# Shadowsocks

-----------------------------------------

yum -y install wget


---------------------------------------------
如果出现wget安装不了

Error: Cannot retrieve metalink for repository: epel. Please verify its path and try again

处理很简单，修改文件“/etc/yum.repos.d/epel.repo”， 将baseurl的注释取消， mirrorlist注释掉。即可。

----------------------------------------------


wget –no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/sixpence111/Shadowsocks/master/shadowsocks-all.sh

chmod +x shadowsocks-all.sh

./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log


-----------------------------------------


-----------------------------------------

wget "https://github.com/chiakge/Linux-NetSpeed/raw/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh

yum -y install ca-certificates


 ./tcp.sh
 
 -----------------------------------------
 
 ## 安卓APK点击这里<a href="https://github.com/sixpence111/Shadowsocks/raw/master/shadowsocks-nightly-4.1.8.apk">下载</a>
 
##  电脑exe点击这里<a href="https://github.com/sixpence111/Shadowsocks/raw/master/ShadowsocksR-4.7.0.rar">下载</a>

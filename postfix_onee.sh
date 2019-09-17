yum -y install lsof
yum -y install psmisc
firewall-cmd --permanent --add-port=25/tcp
firewall-cmd --permanent --add-port=110/tcp
firewall-cmd --reload


killall -9 yum
kill $(lsof -i:25|awk '{print $2}')

#创建用户:meimei
useradd $3
echo $4|passwd $3 --stdin

#卸载原有的软件 并 重新安装
yum -y remove   sendmail-devel dovecot postfix cyrus-sasl cyrus-sasl-plain  crypto-utils openssl-devel gcc make tcsh rpm-build wget telnet 
rm -rf /etc/postfix
yum -y install  sendmail-devel dovecot postfix cyrus-sasl cyrus-sasl-plain  crypto-utils openssl-devel gcc make tcsh rpm-build wget telnet 

#停掉sendmail服务，避免出现冲突
systemctl stop sendmail

#开始配置dovecot
echo "listen = *" >> /etc/dovecot/dovecot.conf
sed -i "s/#protocols = imap pop3 lmtp/protocols = imap pop3 lmtp/g" /etc/dovecot/dovecot.conf 
sed -i "s/#protocols = imap pop3 lmtp/protocols = imap pop3 lmtp/g" /etc/dovecot/dovecot.conf 
sed -i "s/#disable_plaintext_auth = yes/disable_plaintext_auth = yes/g" /etc/dovecot/conf.d/10-auth.conf 
sed -i "s/auth_mcooanisms = plain/auth_mcooanisms = plain login/g" /etc/dovecot/conf.d/10-auth.conf 

sed -i "s/#user/user = postfix/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/#group/group = postfix/g" /etc/dovecot/conf.d/10-auth.conf

sed -i "s/disable_plaintext_auth = yes/disable_plaintext_auth = no/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/ssl = required/ssl = no/g" /etc/dovecot/conf.d/10-ssl.conf

#开始配置postfix
cat > /etc/postfix/smtp_header_checks << EOF
/^Received:from/ IGNORE 
/^X-Mailer:/ IGNORE 
/^Received:.*\[(192\.168|172\.(1[6-9]|2[0-9]|3[01])|10)\./ IGNORE 
/^Received:.*\[(192\.168|172\.(1[6-9]|2[0-9]|3[01])|10)\./ IGNORE 
/^Received:.*\[127\.0\.0\.1/ IGNORE 
EOF

echo "smtp2           8080/tcp          mail">>/etc/services
echo "smtp2      inet  n       -       n       -       -       smtpd">>/etc/postfix/master.cf
sed -i "s/myhostname/#myhostname/g" /etc/postfix/main.cf
sed -i "s/mydomain/#mydomain/g" /etc/postfix/main.cf
sed -i "s/myorigin/#myorigin/g" /etc/postfix/main.cf
sed -i "s/inet_interfaces/#inet_interfaces/g" /etc/postfix/main.cf
sed -i "s/inet_protocols/#inet_protocols/g" /etc/postfix/main.cf
sed -i "s/mydestination/#mydestination/g" /etc/postfix/main.cf

cat > /etc/postfix/main.cf <<1122EEOOPP
queue_directory = /var/spool/postfix
command_directory = /usr/sbin 
daemon_directory = /usr/libexec/postfix 
data_directory = /var/lib/postfix 
mail_owner = postfix 
myhostname = $2
mydomain = $2
inet_protocols = all
inet_interfaces = all
mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain 
mail_name = Postfix - \$mydomain 
smtp_helo_name = \$myhostname 
smtpd_banner = \$myhostname ESMTP
alias_maps = hash:/etc/aliases 
alias_database = hash:/etc/aliases 
home_mailbox = Maildir/ 
debug_peer_level = 2 
sendmail_path = /usr/sbin/sendmail.postfix
newaliases_path = /usr/bin/newaliases.postfix 
mailq_path = /usr/bin/mailq.postfix 
setgid_group = postdrop 
html_directory = no 
readme_directory = /usr/share/doc/postfix-2.6.6/README_FILES 
master_service_disable = 
authorized_submit_users = root 
multi_instance_group = mta 
multi_instance_name = postfix 
multi_instance_enable = yes 
smtp_header_checks = regexp:/etc/postfix/smtp_header_checks 
smtpd_sasl_auth_enable = yes 
smtpd_recipient_restrictions = permit_sasl_authenticated,reject_unauth_destination 
broken_sasl_auth_clients = yes 
default_destination_rate_delay = 0s 
initial_destination_concurrency = 1 
default_destination_concurrency_limit = 1
bounce_queue_lifetime = 0s 
maximal_queue_lifetime = 0s 
message_size_limit = 157286400 
mailbox_size_limit = 157286400 
local_recipient_maps = 
unknown_local_recipient_reject_code = 550 
smtpd_milters = inet:localhost:20209 
non_smtpd_milters = \$smtpd_milters 
milter_protocol = 2 
milter_default_action = accept 
1122EEOOPP

#卸载原有的dkim_milter
rpm -e dkim-milter
rm -rf /etc/mail/dkim-milter
rm -rf /etc/sysconfig/dkim-milter

#下载安装dkim_milter
rpm -ivh http://software.virtualmin.com/gpl/centos/7.3.1611/x86_64/dkim-milter-2.8.3-8.el6.x86_64.rpm 

#开始配置dkim-milter
chown dkim-milter /etc/mail/dkim-milter/
chown dkim-milter /etc/mail/dkim-milter/keys
#!/bin/bash 
cd /etc/mail/dkim-milter/keys/ 
/usr/sbin/dkim-genkey -s default -d $2 
chown dkim-milter /etc/mail/dkim-milter/keys/keylist
chown dkim-milter /etc/mail/dkim-milter/keys/default.txt
chown dkim-milter /etc/mail/dkim-milter/keys/default.private

cat >> /etc/mail/dkim-milter/keys/keylist <<eof9998 
*@$2:$2:/etc/mail/dkim-milter/keys/default.private
eof9998

echo 'USER="dkim-milter"' >> /etc/sysconfig/dkim-milter
echo 'PORT="inet:20209@localhost"' >> /etc/sysconfig/dkim-milter
echo 'SELECTOR_NAME="default"' >> /etc/sysconfig/dkim-milter
echo "SIGNING_DOMAIN="$2"" >> /etc/sysconfig/dkim-milter
echo 'KEYFILE="/etc/mail/dkim-milter/keys/default.key"' >> /etc/sysconfig/dkim-milter
echo 'SIGNER=yes' >> /etc/sysconfig/dkim-milter
echo 'VERIFIER=yes' >> /etc/sysconfig/dkim-milter
echo 'CANON=simple' >> /etc/sysconfig/dkim-milter
echo 'SIGALG=rsa-sha256' >> /etc/sysconfig/dkim-milter
echo 'REJECTION="bad=r,dns=t,int=t,no=a,miss=r"' >> /etc/sysconfig/dkim-milter
echo 'EXTRA_ARGS="-h -l -D"' >> /etc/sysconfig/dkim-milter

echo 'Canonicalization simple' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'AutoRestart yes' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'AutoRestartRate 10/1h' >> /etc/mail/dkim-milter/dkim-filter.conf
echo "Domain "$2"" >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'SubDomains yes' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'Selector default' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'MTA MSA' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'KeyFile /etc/mail/dkim-milter/keys/default.key' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'Background yes' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'Socket inet:20209@localhost' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'X-Header yes' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'LogWhy yes' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'Userid dkim-milter' >> /etc/mail/dkim-milter/dkim-filter.conf
echo 'SignatureAlgorithm rsa-sha256' >> /etc/mail/dkim-milter/dkim-filter.conf

systemctl start saslauthd
systemctl stop dovecot
systemctl stop dkim-milter
systemctl stop postfix
systemctl start dovecot
systemctl start dkim-milter
systemctl start postfix


#开始上传dns记录
echo "####################"
echo "A info:"
echo "$(echo $2|cut -d"." -f 1)"
echo "$1"
echo "####################"
echo "####################"
echo "MX info:"
echo "$(echo $2|cut -d"." -f 1)"
echo "$(echo $2|cut -d"." -f 1)"
echo "$2"
echo "####################"
echo "####################"
echo "DMARC  info:"
echo "_dmarc.$(echo $2|cut -d"." -f 1)"
echo "v=DMARC1; p=none"
echo "####################"
echo "####################"
echo "SPF info:"
echo "$(echo $2|cut -d"." -f 1)"
echo "v=spf1 mx mx:$2 ip4:$1 ~all"
echo "####################"
echo "####################"
echo "$2 DNS DKIM info:"
echo "$(cat /etc/mail/dkim-milter/keys/default.txt|awk -F" IN" '{print$1}').$(echo $2|cut -d"." -f 1)"
echo "$(cat /etc/mail/dkim-milter/keys/default.txt|awk -F"\"" '{print$2}')"
echo "####################"
echo "####################"
echo "$2 DNS DKIM  private keys info:"
echo "DKIM  private keys file /etc/mail/dkim-milter/keys/default.private"
echo "$(cat /etc/mail/dkim-milter/keys/default.private)"
echo "####################"
echo ""
echo "$(echo $2|cut -d"." -f 1)  A       默认    "$1"    0       600"
echo "$(echo $2|cut -d"." -f 1)  MX      默认    "$2".   5       600"
echo "$(echo $2|cut -d"." -f 1)  TXT     默认    \"v=spf1 mx mx:$2 ip4:$1 ~all\"     0       600"
echo "_dmarc.$(echo $2|cut -d"." -f 1)  TXT     默认    \"v=DMARC1; p=none\"     0       600"
echo "$(cat /etc/mail/dkim-milter/keys/default.txt|awk -F" IN" '{print$1}').$(echo $2|cut -d"." -f 1)        TXT     默认     \"$(cat /etc/mail/dkim-milter/keys/default.txt|awk -F"\"" '{print$2}')\"   0       600"
echo ""  >>/opt/$1_$2.dns.info.txt
echo "$(echo $2|cut -d"." -f 1)  A       默认    "$1"    0       600" >>/opt/$1_$2.dns.info.txt
echo "$(echo $2|cut -d"." -f 1)  MX      默认    "$2".   5       600" >>/opt/$1_$2.dns.info.txt
echo "$(echo $2|cut -d"." -f 1)  TXT     默认    \"v=spf1 mx mx:$2 ip4:$1 ~all\"     0       600" >>/opt/$1_$2.dns.info.txt
echo "_dmarc.$(echo $2|cut -d"." -f 1)  TXT     默认    \"v=DMARC1; p=none\"     0       600">>/opt/$1_$2.dns.info.txt
echo "$(cat /etc/mail/dkim-milter/keys/default.txt|awk -F" IN" '{print$1}').$(echo $2|cut -d"." -f 1)        TXT     默认     \"$(cat /etc/mail/dkim-milter/keys/default.txt|awk -F"\"" '{print$2}')\"   0       600" >>/opt/$1_$2.dns.info.txt
echo "/usr/bin/dk-filter  -l -d $2  -p inet:8891@localhost -S default -s /etc/mail/dkim-milter/keys/default.private -A " >>  /root/sdkim
echo "/usr/bin/dk-filter  -l -d $2  -p inet:8891@localhost -S default -s /etc/mail/dkim-milter/keys/default.private -A " >> /etc/rc.local
DOMAINIDD=$(curl -m 20  -d "login_email=用户名&login_password=密码&format=json&lang=en&type=all" https://dnsapi.cn/Domain.List |grep -E -o "\{[^{}]*\}"  |grep -E -o "[^\,]*"|grep -B 13 $2|grep -w   id|grep -E -o ":[^\,]*"|grep -E -o "([1-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9])")
curl -m 20 -X POST https://dnsapi.cn/Record.Create -d 'login_email=用户名&login_password=密码&format=json&domain_id='$DOMAINIDD'&sub_domain=@&record_type=A&record_line=默认&value='$1''
curl -m 20 -X POST https://dnsapi.cn/Record.Create -d 'login_email=用户名&login_password=密码&format=json&domain_id='$DOMAINIDD'&sub_domain=@&record_type=MX&record_line=默认&value='$2'&mx=10'
curl -m 20 -X POST https://dnsapi.cn/Record.Create -d 'login_email=用户名&login_password=密码&format=json&domain_id='$DOMAINIDD'&sub_domain=_dmarc&record_type=TXT&record_line=默认&value='"v=DMARC1; p=none"''
curl -m 20 -X POST https://dnsapi.cn/Record.Create -d 'login_email=用户名&login_password=密码&format=json&domain_id='$DOMAINIDD'&sub_domain=@&record_type=TXT&record_line=默认&value='"v=spf1 mx mx:$2 ip4:$1 ~all"''
curl -m 20 -X POST https://dnsapi.cn/Record.Create -d 'login_email=用户名&login_password=密码&format=json&domain_id='$DOMAINIDD'&sub_domain='"$(cat /etc/mail/dkim-milter/keys/default.txt|awk -F" IN" '{print$1}').$(echo $2|cut -d"." -f 1)"'&record_type=TXT&record_line=默认&value='"$(cat /etc/mail/dkim-milter/keys/default.txt|awk -F"\"" '{print$2}')"''
echo "\nOKOKOKOKOK"

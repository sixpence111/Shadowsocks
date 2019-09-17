  
yum -y install lsof
yum -y install psmisc
firewall-cmd --permanent --add-port=25/tcp
firewall-cmd --permanent --add-port=110/tcp
firewall-cmd --reload


killall -9 yum
kill $(lsof -i:25|awk '{print $2}')

#创建用户:meimei
useradd $2
echo $3|passwd $2 --stdin

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
myhostname = $1
mydomain = $1
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
/usr/sbin/dkim-genkey -s default -d $1 
chown dkim-milter /etc/mail/dkim-milter/keys/keylist
chown dkim-milter /etc/mail/dkim-milter/keys/default.txt
chown dkim-milter /etc/mail/dkim-milter/keys/default.private

cat >> /etc/mail/dkim-milter/keys/keylist <<eof9998 
*@$1:$1:/etc/mail/dkim-milter/keys/default.private
eof9998

echo 'USER="dkim-milter"' >> /etc/sysconfig/dkim-milter
echo 'PORT="inet:20209@localhost"' >> /etc/sysconfig/dkim-milter
echo 'SELECTOR_NAME="default"' >> /etc/sysconfig/dkim-milter
echo "SIGNING_DOMAIN="$1"" >> /etc/sysconfig/dkim-milter
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
echo "Domain "$1"" >> /etc/mail/dkim-milter/dkim-filter.conf
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

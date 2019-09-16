killall -9 yum

for i in `seq 1 1` 
do
useradd "$7"
echo "$8"|passwd "$7" --stdin
done

yum -y remove   sendmail-devel dovecot postfix cyrus-sasl cyrus-sasl-plain  crypto-utils openssl-devel gcc make tcsh rpm-build wget telnet 
yum -y install  sendmail-devel dovecot postfix cyrus-sasl cyrus-sasl-plain  crypto-utils openssl-devel gcc make tcsh rpm-build wget telnet 
rpm -ivh http://software.virtualmin.com/gpl/centos/7.3.1611/x86_64/dkim-milter-2.8.3-8.el6.x86_64.rpm 
/etc/init.d/sendmail stop 
chkconfig sendmail off 
service saslauthd restart 
chkconfig saslauthd on 
chkconfig iptables off 
service postfix stop 
chkconfig postfix off 
service iptables stop 
chkconfig iptables off 
chkconfig dovecot on

echo "listen = *" >> /etc/dovecot/dovecot.conf
echo "auth_mechanisms = plain login" >> /etc/dovecot/conf.d/10-auth.conf
echo "mail_location = maildir:~/Maildir" >> /etc/dovecot/conf.d/10-mail.conf

echo "smtp2           8080/tcp          mail">>/etc/services
echo "smtp2      inet  n       -       n       -       -       smtpd">>/etc/postfix/master.cf

sed -i "s/#protocols = imap pop3 lmtp/protocols = imap pop3 lmtp/g" /etc/dovecot/dovecot.conf 
echo "mail_location = maildir:~/Maildir" >> /etc/dovecot/conf.d/10-mail.conf 
sed -i "s/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g" /etc/dovecot/conf.d/10-auth.conf 
sed -i "s/auth_mcooanisms = plain/auth_mcooanisms = plain login/g" /etc/dovecot/conf.d/10-auth.conf 
sed -i "s/#mail_max_userip_connections = 3/mail_max_userip_connections = 128/g" /etc/dovecot/conf.d/20-pop3.conf 
sed -i "s/#mail_max_userip_connections = 10/mail_max_userip_connections = 128/g" /etc/dovecot/conf.d/20-imap.conf 
mkdir /var/run/dk-milter/ -p 
chmod -R 777 /var/run/dk-milter/ 
mkdir -p /var/milter/ 
chmod -R 777 /var/milter/ 
mkdir -p /var/milter/ 
chmod -R 777 /var/milter/ 
echo > /etc/aliases 
postalias /etc/aliases 

cat > /etc/postfix/smtp_header_checks << EOF
/^Received: .*/     IGNORE
/^X-Originating-IP:/    IGNORE
EOF


mkdir -p /etc/postfix-0
mkdir -p /var/spool/postfix-0

cat > /etc/postfix-0/main.cf <<1122EEOOPP
queue_directory = /var/spool/postfix-0
command_directory = /usr/sbin 
daemon_directory = /usr/libexec/postfix 
data_directory = /var/lib/postfix-0 
mail_owner = postfix 
myhostname = $3
mydomain = $3
inet_protocols = ipv4
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
multi_instance_name = postfix-0 
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
smtpd_milters = inet:127.0.0.1:8888 
non_smtpd_milters = \$smtpd_milters 
milter_protocol = 2 
milter_default_action = accept 
1122EEOOPP


for i in `seq 1 1`
do
mkdir -p /var/spool/postfix-"$i" 
mkdir -p /var/lib/postfix-"$i" 
chown -R postfix:postfix /var/lib/postfix-"$i"/  
mkdir -p /etc/postfix-"$i"/ 
yes|cp -avrp /etc/postfix/master.cf /etc/postfix-"$i" 
yes|cp -avrp /etc/postfix-0/main.cf /etc/postfix-"$i" 
done



yes|cp /etc/postfix-0/main.cf /etc/postfix-"\$1"/main.cf 
sed -i "s/mydomain = demo.com/mydomain = "\$3"/g" /etc/postfix-"\$1"/main.cf 
sed -i "s/myhostname = mail.demo.com/myhostname = "\$4"/g" /etc/postfix-"\$1"/main.cf 
sed -i "s/inet_interfaces = 88.88.88.88/inet_interfaces = "\$2"/g" /etc/postfix-"\$1"/main.cf 
sed -i "s/postfix-0/postfix-"\$1"/g" /etc/postfix-"\$1"/main.cf 
sed -i "s/inet:127.0.0.1:8888/inet:127.0.0.1:630"\$5"/g" /etc/postfix-"\$1"/main.cf


for i in `seq 1 1` 
do 
echo "postfix -c /etc/postfix-"$i" start" >> /root/startp 
echo "postfix -c /etc/postfix-"$i" start" >> /etc/rc.local 
echo "postfix -c /etc/postfix-"$i" stop" >> /root/stopp 
done

#!/bin/bash 
cd /etc/mail/dkim-milter/keys/ 
/usr/sbin/dkim-genkey -s $5 -d $3 
ls -l $5.txt $5.private 
cat >> /etc/mail/dkim-milter/keys/keylist <<eof9998 
*@$3:$3:/etc/mail/dkim-milter/keys/$5.private 
eof9998
 
cat >> /etc/mail/dkim-milter/$5-filter.conf <<eof9998 
AutoRestart yes 
Domain $3 
Selector $5 
#Socket inet:630$1@localhost 
Socket local:/var/run/dkim-milter/$5-milter.sock 
Syslog Yes 
X-Header Yes 
KeyFile /etc/mail/dkim-milter/keys/$5.private 
KeyList /etc/mail/dkim-milter/keys/keylist 
eof9998

sh /root/startp 
service dovecot restart

yum -y remove   sendmail-devel dovecot postfix cyrus-sasl cyrus-sasl-plain  crypto-utils openssl-devel gcc make tcsh rpm-build wget telnet 
yum -y install  sendmail-devel dovecot postfix cyrus-sasl cyrus-sasl-plain  crypto-utils openssl-devel gcc make tcsh rpm-build wget telnet 
rpm -ivh http://software.virtualmin.com/gpl/centos/7.3.1611/x86_64/dkim-milter-2.8.3-8.el6.x86_64.rpm 
/etc/init.d/sendmail stop 
chkconfig sendmail off 
service saslauthd restart 
chkconfig saslauthd on 
chkconfig iptables off 
service postfix stop 
chkconfig postfix off 
service iptables stop 
chkconfig iptables off 
chkconfig dovecot on

echo "listen = *" >> /etc/dovecot/dovecot.conf
echo "auth_mechanisms = plain login" >> /etc/dovecot/conf.d/10-auth.conf
echo "mail_location = maildir:~/Maildir" >> /etc/dovecot/conf.d/10-mail.conf

echo "smtp2           8080/tcp          mail">>/etc/services
echo "smtp2      inet  n       -       n       -       -       smtpd">>/etc/postfix/master.cf

sed -i "s/#protocols = imap pop3 lmtp/protocols = imap pop3 lmtp/g" /etc/dovecot/dovecot.conf 
echo "mail_location = maildir:~/Maildir" >> /etc/dovecot/conf.d/10-mail.conf 
sed -i "s/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g" /etc/dovecot/conf.d/10-auth.conf 
sed -i "s/auth_mcooanisms = plain/auth_mcooanisms = plain login/g" /etc/dovecot/conf.d/10-auth.conf 
sed -i "s/#mail_max_userip_connections = 3/mail_max_userip_connections = 128/g" /etc/dovecot/conf.d/20-pop3.conf 
sed -i "s/#mail_max_userip_connections = 10/mail_max_userip_connections = 128/g" /etc/dovecot/conf.d/20-imap.conf 
mkdir /var/run/dk-milter/ -p 
chmod -R 777 /var/run/dk-milter/ 
mkdir -p /var/milter/ 
chmod -R 777 /var/milter/ 
mkdir -p /var/milter/ 
chmod -R 777 /var/milter/ 
echo > /etc/aliases 
postalias /etc/aliases 

cat > /etc/postfix/smtp_header_checks << EOF
/^Received:from/ IGNORE 
/^X-Mailer:/ IGNORE 
/^Received:.*\[(192\.168|172\.(1[6-9]|2[0-9]|3[01])|10)\./ IGNORE 
/^Received:.*\[(192\.168|172\.(1[6-9]|2[0-9]|3[01])|10)\./ IGNORE 
/^Received:.*\[127\.0\.0\.1/ IGNORE 
EOF


mkdir -p /etc/postfix-0
mkdir -p /var/spool/postfix-0

cat > /etc/postfix-0/main.cf <<1122EEOOPP
queue_directory = /var/spool/postfix-0
command_directory = /usr/sbin 
daemon_directory = /usr/libexec/postfix 
data_directory = /var/lib/postfix-0 
mail_owner = postfix 
myhostname = $3
mydomain = $3
inet_protocols = ipv4
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
multi_instance_name = postfix-0 
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
smtpd_milters = inet:127.0.0.1:8888 
non_smtpd_milters = \$smtpd_milters 
milter_protocol = 2 
milter_default_action = accept 
1122EEOOPP


for i in `seq 1 1`
do
mkdir -p /var/spool/postfix-"$i" 
mkdir -p /var/lib/postfix-"$i" 
chown -R postfix:postfix /var/lib/postfix-"$i"/  
mkdir -p /etc/postfix-"$i"/ 
yes|cp -avrp /etc/postfix/master.cf /etc/postfix-"$i" 
yes|cp -avrp /etc/postfix-0/main.cf /etc/postfix-"$i" 
done



yes|cp /etc/postfix-0/main.cf /etc/postfix-"\$1"/main.cf 
sed -i "s/mydomain = demo.com/mydomain = "\$3"/g" /etc/postfix-"\$1"/main.cf 
sed -i "s/myhostname = mail.demo.com/myhostname = "\$4"/g" /etc/postfix-"\$1"/main.cf 
sed -i "s/inet_interfaces = 88.88.88.88/inet_interfaces = "\$2"/g" /etc/postfix-"\$1"/main.cf 
sed -i "s/postfix-0/postfix-"\$1"/g" /etc/postfix-"\$1"/main.cf 
sed -i "s/inet:127.0.0.1:8888/inet:127.0.0.1:630"\$5"/g" /etc/postfix-"\$1"/main.cf


for i in `seq 1 1` 
do 
echo "postfix -c /etc/postfix-"$i" start" >> /root/startp 
echo "postfix -c /etc/postfix-"$i" start" >> /etc/rc.local 
echo "postfix -c /etc/postfix-"$i" stop" >> /root/stopp 
done

#!/bin/bash 
cd /etc/mail/dkim-milter/keys/ 
/usr/sbin/dkim-genkey -s $5 -d $3 
ls -l $5.txt $5.private 
cat >> /etc/mail/dkim-milter/keys/keylist <<eof9998 
*@$3:$3:/etc/mail/dkim-milter/keys/$5.private 
eof9998
 
cat >> /etc/mail/dkim-milter/$5-filter.conf <<eof9998 
AutoRestart yes 
Domain $3 
Selector $5 
#Socket inet:630$1@localhost 
Socket local:/var/run/dkim-milter/$5-milter.sock 
Syslog Yes 
X-Header Yes 
KeyFile /etc/mail/dkim-milter/keys/$5.private 
KeyList /etc/mail/dkim-milter/keys/keylist 
eof9998

sh /root/startp 
service dovecot restart
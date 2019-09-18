firewall-cmd --permanent --add-port=25/tcp

firewall-cmd --permanent --add-port=110/tcp

firewall-cmd --reload

#移除sendmail
yum remove sendmail



yum -y install vim

sed -i "s/#myhostname = host.domain.tld/myhostname = mail.$1/g" /etc/postfix/main.cf
sed -i "s/#mydomain = domain.tld/mydomain = $1/g" /etc/postfix/main.cf
sed -i "s/#myorigin = \$mydomain/myorigin = \$mydomain/g" /etc/postfix/main.cf
sed -i "s/inet_interfaces = localhost/inet_interfaces = all/g" /etc/postfix/main.cf
sed -i "s/mydestination = \$myhostname, localhost.\$mydomain, localhost/mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain/g" /etc/postfix/main.cf
sed -i "s/#mynetworks = 168.100.189.0\/28, 127.0.0.0\/8/mynetworks = 168.100.189.0\/28, 127.0.0.0\/8/g" /etc/postfix/main.cf
sed -i "s/#home_mailbox = Maildir\//home_mailbox = Maildir\//g" /etc/postfix/main.cf
sed -i "s/#smtpd_banner = \$myhostname ESMTP \$mail_name (\$mail_version)/smtpd_banner = \$myhostname ESMTP/g" /etc/postfix/main.cf

echo 'message_size_limit = 10485760' >> /etc/postfix/main.cf
echo 'mailbox_size_limit = 1073741824' >> /etc/postfix/main.cf
echo 'smtpd_sasl_type = dovecot' >> /etc/postfix/main.cf
echo 'smtpd_sasl_path = private/auth' >> /etc/postfix/main.cf
echo 'smtpd_sasl_auth_enable = yes' >> /etc/postfix/main.cf
echo 'smtpd_sasl_security_options = noanonymous' >> /etc/postfix/main.cf
echo 'smtpd_sasl_local_domain = $myhostname' >> /etc/postfix/main.cf
echo 'smtpd_recipient_restrictions = permit_mynetworks,permit_auth_destination,permit_sasl_authenticated,reject' >> /etc/postfix/main.cf

#echo 'smtpd_milters = inet:127.0.0.1:8888' >> /etc/postfix/main.cf
#echo 'non_smtpd_milters = $smtpd_milters' >> /etc/postfix/main.cf
#echo 'milter_protocol = 2' >> /etc/postfix/main.cf
#echo 'milter_default_action = accept' >> /etc/postfix/main.cf






cat > /etc/postfix/main.cf <<1122EEOOPP
command_directory = /usr/sbin 
daemon_directory = /usr/libexec/postfix 
mail_owner = postfix 
myhostname = $1
mydomain = $1
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









systemctl  restart  postfix

systemctl  enable  postfix

yum -y install dovecot




sed -i "s/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/auth_mechanisms = plain/auth_mechanisms = plain login/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/#mail_location =/mail_location = maildir:~\/Maildir/g" /etc/dovecot/conf.d/10-mail.conf

echo "listen = *" >> /etc/dovecot/dovecot.conf
echo "smtp2           8080/tcp          mail">>/etc/services
echo "smtp2      inet  n       -       n       -       -       smtpd">>/etc/postfix/master.cf

sed -i "s/#protocols = imap pop3 lmtp/protocols = imap pop3 lmtp/g" /etc/dovecot/dovecot.conf 


sed -i "s/#unix_listener \/var\/spool\/postfix\/private\/auth {/unix_listener \/var\/spool\/postfix\/private\/auth { \n mode = 0666 \n user = postfix \n group = postfix \n }/g" /etc/dovecot/conf.d/10-master.conf


sed -i "s/ssl = required/ssl = no/g" /etc/dovecot/conf.d/10-ssl.conf 


systemctl restart dovecot
systemctl enable dovecot

cat > /etc/postfix/smtp_header_checks << EOF
/^Received: .*/     IGNORE
/^X-Originating-IP:/    IGNORE
/^Received:from/ IGNORE 
/^X-Mailer:/ IGNORE
/^Received:.*\[(192\.168|172\.(1[6-9]|2[0-9]|3[01])|10)\./ IGNORE
/^Received:.*\[(192\.168|172\.(1[6-9]|2[0-9]|3[01])|10)\./ IGNORE
/^Received:.*\[127\.0\.0\.1/ IGNORE
EOF

useradd $2
echo $3|passwd $2 --stdin


alternatives --config mta


echo "\n OKOKOKOKOK"









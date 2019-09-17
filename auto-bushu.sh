firewall-cmd --permanent --add-port=25/tcp

firewall-cmd --permanent --add-port=110/tcp

firewall-cmd --reload

#移除sendmail
yum remove sendmail

alternatives --config mta

yum -y install vim

sed -i "s/#myhostname = host.domain.tld/myhostname = mail.$1/g" /etc/postfix/main.cf
sed -i "s/#mydomain = domain.tld/mydomain = $1/g" /etc/postfix/main.cf
sed -i "s/#myorigin = \$mydomain/myorigin = \$mydomain/g" /etc/postfix/main.cf
sed -i "s/inet_interfaces = localhost/inet_interfaces = all/g" /etc/postfix/main.cf
sed -i "s/mydestination = \$myhostname, localhost.\$mydomain, localhost/mydestination = \$myhostname, localhost.\$mydomain, localhost, \$mydomain/g" /etc/postfix/main.cf
sed -i "s/#mynetworks = 168.100.189.0\/28, 127.0.0.0\/8/mynetworks = 168.100.189.0\/28, 127.0.0.0\/8/g" /etc/postfix/main.cf
sed -i "s/#home_mailbox = Maildir/home_mailbox = Maildir\//g" /etc/postfix/main.cf
sed -i "s/#smtpd_banner = \$myhostname ESMTP \$mail_name (\$mail_version)/smtpd_banner = \$myhostname ESMTP/g" /etc/postfix/main.cf

echo 'message_size_limit = 10485760' >> /etc/postfix/main.cf
echo 'mailbox_size_limit = 1073741824' >> /etc/postfix/main.cf
echo 'smtpd_sasl_type = dovecot' >> /etc/postfix/main.cf
echo 'smtpd_sasl_path = private/auth' >> /etc/postfix/main.cf
echo 'smtpd_sasl_auth_enable = yes' >> /etc/postfix/main.cf
echo 'smtpd_sasl_security_options = noanonymous' >> /etc/postfix/main.cf
echo 'smtpd_sasl_local_domain = $myhostname' >> /etc/postfix/main.cf
echo 'smtpd_recipient_restrictions = permit_mynetworks,permit_auth_destination,permit_sasl_authenticated,reject' >> /etc/postfix/main.cf




systemctl  restart  postfix

systemctl  enable  postfix

yum -y install dovecot




sed -i "s/#disable_plaintext_auth = yes/disable_plaintext_auth = no/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/auth_mechanisms = plain/auth_mechanisms = plain login/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/#mail_location =/mail_location = maildir:~\/Maildir/g" /etc/dovecot/conf.d/10-mail.conf




sed -i "s/#unix_listener \/var\/spool\/postfix\/private\/auth {/unix_listener \/var\/spool\/postfix\/private\/auth { \n mode = 0666 \n user = postfix \n group = postfix \n }/g" /etc/dovecot/conf.d/10-master.conf


sed -i "s/ssl = required/ssl = no/g" /etc/dovecot/conf.d/10-ssl.conf 


systemctl restart dovecot
systemctl enable dovecot

sed -i "s/cleanup   unix  n       -       n       -       0       cleanup/cleanup   unix  n       -       n       -       0       cleanup -o header_checks=pcre:\/etc\/postfix\/header_checks/g" /etc/postfix/master.cf
echo '/^Received:/IGNORE' >> /etc/postfix/header_checks
service postfix restart

useradd $2
echo $3|passwd $2 --stdin


echo "\n OKOKOKOKOK"









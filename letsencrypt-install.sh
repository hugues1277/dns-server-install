#!/bin/bash
#================================================================
# Apache config and Lets Encrypt install with renewal
# @author fedwiiix
# Usage: ./letsencript.sh mon-site.fr mon-site
# More info: https://github.com/fedwiiix
#================================================================

# --------------------------- check sudo
if [ $USER != "root" -o $UID != 0 ]
then
  echo "need sudo !"
  exit 1
fi

if [ -z $1 ] || [ -z $2 ] || [ $1 = "-h" ]; then
	echo " - you need add domain and site name as argument: 
	sudo ./letsencript.sh mon-site.fr mon-site
	sudo ./letsencript.sh mon-site.hello.fr mon-site
	
- Check if your domain targets your server address
	"
	exit
fi

SITE_NAME=$2
DOMAIN=$1

mkdir -p /var/www/$SITE_NAME
# init apache
sudo echo "
<VirtualHost *:80>
    ServerName  $DOMAIN
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/$SITE_NAME
    ErrorLog ${APACHE_LOG_DIR}/$SITE_NAME-error.log
    CustomLog ${APACHE_LOG_DIR}/$SITE_NAME-access.log combined
</VirtualHost>" > /etc/apache2/sites-available/test.conf

sudo a2ensite $SITE_NAME.conf
echo " - to disable site, use: sudo a2dissite $SITE_NAME.conf"
sudo service apache2 reload

# check if letsencrypt exist
cd /opt
if [ ! -d "letsencrypt" ]; 
then	
	echo " - install letsencrypt"
	git clone https://github.com/letsencrypt/letsencrypt
fi

cd letsencrypt

echo '
 - You can add your domain name and after, select option 2
'

./certbot-auto -d $DOMAIN

# -> manual renew ---------------------------------------------------------------------
#/opt/letsencrypt/letsencrypt-auto certonly --apache --renew-by-default --domains sjtm.fr --expand -d evangelisation.sjtm.fr -d lifebook.sjtm.fr -d preview.sjtm.fr -d lifebookapi.sjtm.fr

sudo apt install bc

sudo echo '#!/bin/bash
#================================================================
# Lets Encrypt renewal script for Apache on Ubuntu/Debian
# @author Erika Heidi<erika@do.co>
# Usage: ./le-renew.sh [base-domain-name]
# More info: http://do.co/1mbVihI
#================================================================
domain=$1
le_path="/opt/letsencrypt"
le_conf="/etc/letsencrypt"
exp_limit=30;

if [ -z "$domain" ] ; then
        echo "[ERROR] you must provide the domain name for the certificate renewal."
        exit 1;
fi

cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"

if [ ! -f $cert_file ]; then
	echo "[ERROR] certificate file not found for domain $domain."
	exit 1;
fi

exp=$(date -d "`openssl x509 -in $cert_file -text -noout|grep "Not After"|cut -c 25-`" +%s)
datenow=$(date -d "now" +%s)
days_exp=$(echo \( $exp - $datenow \) / 86400 |bc)

echo "Checking expiration date for $domain..."

if [ "$days_exp" -gt "$exp_limit" ] ; then
	echo "The certificate is up to date, no need for renewal ($days_exp days left)."
	exit 0;
else
	echo "The certificate for $domain is about to expire soon. Starting renewal request..."

        # renewal domain command /// add yours domain names -d name1 -d name2
	"$le_path"/letsencrypt-auto certonly --apache --renew-by-default -d $domain
	echo "Restarting Apache..."
	/usr/sbin/service apache2 reload
	echo "Renewal process finished for domain $domain"
	exit 0;
fi
' > /usr/local/sbin/le-renew

sudo chmod 755 /usr/local/sbin/le-renew

# or default but buged
# sudo curl -L -o /usr/local/sbin/le-renew http://do.co/le-renew
#sudo le-renew sjtm.fr

FILE="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
if sudo test -f "$FILE"; then
echo "

Your ssl is installed
 - To renew automatically your ssl certificate, edit crontab

sudo crontab -e
0 3 * * * /usr/local/sbin/le-renew $DOMAIN >> /var/log/le-renew.log
"
else
	echo " - a error ocured"
fi

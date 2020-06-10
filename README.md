# dns-server-install
It's apache config and let's encript install automatisation

befor all, check if your domain targets your server address

run
``` sh
sudo ./dns-server-install.sh mon-site.fr mon-site
sudo ./dns-server-install.sh mon-site.hello.fr mon-site
```

What is it doing ?
* this script create folder /var/www/mon-site
* add htaccess
* create apache site config file
* enable site
* reload apache > now, the http website is efficient
* install let's encript if isn't installed
* run let's encript for your domain name
* install auto renewal script
* check installation

at the end, you must edit crontab to allow auto renew

``` sh
sudo crontab -e
0 3 * * * /usr/local/sbin/le-renew $DOMAIN >> /var/log/le-renew.log
```

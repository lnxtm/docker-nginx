#!/bin/sh
# conf files
80_CONF=/etc/nginx/sites-enabled/http
443_CONF=/etc/nginx/sites-enabled/https

# base test and set defauln env
WWW_FQDN=www.${FQDN}

# functions ###
setup_code () {
	if [ "$CODE" = "external" ]; then
		echo "external code mode"
	else
		mkdir /code
		if [ "$BRANCH" = "master" ]; then
			cd /code && git init && git remote add origin https://$G_USER:$G_PASS@$CODE
		    cd /code && git pull origin master && git branch --set-upstream-to=origin/master master
		else
			cd /code && git init && git remote add origin https://$G_USER:$G_PASS@$CODE
		    cd /code && git pull origin master && git branch --set-upstream-to=origin/master master
		    cd /code && git checkout -b ${BRANCH}
		fi
		echo "*/15  *  *  *  * /pullnpush.sh" | crontab -u root - 
	fi
}
setup_nginx_le () {
	# make dhparams
	if [ ! -f /etc/nginx/ssl/dhparams.pem ]; then
    	echo "make dhparams"
    	cd /etc/nginx/ssl
    	openssl dhparam -out dhparams.pem 2048
    	chmod 600 dhparams.pem
	fi
	if [ ! -f /http ]; then
		mv /http /etc/nginx/sites-enabled/
		sed -i "s|FQDN|${FQDN}|g" ${80_CONF}
		sed -i "s|WWW_FQDN|${WWW_FQDN}|g" ${80_CONF}
		sed -i "s|HTTP|${HTTP}|g" ${80_CONF}
	else
		sed -i "s|FQDN|${FQDN}|g" ${80_CONF}
		sed -i "s|WWW_FQDN|${WWW_FQDN}|g" ${80_CONF}
		sed -i "s|HTTP|${HTTP}|g" ${80_CONF}
	fi
	if [ ! -f /https ]; then
		sed -i "s|FQDN|${FQDN}|g" /https
		sed -i "s|WWW_FQDN|${WWW_FQDN}|g" /https
		sed -i "s|HTTPS|${HTTPS}|g" /https
	else
		sed -i "s|FQDN|${FQDN}|g" ${443_CONF}
		sed -i "s|WWW_FQDN|${WWW_FQDN}|g" ${443_CONF}
		sed -i "s|HTTPS|${HTTPS}|g" ${443_CONF}
	fi
	(
		sleep 5 # give nginx time to start
 		while :
 		do
 		if [ ! -f ${443_CONF} ]; then
 			mv ${443_CONF} /
 			nginx -s reload
 			/le.sh && mv /https ${443_CONF}
 			nginx -s reload
 			sleep 60d
 		else
 			/le.sh && mv /https ${443_CONF}
 			nginx -s reload
 			sleep 60d
 		fi
 		done
	) &
}
# - setup
if [ "$FQDN" = "example.com" ]; then
	mv /localhost /etc/nginx/sites-enabled/
else
	setup_code
	setup_nginx_le
fi
# - run
/usr/bin/supervisord
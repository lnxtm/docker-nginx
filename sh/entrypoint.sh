#!/bin/sh

# base test and set defauln env
WWW_FQDN=www.${FQDN}

# functions ###
setup_code () {
	if [ "$REPO" = "external" ]; then
		echo "external code mode"
	else
		if ! [ -d /code/.git ]; then
			/pullnpush.sh
		else
		mkdir /code
			if [ "$BRANCH" = "master" ]; then
				cd /code && git init && git remote add origin https://$GIT_USER:$GIT_PASS@$REPO
		    	cd /code && git pull origin master && git branch --set-upstream-to=origin/master master
		    	export -n GIT_PASS
			else
				cd /code && git init && git remote add origin https://$GIT_USER:$GIT_PASS@$REPO
		    	cd /code && git pull origin master && git branch --set-upstream-to=origin/master master
		    	cd /code && git checkout -b ${BRANCH}
		    	export -n GIT_PASS
			fi
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
		sed -i "s|FQDN|${FQDN}|g" /etc/nginx/sites-enabled/http
		sed -i "s|WWW_FQDN|${WWW_FQDN}|g" /etc/nginx/sites-enabled/http
		sed -i "s|HTTP|${HTTP}|g" /etc/nginx/sites-enabled/http
	else
		sed -i "s|FQDN|${FQDN}|g" /etc/nginx/sites-enabled/http
		sed -i "s|WWW_FQDN|${WWW_FQDN}|g" /etc/nginx/sites-enabled/http
		sed -i "s|HTTP|${HTTP}|g" /etc/nginx/sites-enabled/http
	fi
	if [ ! -f /https ]; then
		sed -i "s|FQDN|${FQDN}|g" /https
		sed -i "s|WWW_FQDN|${WWW_FQDN}|g" /https
		sed -i "s|HTTPS|${HTTPS}|g" /https
	else
		sed -i "s|FQDN|${FQDN}|g" $/etc/nginx/sites-enabled/https
		sed -i "s|WWW_FQDN|${WWW_FQDN}|g" $/etc/nginx/sites-enabled/https
		sed -i "s|HTTPS|${HTTPS}|g" $/etc/nginx/sites-enabled/https
	fi
	(
		sleep 5 # give nginx time to start
 		while :
 		do
 		if [ ! -f $/etc/nginx/sites-enabled/https ]; then
 			mv $/etc/nginx/sites-enabled/https /
 			nginx -s reload
 			/le.sh && mv /https $/etc/nginx/sites-enabled/https
 			nginx -s reload
 			sleep 60d
 		else
 			/le.sh && mv /https $/etc/nginx/sites-enabled/https
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
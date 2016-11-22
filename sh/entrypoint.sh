#!/bin/sh

# functions ###
setup_code () {
	if [ "$REPO" = "external" ]; then
		echo "external code mode"
	else
		if ! [ -d /code/.git ]; then
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
			echo "*/15  *  *  *  * /pullnpush.sh" | crontab -u root - 
		else
			/pullnpush.sh
		fi
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
	sed -i "s|FQDN|${FQDN}|g" /http
	sed -i "s|WWW_FQDN|${WWW_FQDN}|g" /http
	sed -i "s|HTTP|${HTTP}|g" /http
	sed -i "s|FQDN|${FQDN}|g" $/https
	sed -i "s|WWW_FQDN|${WWW_FQDN}|g" $/https
	sed -i "s|HTTPS|${HTTPS}|g" $/https
	(
 		while :
 		do
 		if [ ! -f /etc/nginx/sites-enabled/https ]; then
 			if [ ! -f /etc/nginx/sites-enabled/http ]; then
	 			mv /http /etc/nginx/sites-enabled/http
	 		fi
 			nginx -s reload
 			sleep 3
 			/le.sh && mv /https /etc/nginx/sites-enabled/https
 			nginx -s reload
 			sleep 60d
 		else
 			if [ ! -f /etc/nginx/sites-enabled/http ]; then
	 			mv /http /etc/nginx/sites-enabled/http
	 		fi
 			mv /etc/nginx/sites-enabled/https /https 
			nginx -s reload
 			sleep 3
 			/le.sh && mv /https /etc/nginx/sites-enabled/https
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
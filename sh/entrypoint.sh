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
			else
				cd /code && git init && git remote add origin https://$GIT_USER:$GIT_PASS@$REPO
		    	cd /code && git pull origin master && git branch --set-upstream-to=origin/master master
		    	cd /code && git checkout -b ${BRANCH}
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
	sed -i "s|WWW|${WWW_FQDN}|g" /http
	sed -i "s|HTTP|${HTTP}|g" /http
	sed -i "s|FQDN|${FQDN}|g" /https
	sed -i "s|WWW|${WWW_FQDN}|g" /https
	sed -i "s|HTTPS|${HTTPS}|g" /https
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

setup_php_fpm () {
	sed -i "s|PHP_MEMORY|${PHP_MEMORY}|g" /etc/php/7.0/fpm/php.ini
	sed -i "s|PHP_MEMORY|${PHP_MEMORY}|g" /etc/php/7.0/fpm/pool.d/pool.conf
	sed -i "s|PHP_PM_MAX|${PHP_PM_MAX}|g" /etc/php/7.0/fpm/pool.d/pool.conf
	sed -i "s|PHP_PM_START|${PHP_PM_START}|g" /etc/php/7.0/fpm/pool.d/pool.conf
	sed -i "s|PHP_PM_SPARE_MIN|${PHP_PM_SPARE_MIN}|g" /etc/php/7.0/fpm/pool.d/pool.conf
	sed -i "s|PHP_PM_SPARE_MAX|${PHP_PM_SPARE_MAX}|g" /etc/php/7.0/fpm/pool.d/pool.conf
}

# - setup
if [ "$FQDN" = "example.com" ]; then
	mv /localhost /etc/nginx/sites-enabled/
else
	if [ "$FPM_ENABLE" = "true" ]; then
		setup_php_fpm
	fi
	setup_code
	setup_nginx_le
fi
export GIT_PASS=erased
# - run
/usr/bin/supervisord
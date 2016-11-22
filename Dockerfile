FROM lnxtm/docker-cron
MAINTAINER Alexander Shevchenko <kudato@me.com>
#
ENV HTTP 80
ENV HTTPS 443
#
ENV FQDN example.com
ENV W_FQDN www.example.com
#
ADD conf/nginx.conf /etc/nginx/nginx.conf
ADD conf/https /https
ADD conf/http /http
ADD conf/localhost /localhost
#
ADD sh/le.sh /le.sh
ADD sh/pullnpush.sh /pullnpush.sh
ADD sh/entrypoint.sh /entrypoint.sh
#
RUN chmod +x /*.sh
#
RUN apt-get install -y nginx-full && \
    echo "[program:nginx]" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "command = /usr/sbin/nginx" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "user = root" >> /etc/supervisor/conf.d/supervisord.conf && \
	echo "autostart = true" >> /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /etc/nginx/ssl && mkdir -p /usr/share/nginx/html
# - >
CMD ["/entrypoint.sh"]
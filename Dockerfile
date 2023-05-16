FROM alpine:3.16

#latest php-fpm stable for Alpine 3.16
# using sed to add www-data coz nginx runs
# under the username www-data
RUN apk update && \
	apk add --no-cache php8-fpm=8.0.28-r0 php8-phar less mysql-client sudo curl php8-mysqli php8-bcmath php8-bz2 php8-ctype php8-curl php8-exif php8-fileinfo php8-gd php8-gettext php8-gmp php8-iconv php8-intl php8-imap php8-json php8-ldap php8-mbstring php8-pecl-apcu php8-pecl-igbinary php8-pecl-imagick php8-pecl-mcrypt php8-pecl-memcached php8-pecl-redis php8-pdo php8-pdo_mysql php8-opcache php8-pdo_pgsql php8-pgsql php8-pcntl php8-posix php8-simplexml php8-sysvsem php8-xml php8-xmlreader php8-xmlwriter php8-zip && \
	sed -i "s#listen = 127.0.0.1:9000#listen = 0.0.0.0:9000#g" /etc/php8/php-fpm.d/www.conf && \
	sed -i "s#^user = nobody#user = www-data#g" /etc/php8/php-fpm.d/www.conf && \
	sed -i "s#^group = nobody#group = www-data#g" /etc/php8/php-fpm.d/www.conf && \
	sed -i "s#^;listen.owner = nobody#listen.owner = www-data#g" /etc/php8/php-fpm.d/www.conf && \
	sed -i "s#^;listen.group = nobody#listen.group = www-data#g" /etc/php8/php-fpm.d/www.conf && \
	sed -i "s#^;listen.mode = 0660#listen.mode = 0660#g" /etc/php8/php-fpm.d/www.conf && \
	sed -i "s#^;env#env#g" /etc/php8/php-fpm.d/www.conf && \
	deluser "$(grep ':33:' /etc/passwd | awk -F ':' '{print $1}')" || true && \
	delgroup "$(grep '^www-data:' /etc/group | awk -F ':' '{print $1}')" || true && \
	mkdir /var/www && \
	addgroup -g 33 www-data && \
	adduser -D -u 33 -G www-data -s /sbin/nologin -H -h /var/www www-data && \
	chown -R www-data:www-data /var/www

#for editing files
RUN apk add --no-cache nano

#Add entrypoint script inside the Image's WORKDIR
COPY --chmod=0755 conf/entrypoint.sh /

#
ENTRYPOINT ["/entrypoint.sh"]

CMD ["/usr/sbin/php-fpm8", "-F", "--fpm-config", "/etc/php8/php-fpm.conf"]


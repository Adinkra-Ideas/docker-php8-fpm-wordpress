#!/bin/sh

LISTEN=${LISTEN:-socket}

# Append a mapping of custom domain name to 127.0.0.1 into /etc/hosts file
echo "127.0.0.1 $DOMAIN_NAME" >> /etc/hosts

# Get version of php8.x we have
if [ -d /etc/php8 ]
then
  PHP_VER="php8"
# SOCKFILE="php-fpm8.sock"
elif [ -d /etc/php81 ]
then
  PHP_VER="php81"
# SOCKFILE="php-fpm81.sock"
else
  echo "ERROR: unknown php version!"
  exit 1
fi

# Ensuring /run/php exists
if [ ! -d /run/php ]
then
  mkdir /run/php
fi

if [ ! -f /tmp/configured ]
then
  # Ensure it is listening on port 9000
  if [ "${LISTEN}" = "port" ]
  then
    echo "Disabling UNIX socket; enabling listening on TCP port 9000"
    sed -i "s#listen = /var/run/php/${SOCKFILE}#listen = 9000#g" "/etc/${PHP_VER}/php-fpm.d/www.conf"
  fi

  cd /htdocs_vol/
  rm -r *
  # Download Wpcli
  wget https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
  chmod +x wp-cli.phar
  mv wp-cli.phar /usr/local/bin/wp-cli

# Get, install and setup wordpress
  wp-cli core download --allow-root
  wp-cli config create --dbname=${MARIADB_DATABASE} --dbuser=${MARIADB_USER} --dbpass=${MARIADB_PASSWORD} --dbhost=mariadb --locale=en_DB --allow-root
  wp-cli core install --url=${DOMAIN_NAME} --title="${SITE_TITLE}" --admin_user=${ADMIN_NAME} --admin_password=${ADMIN_PASS} --admin_email=${ADMIN_EMAIL} --skip-email --allow-root
  wp-cli theme install digital-newspaper --activate --allow-root 

# Settings
# use 'wp-cli option get *option*' to see current option status
# All option lists are on codex.wordpress.org/User:HEngel/Option_Reference
# Tutorial on catalyst2.com/knowledgebase/wp-cli/managing-wordpress-options-via-wp-cli/
  wp-cli option update comment_whitelist 0 --allow-root

# Create new user with "Author" role
  wp-cli user create ${USER_NAME} ${USER_EMAIL} --user_pass=${USER_PASS} --role=author --porcelain --allow-root

  touch /tmp/configured
fi

# Since this bash script was called using ARGVS,(AKA
# CMD in Dockerfile becomes ARGVs for ENTRYPOINT)
# now execute those ARGVS by doing "exec ARGVS"
exec "$@"


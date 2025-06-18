#!/usr/bin/env sh

set -e

if [ -z "$DB_HOST" ]; then
	echo "*** DATABASE HOST NOT SPECIFIED, ABORTING... ***"
	exit 1
fi

if [ ! "$(ls -A /var/www/bookstack)" ]; then
	git clone --single-branch -b release https://github.com/BookStackApp/bookstack.git /var/www/bookstack
	composer install -d /var/www/bookstack --no-dev

	mkdir /data/storage /data/public
	ln -sf /var/www/bookstack/storage /data/storage
	ln -sf /var/www/bookstack/public /data/public

	cd /var/www/bookstack

	/usr/bin/php artisan key:generate
fi

wait4x mysql "$DB_USERNAME:$DB_PASSWORD@tcp($DB_HOST)/$DB_DATABASE"

/usr/bin/php /var/www/bookstack/artisan migrate

exec php-fpm84

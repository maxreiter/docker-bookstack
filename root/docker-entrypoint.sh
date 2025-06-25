#!/usr/bin/env sh

set -e

if [ -z "$DB_HOST" ]; then
	echo "*** DATABASE HOST NOT SPECIFIED, ABORTING... ***"
	exit 1
fi

wait4x mysql "$DB_USERNAME:$DB_PASSWORD@tcp($DB_HOST)/$DB_DATABASE"

if [ ! "$(ls -A /var/www/bookstack)" ]; then
	curl \
		--location \
		--remote-name \
		--output-dir /var/www/bookstack \
		https://api.github.com/repos/BookStackApp/BookStack/tarball/$BOOKSTACK_VERSION

	tar x \
		-f /var/www/bookstack/$BOOKSTACK_VERSION \
		-C /var/www/bookstack \
		--strip-components 1 \

	rm /var/www/bookstack/$BOOKSTACK_VERSION
	composer install -d /var/www/bookstack --no-dev

	mkdir /data/storage /data/public
	ln -sf /var/www/bookstack/storage /data/storage
	ln -sf /var/www/bookstack/public /data/public

	php /var/www/bookstack/artisan migrate
fi

exec php-fpm84

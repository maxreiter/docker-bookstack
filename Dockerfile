FROM alpine:3.22

# A date-time string as defined by RFC3339
ARG BUILD_DATE

LABEL org.opencontainers.image.created = "$BUILD_DATE" \
	org.opencontainers.image.authors = "Max Reiter <mreiter@rtc.edu>" \
	org.opencontainers.image.url = "https://github.com/maxreiter/docker-bookstack" \
	org.opencontainers.image.documentation = "https://github.com/maxreiter/docker-bookstack" \
	org.opencontainers.image.source = "https://github.com/BookStackApp/BookStack" \
	org.opencontainers.image.version = "25.05.01" \
	org.opencontainers.image.vendor = "Max Reiter" \
	org.opencontainers.image.license = "MIT" \
	org.opencontainers.image.title = "BookStack" \
	org.opencontainers.image.description = "A platform to create documentation/wiki content built with PHP & Laravel"


# Set up container dependencies
RUN <<EOF
	set -eux

	# Install base dependencies
	apk add --no-cache ca-certificates curl openssl tar xz wait4x git

	# Install PHP, FPM and needed modules
	apk add --no-cache php84 php84-fpm php84-gd php84-dom php84-iconv \
	php84-mbstring php84-mysqlnd php84-openssl php84-pdo php84-pdo_mysql \
	php84-tokenizer php84-xml php84-xmlwriter php84-simplexml php84-phar \
	php84-zip php84-session php84-fileinfo php84-curl

	# Symlink /usr/bin/php84 to /usr/bin/php for ease of access
	ln -sf /usr/bin/php84 /usr/bin/php

	# Download the composer installer manually
	SIG="$(curl -fsSL https://composer.github.io/installer.sig)"
	curl -fsSL https://getcomposer.org/installer -o composer-setup.php
	CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

	if [ "$CHECKSUM" != "$SIG" ]; then
		echo "*** COMPOSER CHECKSUM MISMATCH, ABORTING... ***"
		exit 1
	fi

	# Run the composer installer, clean up and move the resulting script to
	# /usr/local/bin/composer
	/usr/bin/php composer-setup.php --quiet
	rm composer-setup.php
	mv composer.phar /usr/local/bin/composer

	# Add the www-data user; defaults to 82 on Alpine
	adduser -u 82 -D -S -G www-data www-data

	mkdir /data
	chown www-data:www-data /data
	chmod 1777 /data

	mkdir -p /var/www/bookstack
	chown www-data:www-data /var/www/bookstack
EOF

USER www-data
WORKDIR /data
VOLUME /data

# Copy PHP configurations and entrypoint script
COPY root/etc/php84/php.ini /etc/php84/php.ini
COPY root/etc/php84/php-fpm.conf /etc/php84/php-fpm.conf
COPY root/etc/php84/php-fpm.d/www.conf /etc/php84/php-fpm.d/www.conf
COPY root/docker-entrypoint.sh /usr/bin/docker-entrypoint

# Expose the port FPM runs on
EXPOSE 9000

ENTRYPOINT [ "/usr/bin/docker-entrypoint" ]

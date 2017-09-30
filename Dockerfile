FROM php:7.0-apache

RUN apt-get update \
  && apt-get install -y \
    libfreetype6-dev \
    libicu-dev \
    libjpeg62-turbo-dev \
    libmcrypt-dev \
    libpng12-dev \
    libxslt1-dev \
    git \
    vim \
    wget \
    lynx \
    psmisc \
    cron \
    openssh-server \
    unison-all \
  && apt-get clean

RUN mkdir -p /var/spool/cron/crontabs/ \
  && touch /var/spool/cron/crontabs/root

RUN docker-php-ext-configure \
    gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/; \
  docker-php-ext-install \
    gd \
    intl \
    mcrypt \
    mbstring \
    pdo_mysql \
    xsl \
    zip \
    soap \
    opcache

RUN yes | pecl install xdebug && \
docker-php-ext-enable xdebug;

RUN { \
		echo 'xdebug.remote_enable=true'; \
		echo 'xdebug.remote_connect_back=1'; \
		echo 'xdebug.remote_port=9000'; \
	} > /usr/local/etc/php/conf.d/xdebug.ini


# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=256M'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=0'; \
		echo 'opcache.fast_shutdown=1'; \
		echo 'opcache.enable_cli=1'; \
		echo 'opcache.enable=1'; \
		echo 'opcache.save_comments=1'; \
		echo 'opcache.revalidate_path=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini


ADD php.ini /usr/local/etc/php/conf.d/magento2.ini


RUN usermod -a -G www-data root; \
    a2enmod rewrite;

##
# Install composer
# source: https://getcomposer.org/download/
##
##
RUN curl -L https://getcomposer.org/installer -o composer-setup.php && \
    php composer-setup.php && \
    rm  composer-setup.php && \
    mv composer.phar /usr/local/bin/composer && \
    chmod +rx /usr/local/bin/composer && \
    # Remove cache and tmp files
    rm -rf /var/cache/apk/*


# Defaults

ENV MYSQL_USER magento2
ENV MYSQL_DATABASE magento2
ENV MYSQL_PASSWORD password
ENV DB_HOST db
ENV TIMEZONE UTC
ENV CURRENCY USD
ENV LANGUAGE en_US
ENV USE_SECURE 0
ENV USE_SECURE_ADMIN 0
ENV DEPLOY_MODE developer
ENV MAGENTO_VERSION 2.2.0
ENV BASE_URL http://127.0.0.1
ENV BACKEND_FRONTNAME admin
ENV USE_REWRITES 0

RUN  echo "root\nroot" | (passwd);
RUN sed -i '/PermitRootLogin without-password/c\PermitRootLogin yes' /etc/ssh/sshd_config && systemctl enable ssh;

COPY 000-default.conf /etc/apache2/sites-available/
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

WORKDIR /var/www/html
VOLUME /var/www/html

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["apache2-foreground"]
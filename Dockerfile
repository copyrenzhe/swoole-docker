FROM php:7.2

LABEL maintainer="copyrenzhe@gmail.com"

# Create dir
RUN mkdir /data \
&& mkdir /data/env \
&& mkdir /data/env/runtime \
&& mkdir /data/website \
&& mkdir /data/logs \
&& mkdir /data/logs/php

WORKDIR /data/

# Env
ENV TZ=Asia/Shanghai \
    HIREDIS_VERSION=0.13.3 \
    SWOOLE_VERSION=4.2.7

# Timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Libs
RUN apt-get update \
    && apt-get install -y \
    curl \
    wget \
    libmagickwand-dev \
    libssl-dev \
    libnghttp2-dev \
    && apt-get clean \
    && apt-get autoremove


# Php extension
RUN docker-php-ext-install -j$(nproc) bcmath gd pdo_mysql mysqli sockets zip

# Imagick extension
RUN pecl install imagick

# Redis extension
RUN pecl install redis

# Hiredis
RUN wget https://github.com/redis/hiredis/archive/v${HIREDIS_VERSION}.tar.gz -O hiredis.tar.gz \
    && mkdir -p hiredis \
    && tar -xf hiredis.tar.gz -C hiredis --strip-components=1 \
    && rm hiredis.tar.gz \
    && ( cd hiredis \
    && make -j$(nproc) \
    && make install \
    && ldconfig ) \
    && rm -r hiredis

# Swoole extension
RUN wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( cd swoole \
    && phpize \
    && ./configure --enable-async-redis --enable-mysqlnd --enable-openssl --enable-http2 \
    && make -j$(nproc) \
    && make install ) \
    && rm -r swoole

# Enable extension
RUN docker-php-ext-enable imagick redis swoole

# Composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer self-update --clean-backups

# config
RUN echo "error_log = /data/logs/php/php_error.log" > /usr/local/etc/php/conf.d/log.ini
RUN echo "log_errors = On" >> /usr/local/etc/php/conf.d/log.ini

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod 777 /usr/local/bin/docker-entrypoint.sh \
    && ln -s /usr/local/bin/docker-entrypoint.sh /

ENTRYPOINT ["/bin/bash", "docker-entrypoint.sh"]
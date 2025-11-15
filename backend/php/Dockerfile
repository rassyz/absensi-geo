FROM php:8.3-fpm

ENV PS1="\u@\h:\w\\$ "
ENV TZ="Asia/Jakarta"

ENV COMPOSER_MEMORY_LIMIT='-1'

# Menggabungkan instalasi apt-get dan cleanup dalam satu layer
RUN apt-get update && \
    apt-get install -y --force-yes --no-install-recommends \
        libmemcached-dev \
        iputils-ping \
        telnet \
        netcat-openbsd \
        net-tools \
        libmcrypt-dev \
        libreadline-dev \
        libgmp-dev \
        libzip-dev \
        libz-dev \
        libpq-dev \
        libjpeg-dev \
        libpng-dev \
        libfreetype6-dev \
        libssl-dev \
        openssh-server \
        libmagickwand-dev \
        git \
        cron \
        nano \
        libxml2-dev \
        nodejs \
        npm \
    && apt-get clean \
    && rm -r /var/lib/apt/lists/*

# Menggabungkan instalasi ekstensi PHP umum dalam satu layer
RUN docker-php-ext-install \
    soap \
    exif \
    pcntl \
    intl \
    gmp \
    zip \
    pdo_pgsql \
    bcmath

# Menggabungkan instalasi PECL
RUN pecl install redis mongodb imagick memcached && \
    docker-php-ext-enable redis mongodb imagick memcached

# Instalasi GD (memperbaiki sedikit duplikasi dari file asli)
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp && \
    docker-php-ext-install gd

# Xdebug diinstal terpisah karena sering ditoggle oleh entrypoint
RUN pecl install xdebug

# Composer
RUN curl -s http://getcomposer.org/installer | php && \
    echo "export PATH=${PATH}:/var/www/html/vendor/bin" >> ~/.bashrc && \
    mv composer.phar /usr/local/bin/composer
RUN . ~/.bashrc

# Laravel Schedule Cron Job
RUN echo "* * * * * root /usr/local/bin/php /var/www/html/artisan schedule:run >> /dev/null 2>&1"  >> /etc/cron.d/laravel-scheduler
RUN chmod 0644 /etc/cron.d/laravel-scheduler

ADD ./local.ini /usr/local/etc/php/conf.d

# Aliases
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/html/artisan "$@"' > /usr/bin/art
RUN chmod +x /usr/bin/art
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/html/artisan migrate "$@"' > /usr/bin/migrate
RUN chmod +x /usr/bin/migrate
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/html/artisan migrate:fresh --seed' > /usr/bin/fresh
RUN chmod +x /usr/bin/fresh
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/html/artisan config:clear\n/var/www/html/vendor/bin/phpunit -d memory_limit=2G --stop-on-error --stop-on-failure --testdox-text=tests/report.txt "$@"' > /usr/bin/t
RUN chmod +x /usr/bin/t
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/html/artisan config:clear\n/bin/bash\n/usr/local/bin/php /var/www/html/artisan dusk -d memory_limit=2G --stop-on-error --stop-on-failure --testdox-text=tests/report-dusk.txt "$@"' > /usr/bin/d
RUN chmod +x /usr/bin/d

# Perintah `rm -r /var/lib/apt/lists/*` dipindahkan ke atas (ke dalam layer apt-get)

WORKDIR /var/www/html

COPY ./docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN ln -s /usr/local/bin/docker-entrypoint.sh /
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 9000
CMD ["php-fpm"]
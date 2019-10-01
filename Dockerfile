FROM php:7.3-fpm

ENV MASTER_TZ=Asia/Manila
ENV MASTER_DIR=/var/www/html

RUN ln -snf /usr/share/zoneinfo/${MASTER_TZ} /etc/localtime && echo ${MASTER_TZ} > /etc/timezone

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    jpegoptim optipng pngquant gifsicle \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    locales \
    mysql-client \
    unzip \
    vim \
    zip

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install bcmath exif mbstring pcntl pdo_mysql zip && \
    docker-php-ext-configure gd --with-gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ && \
    docker-php-ext-install gd

# This will override default PHP configuration
COPY .docker/php-fpm/php.ini /usr/local/etc/php/conf.d/local.ini:ro

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# This will allow the container to use a cached version of PHP packages
COPY composer.lock composer.json ${MASTER_DIR}/

# This is included just to bypass errors thrown by composer scripts
COPY database ${MASTER_DIR}/database

RUN composer install --no-interaction --no-plugins --no-scripts

COPY . ${MASTER_DIR}
COPY ./.docker/php-fpm/init.sh /usr/local/bin/init
COPY ./.docker/php-fpm/after.sh /usr/local/bin/after
COPY ./.docker/queuer/init.sh /usr/local/bin/laravel-queuer
COPY ./.docker/scheduler/init.sh /usr/local/bin/laravel-scheduler

RUN chmod -R 775 ${MASTER_DIR}/storage ${MASTER_DIR}/bootstrap/cache
RUN chmod u+x /usr/local/bin/init
RUN chmod u+x /usr/local/bin/after
RUN chmod u+x /usr/local/bin/laravel-queuer
RUN chmod u+x /usr/local/bin/laravel-scheduler

ENTRYPOINT ["init", "--port", "9000"]
# production base image to run XBackBone
FROM php:7.4-fpm as base

ENV BASE_URL=http://localhost

# install nginx and supervisor to run in the same container
RUN apt-get update && apt-get install -y nginx supervisor

# grab the php extensions installer (helper function to apt install dependancies)
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/

# install required dependancies for XBackBone
RUN install-php-extensions gd intl zip

COPY config/nginx.conf /etc/nginx/conf.d/default.conf
COPY config/supervisord.conf /etc/supervisord.conf
COPY scripts/init.sh /run/init.sh

# start from the prod base image and install things required for packaging the website
FROM base as build

# nodejs installer
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

# install required stuff
RUN apt-get update && \
    apt-get install -y unzip nodejs

WORKDIR /app/xbackbone

# install composer, globally
RUN curl https://raw.githubusercontent.com/composer/getcomposer.org/76a7060ccb93902cd7576b67264ad91c8a2700e2/web/installer | php -- && \
    mv composer.phar /usr/local/bin/composer
    
COPY package.json package-lock.json \
     composer.json composer.lock ./

# install packages for XBackBone
# build the release using grunt
RUN composer install && npm install

# grab the xbackbone code
COPY . .

RUN ./node_modules/grunt/bin/grunt build-release

# extract the built files to a dist folder for the production image
# (grunt could not-zip them up, but I didn't want to change the repo code)
RUN unzip release*.zip -d ./dist/

# start from the prod base image and build onto it for running XBackBone
FROM base as runtime

COPY --from=build /app/xbackbone/dist/ /app

# ensure that XBackBone can write to the various folders it requires
RUN chown -R www-data:www-data /app 

VOLUME [ "/app/storage", "/app/resources/database", "/app/logs", "/app/config"]

ENTRYPOINT ["/run/init.sh"]
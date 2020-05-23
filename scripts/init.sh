#!/bin/bash

# extract the domain from a url (remove the http/https)
# http://example.com -> example.com
baseUrl=$(echo $NGINX_SERVER_NAME | sed -e 's|^[^/]*//||')
baseUrl=${baseUrl:-localhost}

# replace the localhost in the server_name
sed -i "s/localhost/$baseUrl/g" /etc/nginx/conf.d/default.conf

exec /usr/bin/supervisord -n -c /etc/supervisord.conf
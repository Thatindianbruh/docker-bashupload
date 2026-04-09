#!/bin/sh

# Apply UPLOADSIZE env var to PHP ini if provided
if [ -n "$UPLOADSIZE" ]; then
    sed -i "s|^upload_max_filesize = .*|upload_max_filesize = $UPLOADSIZE|" /etc/php83/php.ini
    sed -i "s|^post_max_size = .*|post_max_size = $UPLOADSIZE|" /etc/php83/php.ini
    sed -i "s|client_max_body_size .*;|client_max_body_size $UPLOADSIZE;|" /etc/nginx/conf.d/default.conf
fi

# Start PHP-FPM
php-fpm83 -D

# Start nginx in foreground
exec nginx -g "daemon off;"

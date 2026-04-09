FROM nginx:alpine

# Install PHP-FPM and required extensions
RUN apk add --no-cache php83 php83-fpm php83-session

# Configure PHP-FPM to run as nginx user and listen on a TCP socket
RUN sed -i 's|^user = .*|user = nginx|' /etc/php83/php-fpm.d/www.conf && \
    sed -i 's|^group = .*|group = nginx|' /etc/php83/php-fpm.d/www.conf && \
    sed -i 's|^listen = .*|listen = 127.0.0.1:9000|' /etc/php83/php-fpm.d/www.conf

# Set upload size limit from build arg (overridable via UPLOADSIZE env at runtime via entrypoint)
RUN sed -i 's|^upload_max_filesize = .*|upload_max_filesize = 1G|' /etc/php83/php.ini && \
    sed -i 's|^post_max_size = .*|post_max_size = 1G|' /etc/php83/php.ini

# Copy app files
COPY . /app

# Write nginx config
RUN printf 'server {\n\
    listen 80;\n\
    root /app/web;\n\
    index index.php;\n\
\n\
    client_max_body_size 1G;\n\
\n\
    location / {\n\
        try_files $uri /index.php?$args;\n\
    }\n\
\n\
    location = /index.php {\n\
        fastcgi_pass 127.0.0.1:9000;\n\
        fastcgi_index index.php;\n\
        include fastcgi_params;\n\
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;\n\
        fastcgi_read_timeout 1800;\n\
    }\n\
}\n' > /etc/nginx/conf.d/default.conf

# Create files storage directory
RUN mkdir -p /app/files && chown -R nginx:nginx /app/files

# Entrypoint: apply UPLOADSIZE env var if set, then start services
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]

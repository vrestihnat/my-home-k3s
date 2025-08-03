FROM php:8.2-apache

# Instalace dodatečných PHP rozšíření
RUN docker-php-ext-install pdo pdo_mysql

# Povolení Apache mod_rewrite
RUN a2enmod rewrite

# Kopírování aplikace
COPY index.php /var/www/html/

# Nastavení oprávnění
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html

# Konfigurace Apache pro Kubernetes
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/ || exit 1

EXPOSE 80

CMD ["apache2-foreground"]

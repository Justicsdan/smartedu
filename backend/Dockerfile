# Use the latest PHP 8 Apache image
FROM php:8.2-apache

# Enable mod_rewrite (needed for clean URLs in PHP apps)
RUN a2enmod rewrite

# Copy the backend files into the Apache root
COPY ./public /var/www/html/

# Set working directory
WORKDIR /var/www/html/

# Expose port 80 (Render uses this)
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]

#!/bin/sh
echo "Initializing setup..."

/usr/local/bin/composer install -d /src

chmod +x /src/bin/magento

if [ "$M2SETUP_USE_SAMPLE_DATA" = true ]; then
  echo "Installing composer dependencies..."
  /src/bin/magento sampledata:deploy

  echo "Ignore the above error (bug in Magento), fixing with 'composer update'..."
  composer update

  M2SETUP_USE_SAMPLE_DATA_STRING="--use-sample-data"
else
  M2SETUP_USE_SAMPLE_DATA_STRING=""
fi

if [ -f /src/app/etc/config.php ] || [ -f /src/app/etc/env.php ]; then
  echo "Already installed? Either app/etc/config.php or app/etc/env.php exist, please remove both files to continue setup."
  /usr/local/sbin/php-fpm
fi

echo "Running Magento 2 setup script..."
/usr/local/bin/php -d /src/bin/magento setup:install \
  --db-host=$M2SETUP_DB_HOST \
  --db-name=$M2SETUP_DB_NAME \
  --db-user=$M2SETUP_DB_USER \
  --db-password=$M2SETUP_DB_PASSWORD \
  --base-url=$M2SETUP_BASE_URL \
  --admin-firstname=$M2SETUP_ADMIN_FIRSTNAME \
  --admin-lastname=$M2SETUP_ADMIN_LASTNAME \
  --admin-email=$M2SETUP_ADMIN_EMAIL \
  --admin-user=$M2SETUP_ADMIN_USER \
  --admin-password=$M2SETUP_ADMIN_PASSWORD \
  $M2SETUP_USE_SAMPLE_DATA_STRING

echo "Reindexing all indexes..."
/usr/local/bin/php -d /src/bin/magento indexer:reindex

/usr/local/bin/php -d /src/bin/magento setup:static-content:deploy

echo "Applying ownership & proper permissions..."
sed -i 's/0770/0775/g' /src/vendor/magento/framework/Filesystem/DriverInterface.php
sed -i 's/0660/0664/g' /src/vendor/magento/framework/Filesystem/DriverInterface.php
find pub -type f -exec chmod 664 {} \;
find pub -type d -exec chmod 775 {} \;
find /src/var/generation -type d -exec chmod g+s {} \;
chown -R www-data:www-data /src

echo "The setup script has completed execution."

/usr/local/sbin/php-fpm
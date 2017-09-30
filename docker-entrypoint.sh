#!/usr/bin/env bash
set -euo pipefail

set_permissions(){
    chown -R www-data:www-data $PWD;
}

reset_generated(){
    rm -rf ../var/page_cache/*;
    rm -rf ../var/cache/*;
    rm -rf ../var/view_preprocessed/*;
    rm -rf ../var/composer_home/*;
    rm -rf ../pub/static/*;
    rm -rf ../var/generation/*;
}

cron_jobs(){
    #write out current crontab
    crontab -l > mycron
    #echo new cron into cron file
    echo "* * * * * /usr/bin/php $PWD/bin/magento cron:run | grep -v 'Ran jobs by schedule' >> $PWD/var/log/magento.cron.log" >> mycron
    echo "* * * * * /usr/bin/php $PWD/update/cron.php >> $PWD/var/log/update.cron.log" >> mycron
    echo "* * * * * /usr/bin/php $PWD/bin/magento setup:cron:run >> $PWD/var/log/setup.cron.log" >> mycron
    #install new cron file
    crontab -u www-data mycron
    rm mycron
}

if ! [ -e index.php -a -e bin/magento ]; then
  echo >&2 "Magento2 not found in $PWD - creating now..."

  if [ -z ${MAGENTO_PUBLIC_KEY+x} ] || [ -z ${MAGENTO_PRIVATE_KEY+x} ]; then
    echo >&2 "You must set the following environmental variables to get the integrator package MAGENTO_PUBLIC_KEY , MAGENTO_PRIVATE_KEY "
    echo >&2 "You may optionally set MAGENTO_VERSION (default 2.2.0) "
    echo >&2 "This container will continue to run, you may access it via 'docker exec <this-container> sh' to perform manual installs or backups.."

  else

      if [ "$(ls -A)" ]; then
        echo >&2 "WARNING: $PWD please empty the mounted volume on the host and try again..."
        ( set -x; ls -A; sleep 10 )
      fi

      composer global config http-basic.repo.magento.com ${MAGENTO_PUBLIC_KEY} ${MAGENTO_PRIVATE_KEY};
      composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition:${MAGENTO_VERSION} /var/www/html;

      # Set the pre-installation magento folder permissions
      find var vendor pub/static pub/media app/etc -type f -exec chmod g+w {} \; \
      && find var vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} \; \
      && chown -R :www-data . && chmod u+x bin/magento;
  fi

fi

if ! [ -e app/etc/env.php ]; then


    if [ -z ${ADMIN_FIRSTNAME+x} ] \
    || [ -z ${ADMIN_LASTNAME+x} ] \
    || [ -z ${ADMIN_EMAIL+x} ] \
    || [ -z ${ADMIN_USER+x} ] \
    || [ -z ${ADMIN_PASSWORD+x} ]; then

        echo >&2 "Magento package has been downloaded but not installed"
        echo >&2 "Please visit your host address in the browser to manually setup your magento 2 installation"
        echo >&2 "If you wish to have your magento installation automatically installed please see the README for more details"

    else
          #http://devdocs.magento.com/guides/v2.1/install-gde/install/cli/install-cli-install.html
          ./bin/magento setup:install \
          --admin-firstname=${ADMIN_FIRSTNAME} \
          --admin-lastname=${ADMIN_LASTNAME} \
          --admin-email=${ADMIN_EMAIL} \
          --admin-user=${ADMIN_USER} \
          --admin-password=${ADMIN_PASSWORD} \
          --base-url=${BASE_URL} \
          --backend-frontname=${BACKEND_FRONTNAME} \
          --db-host=${DB_HOST} \
          --db-name=${MYSQL_DATABASE} \
          --db-user=${MYSQL_USER} \
          --db-password=${MYSQL_PASSWORD} \
          --language=${LANGUAGE} \
          --currency=${CURRENCY} \
          --timezone=${TIMEZONE} \
          --use-secure=${USE_SECURE} \
          --use-secure-admin=${USE_SECURE_ADMIN} \
          --use-rewrites=${USE_REWRITES}

         ./bin/magento deploy:mode:set developer;
         set_permissions;

    fi



else

    echo >&2 "Magento package has been downloaded but not installed"
    echo >&2 "Please visit your host address in the browser to manually setup your magento 2 installation"
    echo >&2 "If you wish to have your magento installation automatically installed please see the README for more details"

fi

if ! [ -e /var/spool/cron/crontabs/www-data ]; then
    touch /var/spool/cron/crontabs/www-data && chown www-data:www-data /var/spool/cron/crontabs/www-data;
    cron_jobs;
fi

#if ! [ -e magento_umask ]; then
#
#    echo 'magento_umask 002' > magento_umask;
#
#fi

service ssh start;

exec "$@"

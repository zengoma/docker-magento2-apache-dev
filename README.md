## Simple Apache/Magento 2 Dev Docker container

A simple Magento 2 development environment container for docker. Please note this container is for development purposes
only and is not suitable for use in production. This container is designed to install the integrator package of magento CE
for magento 2 module and theme developers.

### Installation options.

For the sake of convenience and versatility the container can automate the entire installation process or you may choose
to manually oversee each step of the installation. You may also wish to restore a backup via container shell access. The installation 
can be controlled using environmental variables. See the variables section for more information. 


### Environmental variables:


#### Complete manual installation:

You have decided to either reconstruct a backup or manually run composer create-project in the container. In this case do
not declare any of the listed environmental variables.

#### Automatic composer create-project with manual installation.

You have decided to automatically run the "composer create-project" command and manually install magento using the web setup
wizard or command line from within the container.

You need to declare as a minimum the following variables:

* MAGENTO_PUBLIC_KEY
* MAGENTO_PRIVATE_KEY
* MAGENTO_VERSION (optional default = 2.2.0)

#### Completely automated installation.

You have decided to automate composer create-project AND install magento 2. In this scenario you should at least declare:

* MAGENTO_PUBLIC_KEY
* MAGENTO_PRIVATE_KEY
* ADMIN_FIRSTNAME
* ADMIN_LASTNAME
* ADMIN_EMAIL
* ADMIN_USER
* ADMIN_PASSWORD

The other options will revert to the default value, but you should declare these if you wish to override the default.

#### Complete list of configurable variables with defaults:

* MYSQL_USER: database user (default: magento2)
* MYSQL_PASSWORD: database password (default: password)
* MYSQL_DATABASE: magento2 database (default: magento2)
* DB_HOST: linked database container (default: db)
* MAGENTO_PUBLIC_KEY: your marketplace public key **
* MAGENTO_PRIVATE_KEY: your marketplace private key **
* ADMIN_FIRSTNAME: store owner first name **
* ADMIN_LASTNAME: store owner last name **
* ADMIN_EMAIL: store owner email address **
* ADMIN_USER: admin username **
* ADMIN_PASSWORD: admin password (must contain letters and numbers) **
* BASE_URL: base url (default: http://127.0.01) ***
* LANGUAGE: store language (default: en_US) ***
* CURRENCY: store currency code (default: USD) ***
* TIMEZONE: timezone for store (default: UTC) ***
* MAGENTO_VERSION: the version of magento you wish to install i.e 2.2.0 (default: 2.2.0) ***
* DEPLOY_MODE: the deployment mode - you should leave this unchanged (default: developer) ***
* USE_REWRITES: whether or not to use rewrites 0=no 1=yes (default: 0)

** These values are only required for fresh installs. If you are restoring an old copy these will be inherited from your
database.

*** Optional for fresh installs

### Volumes

* /var/www/html (the magento2 installation root)

### Cron

While cron jobs are normally considered a separate concern for a separate container, the default magento 2 cron jobs are tightly
coupled with the installations. Thus for convenience cron has already been setup in the container for the www-data user:

```bash
crontab -u www-data -l

* * * * * /usr/local/bin/php /var/www/html/bin/magento cron:run | grep -v 'Ran jobs by schedule' >> /var/www/html/var/log/magento.cron.log
* * * * * /usr/local/bin/php /var/www/html/update/cron.php >> /var/www/html/var/log/update.cron.log
* * * * * /usr/local/bin/php /var/www/html/bin/magento setup:cron:run >> /var/www/html/var/log/setup.cron.log

```

### Setup

#### Linux:
Linux provides the best development experience with minimal complications.
Create a docker-compose.yml file (This is a bare minimum setup for fresh install on localhost). Check out the repo for
.env.sample file. Advanced users may use the docker run command to spin up the containers.

```yaml

version: "3"
services:

  magento2-dev:
    image: zengoma/magento2-apache-dev
    ports:
      - "80:80"
    links:
      - db:db
    volumes:
      - ./volumes/magento2:/var/www/html
    environment:
      DB_HOST: ${DB_HOST}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}
      MAGENTO_PUBLIC_KEY: ${MAGENTO_PUBLIC_KEY}
      MAGENTO_PRIVATE_KEY: ${MAGENTO_PRIVATE_KEY}
      ADMIN_FIRSTNAME: ${ADMIN_FIRSTNAME}
      ADMIN_LASTNAME: ${ADMIN_LASTNAME}
      ADMIN_EMAIL: ${ADMIN_EMAIL}
      ADMIN_USER: ${ADMIN_USER}
      ADMIN_PASSWORD: ${ADMIN_PASSWORD}
      

  db:
    image: percona
    volumes:
      - ./volumes/database:/var/www/html
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}

```

If you are performing a fresh install, composer is going to pull the magento repo and run the command line installation.
This is going to take a fair amount of time so get some coffee, read a book or go for a jog. 

The first time you bring up the container you will want to omit the -d argument to prevent detached mode. This will allow 
you see the console output which is helpful for debugging parameters that have been set incorrectly and see the progress of your installation.


#### Windows and Mac:

I would highly recommend that you do not create a local mounted volume for the magento2-dev container. 
i.e remove "- ./volumes/magento2:/var/www/html". Mounting volumes to the local Windows or Mac filesystem will greatly
reduce performance and, to be quite honest, makes local development impossible.

The solution is to mount the magento root directory to a named/native volume in order to persist changes and then to run some kind of
file synchronization tool. To ease this process the container comes with ssh installed.

Accessing the container via ssh is as easy as:

```bash
ssh root@127.0.0.1
```
*The default ssh password is root.*

SSH is not natively available on Windows. 
You can download openSSH for Windows [here](https://db5iu3k4j1efi.cloudfront.net/setupssh-7.3p1-2-zbtukxot24.exe)

Alternatively you can download and install [GIT](https://git-scm.com/downloads), and ssh from the git terminal which supports ssh.

Finally to access the container via ssh you should bind port 22 to a port on your local machine (see docker-compose example below).

A minimal Windows / Mac docker-compose example:

```yaml
version: "3"
services:

  magento2-dev:
    depends_on:
      - db
    image: zengoma/magento2-apache-dev
    volumes:
      - magento2_1_9:/var/www/html
    ports:
      - "80:80"
      - "22:22"
    links:
      - db:db
    environment:
#      Declare any variables if you wish or omit completely


  db:
    image: percona
    volumes:
      - magento_db:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}

volumes:
  magento_db:
  magento2_1_9:
  
```

You should now use a remote syncing tool like [unison](http://unison-binaries.inria.fr/). The container comes with unison
2.40 pre-installed. You must install the same version on your machine to connect. Future releases of this repo will include
more comprehensive instructions.

My preference is to automatically sync files remotely using an IDE (like PHPstorm, Netabeans or Atom).


### Installing sample data

```bash
docker-compose exec magento2-dev ./bin/magento sampledata:deploy && ./bin/magento setup:upgrade
```

Where "magento2-dev" is the name of your magento2 container.

### TODO

* Add docker-compose examples with redis and varnish.
* Instructions for configuring xdebug
* Better instructions for unison and IDE syncing

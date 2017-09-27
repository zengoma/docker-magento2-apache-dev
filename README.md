# Simple Apache/Magento 2 Dev Docker container

A simple Magento 2 development environment container for docker. Please note this container is for development purposes
only and is not suitable for use in production.

## Setup

### Linux:

Create a docker-compose.yml file (This is a bare minimum setup).

```yaml

version: "3"
services:

  magento2-dev:
    restart: unless-stopped
    networks:
      - back
      - front
    image: zengoma/magento2-apache-dev
    ports:
      - "80:80"
    links:
      - db:db
    volumes:
      - ./volumes/magento2:/var/www/html

  db:
    restart: unless-stopped
    networks:
      - back
    image: percona
    volumes:
      - ./volumes/database:/var/www/html
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_USER: ${MYSQL_USER}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD}
      MYSQL_DATABASE: ${MYSQL_DATABASE}

networks:
  front:
  back:

```

Make sure you have composer and php installed on your host system and run the following command from the root directory to populate
the magento 2 volume.

```bash
composer create-project --ignore-platform-reqs --repository-url=https://repo.magento.com/ magento/project-community-edition volumes/magento2
```

We use the "--ignore-platform-reqs" option here just in case you have an unsupported version of php running on your system.
You could bring a previous install and drop it into the mounted volume, but be sure to also bring your database and media too.

You can now visit "http://localhost" in your browser and manually complete your magento 2 install.

When prompted to select your database host please enter "db" (in this instance), as well as the credentials you have in
your .env file.

### Windows and Mac:

The setup remains the same as Linux, with one exception. I would highly recommend that you do not create a mounted volume
for the magento2-dev container. i.e remove "- ./volumes/magento2:/var/www/html". This will seriously hamper performance.
You should rather use unison instead. Personally I find developing on a mac or a windows machine painful. My personal preference
is to spin up a linux development server and sync the filesystem remotely with your IDE.

If you do choose to host your dev server on a VPS I would recommend that you leave it turned off when you are not developing.

## TODO

* Add docker-compose examples with redis and varnish.
* Automatically create a project from environmental variables if /var/www/html is empty.
* Instructions for configuring xdebug

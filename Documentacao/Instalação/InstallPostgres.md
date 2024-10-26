sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ jammy-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

sudo apt update
sudo apt install postgresql-15 postgresql-15-postgis-3

psql --version

CREATE USER indoor WITH PASSWORD 'senha_segura';

CREATE DATABASE indoor-routes OWNER indoor;

GRANT ALL PRIVILEGES ON DATABASE indoor-routes TO indoor;

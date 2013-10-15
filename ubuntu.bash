# Prepare
apt-get update
apt-get -y upgrade

# Timezone
cp /usr/share/zoneinfo/America/Los_Angeles /etc/localtime
echo America/Los_Angeles > /etc/timezone
date

# Download Graphite
rm -rf /tmp/graphite
mkdir -p /tmp/graphite
cd /tmp/graphite

git clone https://github.com/graphite-project/carbon.git
git clone https://github.com/graphite-project/graphite-web.git
git clone https://github.com/graphite-project/whisper.git

# Check Dependencies
cd /tmp/graphite/graphite-web
python check-dependencies.py

# Install Dependencies
apt-get -y install libcairo2-dev

apt-get -y install python-pip
pip install Django==1.5.4

pip install django-tagging

easy_install zope.interface

apt-get -y install python-dev
easy_install twisted

apt-get -y install fontconfig

apt-get -y install apache2 libapache2-mod-wsgi libapache2-mod-python

apt-get -y install memcached

apt-get -y install python-memcache

apt-get -y install python-ldap

easy_install txamqp

apt-get -y install python-rrdtool

apt-get -y install python-tz python-pyparsing python-cairo-dev 

# Install
cd /tmp/graphite/graphite-web
python setup.py install

cd /tmp/graphite/carbon
python setup.py install

cd /tmp/graphite/whisper
python setup.py install

# Check Dependencies
cd /tmp/graphite/graphite-web
python check-dependencies.py

# Configure
mv /opt/graphite/conf/carbon.conf.example /opt/graphite/conf/carbon.conf
mv /opt/graphite/conf/storage-schemas.conf.example /opt/graphite/conf/storage-schemas.conf
mv /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/graphite.wsgi

mv /etc/apache2/sites-available/default /etc/apache2/sites-available/default.bak
cp /opt/graphite/examples/example-graphite-vhost.conf /etc/apache2/sites-available/default

/etc/init.d/apache2 restart

cd /opt/graphite/webapp/graphite
python manage.py syncdb

chown www-data:www-data /opt/graphite/storage/graphite.db
mv /opt/graphite/webapp/graphite/local_settings.py.example /opt/graphite/webapp/graphite/local_settings.py

mv /opt/graphite/conf/storage-aggregation.conf.example /opt/graphite/conf/storage-aggregation.conf

mkdir -p /opt/graphite/storage/log/carbon-cache
cd /opt/graphite
./bin/carbon-cache.py start

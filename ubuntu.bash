function escapeSearchPattern
{
    echo "$(echo "${1}" | sed "s@\[@\\\\[@g")"
}

function installDependencies
{
    apt-get update
    apt-get -y upgrade

    apt-get -y install apache2
    apt-get -y install erlang-os-mon
    apt-get -y install erlang-snmp
    apt-get -y install libapache2-mod-python
    apt-get -y install libapache2-mod-wsgi
    apt-get -y install memcached
    apt-get -y install python-cairo-dev
    apt-get -y install python-dev
    apt-get -y install python-django
    apt-get -y install python-ldap
    apt-get -y install python-memcache
    apt-get -y install python-pip
    apt-get -y install python-pysqlite2
    apt-get -y install rabbitmq-server
    apt-get -y install sqlite3

    pip install django-tagging
}

function installGraphite
{
    pip install carbon
    pip install graphite-web
    pip install whisper
}

function configApache
{
    local oldWSGISocketPrefix="$(escapeSearchPattern 'WSGISocketPrefix run/wsgi')"
    local newWSGISocketPrefix="$(escapeSearchPattern 'WSGISocketPrefix /var/run/apache2/wsgi')"

    sed "s@${oldWSGISocketPrefix}@${newWSGISocketPrefix}@g" '/opt/graphite/examples/example-graphite-vhost.conf' > '/etc/apache2/sites-available/default'
}

function configGraphite
{
    mv '/opt/graphite/conf/carbon.conf.example' '/opt/graphite/conf/carbon.conf'
    mv '/opt/graphite/conf/storage-schemas.conf.example' '/opt/graphite/conf/storage-schemas.conf'
    mv '/opt/graphite/conf/graphite.wsgi.example' '/opt/graphite/conf/graphite.wsgi'

    cp "${appPath}/config/initial_data.json" '/opt/graphite/webapp/graphite/initial_data.json'
    cd '/opt/graphite/webapp/graphite'
    python manage.py syncdb --noinput

    mv '/opt/graphite/webapp/graphite/local_settings.py.example' '/opt/graphite/webapp/graphite/local_settings.py'

    chown -R www-data:www-data '/opt/graphite/storage'
}

function startServers
{
    /etc/init.d/apache2 restart

    cd /opt/graphite
    ./bin/carbon-cache.py start
}

function main
{
    appPath="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    installDependencies
    installGraphite

    configApache
    configGraphite

    startServers
}

main "${@}"

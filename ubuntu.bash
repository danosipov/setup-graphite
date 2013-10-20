#!/bin/bash

function installDependencies
{
    printHeader 'INSTALL DEPENDENCIES'

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

    apt-get -y install expect

    pip install django-tagging
}

function installGraphite
{
    printHeader 'INSTALL GRAPHITE'

    pip install carbon
    pip install graphite-web
    pip install whisper
}

function configApache
{
    printHeader 'CONFIG APACHE'

    local oldWSGISocketPrefix="$(escapeSearchPattern 'WSGISocketPrefix run/wsgi')"
    local newWSGISocketPrefix="$(escapeSearchPattern 'WSGISocketPrefix /var/run/apache2/wsgi')"

    sed "s@${oldWSGISocketPrefix}@${newWSGISocketPrefix}@g" '/opt/graphite/examples/example-graphite-vhost.conf' > '/etc/apache2/sites-available/default'
}

function configGraphite
{
    printHeader 'CONFIG GRAPHITE'

    mv '/opt/graphite/conf/carbon.conf.example' '/opt/graphite/conf/carbon.conf'
    mv '/opt/graphite/conf/storage-schemas.conf.example' '/opt/graphite/conf/storage-schemas.conf'
    mv '/opt/graphite/conf/graphite.wsgi.example' '/opt/graphite/conf/graphite.wsgi'

    cd '/opt/graphite/webapp/graphite'
    python manage.py syncdb --noinput
    python manage.py createsuperuser --username="${1}" --email="${3}" --noinput

    expect << DONE
        spawn python manage.py changepassword "${1}"
        expect "Password: "
        send -- "${2}\r"
        expect "Password (again): "
        send -- "${2}\r\r"
        expect eof
DONE

    mv '/opt/graphite/webapp/graphite/local_settings.py.example' '/opt/graphite/webapp/graphite/local_settings.py'
    chown -R www-data:www-data '/opt/graphite/storage'
}

function restartServers
{
    printHeader 'RESTART SERVERS'

    "${appPath}/bin/restart"
}

function displayUsage
{
    local scriptName="$(basename ${0})"

    echo -e "\033[1;35m"
    echo    "SYNOPSIS :"
    echo -e "    ${scriptName} -h -l <LOGIN> -p <PASSWORD> -e <EMAIL>\n"
    echo    "DESCRIPTION :"
    echo    "    -h    Help page"
    echo    "    -l    Super user's login (require)"
    echo    "    -p    Super user's password (require)"
    echo    "    -e    Super user's email (require)"
    echo -e "\033[1;36m"
    echo    "EXAMPLES :"
    echo    "    ${scriptName} -h"
    echo    "    ${scriptName} -l 'root' -p 'foo' -e 'root@domain.com'"
    echo -e "\033[0m"

    exit 1
}

function main
{
    appPath="$(cd "$(dirname "${0}")" && pwd)"

    source "${appPath}/lib/util.bash" || exit 1

    while getopts ':hl:p:e:' option
    do
        case "${option}" in
            h)
               displayUsage
               ;;
            l)
               local login="${OPTARG}"
               ;;
            p)
               local password="${OPTARG}"
               ;;
            e)
               local email="${OPTARG}"
               ;;
            *)
               ;;
        esac
    done

    OPTIND=1

    if [[ "$(isEmptyString ${login})" = 'false' && "$(isEmptyString ${password})" = 'false' && "$(isEmptyString ${email})" = 'false' ]]
    then
        checkRequireRootUser

        installDependencies
        installGraphite

        configApache
        configGraphite "${login}" "${password}" "${email}"

        restartServers
    else
        error 'ERROR: login, password, or email not found!'
        displayUsage
    fi
}

main "${@}"

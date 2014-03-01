#!/bin/bash

function installDependencies()
{
    printHeader 'INSTALLING DEPENDENCIES'

    apt-get update
    apt-get upgrade -y

    apt-get install -y apache2
    apt-get install -y erlang-os-mon
    apt-get install -y erlang-snmp
    apt-get install -y expect
    apt-get install -y libapache2-mod-python
    apt-get install -y libapache2-mod-wsgi
    apt-get install -y memcached
    apt-get install -y python-cairo-dev
    apt-get install -y python-dev
    apt-get install -y python-ldap
    apt-get install -y python-memcache
    apt-get install -y python-pip
    apt-get install -y python-pysqlite2
    apt-get install -y sqlite3
}

function installGraphite()
{
    printHeader 'INSTALLING GRAPHITE'

    pip install carbon
    pip install graphite-web
    pip install whisper
    pip install Twisted==11.1.0
    pip install django==1.5
    pip install django-tagging
}

function configApache()
{
    printHeader 'CONFIGURING APACHE'

    local oldWSGISocketPrefix="$(escapeSearchPattern 'WSGISocketPrefix run/wsgi')"
    local newWSGISocketPrefix="$(escapeSearchPattern 'WSGISocketPrefix /var/run/apache2/wsgi')"

    if [[ -f '/etc/apache2/sites-available/000-default.conf' ]]
    then
        local defaultConfigFileName='000-default.conf'
        $(safeCopyFile "${appPath}/conf/apache2/apache2.conf" '/etc/apache2/apache2.conf')
    else
        local defaultConfigFileName='default'
    fi

    sed "s@${oldWSGISocketPrefix}@${newWSGISocketPrefix}@g" \
        '/opt/graphite/examples/example-graphite-vhost.conf' \
        > "/opt/graphite/examples/${defaultConfigFileName}"

    $(safeMoveFile "/opt/graphite/examples/${defaultConfigFileName}" "/etc/apache2/sites-available/${defaultConfigFileName}")
}

function configGraphite()
{
    local login="${1}"
    local password="${2}"
    local email="${3}"

    printHeader 'CONFIGURING GRAPHITE'

    $(safeMoveFile '/opt/graphite/conf/carbon.conf.example' '/opt/graphite/conf/carbon.conf')
    $(safeMoveFile '/opt/graphite/conf/storage-schemas.conf.example' '/opt/graphite/conf/storage-schemas.conf')
    $(safeMoveFile '/opt/graphite/conf/graphite.wsgi.example' '/opt/graphite/conf/graphite.wsgi')
    $(safeMoveFile '/opt/graphite/webapp/graphite/local_settings.py.example' '/opt/graphite/webapp/graphite/local_settings.py')

    cd '/opt/graphite/webapp/graphite'
    python manage.py syncdb --noinput
    python manage.py createsuperuser --username="${login}" --email="${email}" --noinput

    expect << DONE
        spawn python manage.py changepassword "${login}"
        expect "Password: "
        send -- "${password}\r"
        expect "Password (again): "
        send -- "${password}\r"
        expect eof
DONE

    chown -R 'www-data:www-data' '/opt/graphite/storage'
}

function configUpstart()
{
    $(safeCopyFile "${appPath}/conf/upstart/carbon-cache.conf" '/etc/init')
}

function restartServers()
{
    printHeader 'RESTARTING SERVERS'

    "${appPath}/bin/restart"
}

function displayUsage()
{
    local scriptName="$(basename ${0})"

    echo -e "\033[1;33m"
    echo    "SYNOPSIS :"
    echo    "    ${scriptName} --help --login <LOGIN> --password <PASSWORD> --email <EMAIL>"
    echo -e "\033[1;35m"
    echo    "DESCRIPTION :"
    echo    "    --help        Help page"
    echo    "    --login       Graphite Browser admin-user's login (require)"
    echo    "    --password    Graphite Browser admin-user's password (require)"
    echo    "    --email       Graphite Browser admin-user's email (require)"
    echo -e "\033[1;36m"
    echo    "EXAMPLES :"
    echo    "    ./${scriptName} --help"
    echo    "    ./${scriptName} --login 'root' --password 'root' --email 'root@localhost.com'"
    echo -e "\033[1;32m"
    echo    "USEFUL COMMANDS :"
    echo    "    To stop/start/restart apache2      : service apache2 <stop|start|restart>"
    echo    "    To stop/start/restart memcached    : service memcached <stop|start|restart>"
    echo    "    To stop/start/restart carbon-cache : <stop|start|restart> carbon-cache"
    echo    "    To stop/start/restart all services : ${appPath}/bin/<stop|start|restart>"
    echo -e "\033[0m"

    exit ${1}
}

function runInstallation()
{
    local login="${1}"
    local password="${2}"
    local email="${3}"

    checkRequireRootUser

    installDependencies
    installGraphite

    configApache
    configGraphite "${login}" "${password}" "${email}"
    configUpstart

    restartServers
}

function main()
{
    appPath="$(cd "$(dirname "${0}")" && pwd)"
    source "${appPath}/lib/util.bash" || exit 1

    local optCount=${#}

    while [[ ${#} -gt 0 ]]
    do
        case "${1}" in
            --help)
                displayUsage 0
                ;;
            --login)
                shift

                if [[ ${#} -gt 0 ]]
                then
                    local login="$(trimString "${1}")"
                fi

                ;;
            --password)
                shift

                if [[ ${#} -gt 0 ]]
                then
                    local password="$(trimString "${1}")"
                fi

                ;;
            --email)
                shift

                if [[ ${#} -gt 0 ]]
                then
                    local email="$(trimString "${1}")"
                fi

                ;;
            *)
                shift
                ;;
        esac
    done

    if [[ "$(isEmptyString ${login})" = 'true' || "$(isEmptyString ${password})" = 'true' ||
          "$(isEmptyString ${email})" = 'true' ]]
    then
        if [[ ${optCount} -gt 0 ]]
        then
            error '\nERROR: login, password, or email parameter not found!'
            displayUsage 1
        fi

        displayUsage 0
    fi

    if [[ "$(isValidEmail ${email})" = 'false' ]]
    then
        error '\nERROR: invalid email!\n'
        exit 1
    fi

    runInstallation "${login}" "${password}" "${email}"
}

main "${@}"

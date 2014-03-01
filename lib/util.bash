#!/bin/bash

function escapeSearchPattern()
{
    echo "$(echo "${1}" | sed "s@\[@\\\\[@g" | sed "s@\*@\\\\*@g" | sed "s@\%@\\\\%@g")"
}

function printHeader()
{
    echo -e "\n\033[1;33m>>>>>>>>>> \033[1;4;35m${1}\033[0m \033[1;33m<<<<<<<<<<\033[0m\n"
}

function error()
{
    echo -e "\033[1;31m${1}\033[0m" 1>&2
}

function trimString()
{
    echo "${1}" | sed -e 's/^ *//g' -e 's/ *$//g'
}

function isEmptyString()
{
    if [[ "$(trimString ${1})" = '' ]]
    then
        echo 'true'
    else
        echo 'false'
    fi
}

function isValidEmail()
{
    local result=$(echo "${1}" | grep -E "^(([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))\.)*([-a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~]+|(\"([][,:;<>\&@a-zA-Z0-9\!#\$%\&\'*+/=?^_\`{\|}~-]|(\\\\[\\ \"]))+\"))@\w((-|\w)*\w)*\.(\w((-|\w)*\w)*\.)*\w{2,4}$")

    if [[ "${result}" = '' ]]
    then
        echo 'false'
    else
        echo 'true'
    fi
}

function checkRequireRootUser()
{
    if [[ "$(whoami)" != 'root' ]]
    then
        error "ERROR: please run this program as 'root'"
        exit 1
    fi
}

function safeCopyFile()
{
    local sourceFilePath="${1}"
    local destinationFilePath="${2}"

    if [[ -f "${sourceFilePath}" ]]
    then
        if [[ -f "${destinationFilePath}" ]]
        then
            mv "${destinationFilePath}" "${destinationFilePath}_$(date +%m%d%Y)_$(date +%H%M%S).BAK"
        fi

        cp "${sourceFilePath}" "${destinationFilePath}"
    fi
}

function safeMoveFile()
{
    local sourceFilePath="${1}"
    local destinationFilePath="${2}"

    if [[ -f "${sourceFilePath}" ]]
    then
        if [[ -f "${destinationFilePath}" ]]
        then
            mv "${destinationFilePath}" "${destinationFilePath}_$(date +%m%d%Y)_$(date +%H%M%S).BAK"
        fi

        mv "${sourceFilePath}" "${destinationFilePath}"
    fi
}

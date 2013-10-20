#!/bin/bash

function escapeSearchPattern
{
    echo "$(echo "${1}" | sed "s@\[@\\\\[@g")"
}

function printHeader
{
    echo -e "\n\033[1;33m>>>>>>>>>> \033[1;4;35m${1}\033[0m \033[1;33m<<<<<<<<<<\033[0m\n"
}

function error
{
    echo -e "\033[1;31m${1}\033[0m" 1>&2
}

function trimString
{
    echo "${1}" | sed -e 's/^ *//g' -e 's/ *$//g'
}

function isEmptyString
{
    if [[ "$(trimString ${1})" = '' ]]
    then
        echo 'true'
    else
        echo 'false'
    fi
}

function checkRequireRootUser
{
    if [[ "$(whoami)" != 'root' ]]
    then
        error "ERROR: please run this program as 'root'"
        exit 1
    fi
}

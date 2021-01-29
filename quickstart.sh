#!/usr/bin/env bash
FILE=.env

if [ ! -f $FILE ]; then
    cp template.env .env
    "Copied 'template.env' to '.env'. Please review the configuration values."
fi

#LOAD_ROUTES=${1:-'-f init-routes.override.yml'}
if [[ -z ${1+x} ]]; then
    LOAD_ROUTES='-f init-routes.override.yml'
else
    LOAD_ROUTES=''
fi
COMMAND=${1:-'up'}

docker-compose  -f docker-compose.yml \
                -f database.override.yml \
                -f konga.override.yml \
                $LOAD_ROUTES \
                $COMMAND \
                ${*:2}

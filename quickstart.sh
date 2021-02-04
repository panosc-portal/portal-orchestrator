#!/usr/bin/env bash
DATABASE=' -f database.override.yml'


while [[ $# -gt 0 ]]
do
key="$1"

case $key in
	-d|--develop)
	DEVELOP='-f develop.override.yml'
	shift
	;;

	-k|--konga)
	KONGA='-f konga.override.yml'
	shift
	;;

	-n|--no-database)
	DATABASE=''
	shift
	;;

	-i|--init-routes)
	INIT_ROUTES='-f init-routes.override.yml'
	shift
	;;

	*)
	break
	;;
esac
done

OTHER_ARGS="$@"

echo $DEVELOP $KONGA $DATABASE $OTHER_ARGS

FILE=.env

if [ ! -f $FILE ]; then
    cp template.env .env
    "Copied 'template.env' to '.env'. Please review the configuration values."
fi

COMMAND=${1:-'up'}

docker-compose  -f docker-compose.yml \
                $DATABASE \
                $KONGA \
				$DEVELOP \
				$INIT_ROUTES \
                $COMMAND \
                ${*:2}

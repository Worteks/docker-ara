#!/bin/sh

ARA_TIME_ZONE=${TZ:-Etc/UTC}
LISTEN_PORT=${LISTEN_PORT:-8080}
if test "$DEBUG"; then
    set -x
    ARA_DEBUG=true
else
    ARA_DEBUG=false
fi
if test -z "$ARA_SECRET_KEY"; then
    echo WARNING: using containers default SECRET_KEY >&2
    echo WARNING: please set your own ARA_SECRET_KEY >&2
    ARA_SECRET_KEY=xTS8ovGeHRMgK6oX9vG8Jib49IG38rjPAG0NCLNKeWEVO8voUm
fi
if test "$ARA_FQDN"; then
    ARA_CORS_ALLOW_ALL=false
else
    ARA_CORS_ALLOW_ALL=true
fi

DB_INITIALIZED=false
cpt=0
if test "$DB_TYPE" = mysql -o "$MYSQL_DB" -o "$MYSQL_HOST"; then
    MYSQL_DB=${MYSQL_DB:-ara}
    MYSQL_HOST=${MYSQL_HOST:-127.0.0.1}
    MYSQL_PASSWORD="${MYSQL_PASSWORD:-secret}"
    MYSQL_PORT=${MYSQL_PORT:-3306}
    MYSQL_USER=${MYSQL_USER:-ara}
    echo -n "Waiting for MySQL backend "
    while true
    do
	if echo SHOW TABLES | mysql -u "$MYSQL_USER" \
		-p "$MYSQL_PASSWORD" -h "$MYSQL_HOST" \
		-p "$MYSQL_PORT" "$MYSQL_DB" >/dev/null 2>&1; then
	    echo " MySQL is alive!"
	    break
	elif test "$cpt" -gt 25; then
	    echo "Could not reach MySQL" >&2
	    exit 1
	fi
	sleep 5
	echo -n .
	cpt=`expr $cpt + 1`
    done
    ARA_DATABASE_ENGINE=django.db.backends.mysql
    ARA_DATABASE_HOST=$MYSQL_HOST
    ARA_DATABASE_NAME=$MYSQL_DB
    ARA_DATABASE_PASSWORD="$MYSQL_PASSWORD"
    ARA_DATABASE_PORT=$MYSQL_PORT
    ARA_DATABASE_USER="$MYSQL_USER"
    if echo 'select * from playbooks' | mysql -u "$MYSQL_USER" \
	    -p "$MYSQL_PASSWORD" -h "$MYSQL_HOST" \
	    -p "$MYSQL_PORT" "$MYSQL_DB" 2>&1 \
	    | grep ansible_version >/dev/null; then
	DB_INITIALIZED=true
    fi
else
    POSTGRES_DB=${POSTGRES_DB:-ara}
    POSTGRES_HOST=${POSTGRES_HOST:-127.0.0.1}
    POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-secret}"
    POSTGRES_PORT=${POSTGRES_PORT:-5432}
    POSTGRES_USER=${POSTGRES_USER:-ara}
    echo -n "Waiting for Postgres backend "
    while true
    do
	if echo '\d' | PGPASSWORD="$POSTGRES_PASSWORD" \
		psql -U "$POSTGRES_USER" -h "$POSTGRES_HOST" \
		-p "$POSTGRES_PORT" "$POSTGRES_DB" >/dev/null 2>&1; then
	    echo " Postgres is alive!"
	    break
	elif test "$cpt" -gt 25; then
	    echo "Could not reach Postgres" >&2
	    exit 1
	fi
	sleep 5
	echo -n .
	cpt=`expr $cpt + 1`
    done
    ARA_DATABASE_ENGINE=django.db.backends.postgresql
    ARA_DATABASE_HOST=$POSTGRES_HOST
    ARA_DATABASE_NAME=$POSTGRES_DB
    ARA_DATABASE_PASSWORD="$POSTGRES_PASSWORD"
    ARA_DATABASE_PORT=$POSTGRES_PORT
    ARA_DATABASE_USER="$POSTGRES_USER"
    if echo 'select * from playbooks' | PGPASSWORD="$POSTGRES_PASSWORD" \
		psql -U "$POSTGRES_USER" -h "$POSTGRES_HOST" \
		-p "$POSTGRES_PORT" "$POSTGRES_DB" 2>&1 \
	    | grep ansible_version >/dev/null; then
	DB_INITIALIZED=true
    fi
fi

mkdir -p /.ara/server
if ! test -s /.ara/server/settings.yaml; then
    sed -e "s|ARA_FQDN|$ARA_FQDN|" \
	-e "s|BINDPORT|$LISTEN_PORT|" \
	-e "s|CORS_ALLOW_ALL|$ARA_CORS_ALLOW_ALL|" \
	-e "s|DBENGINE|$ARA_DATABASE_ENGINE|" \
	-e "s|DBHOST|$ARA_DATABASE_HOST|" \
	-e "s|DBNAME|$ARA_DATABASE_NAME|" \
	-e "s|DBPASSWORD|$ARA_DATABASE_PASSWORD|" \
	-e "s|DBPORT|$ARA_DATABASE_PORT|" \
	-e "s|DBUSER|$ARA_DATABASE_USER|" \
	-e "s|DJANGOSECRET|$ARA_SECRET_KEY|" \
	-e "s|DJANGOTZ|$ARA_TIME_ZONE|" \
	-e "s|DODEBUG|$ARA_DEBUG|" \
	/settings.tpl >/.ara/server/settings.yaml
fi
unset MYSQL_DB MYSQL_HOST MYSQL_PASSWORD MYSQL_PORT MYSQL_USER \
    POSTGRES_DB POSTGRES_HOST POSTGRES_PASSWORD POSTGRES_PORT \
    POSTGRES_USER cpt ARA_CORS_ALLOW_ALL ARA_DATABASE_HOST ARA_DEBUG \
    ARA_DATABASE_NAME ARA_DATABASE_PASSWORD ARA_DATABASE_PORT ARA_SECRET_KEY \
    ARA_CORS_ALLOW_ALL ARA_FQDN ARA_TIME_ZONE

if ! $DB_INITIALIZED; then
    echo Initializing database ...
    /usr/local/bin/ara-manage migrate
    echo Done initializing database
fi

echo Starting ARA
exec /usr/local/bin/ara-manage runserver 0.0.0.0:$LISTEN_PORT

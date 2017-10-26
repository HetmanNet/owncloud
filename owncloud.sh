#!/bin/bash
# Viktor Matvieienko <hetman.net@gmail.com>

SCRIPT=`basename "$0"`
PID=$$
CRON_PATH="/usr/share/owncloud/cron.php"
LOCK_PATH="/srv/owncloud/data/cron.lock"

if [ $USER = "apache" ];
then
	
	logger -t "$SCRIPT[$PID]" "TIMER: start"
	# Пошук файлу блокування одночасного запуску кількох екземплярів owncloud cron
	find $LOCK_PATH -cmin +15 -delete 2> /dev/null
	if [ $? -eq 0 ];
	then
	      	logger -t "$SCRIPT[$PID]" "TIMER: delete cron.lock"
	fi
	
	# Запуск файлу owncloud cron
	logger -t "$SCRIPT[$PID]" "TIMER: run cron.php"
	php -f $CRON_PATH
	logger -t "$SCRIPT[$PID]" "TIMER: end"
	exit 0

else

        logger -t "$SCRIPT[$PID]" "TIMER: Error! No apache user"
        exit 1

fi

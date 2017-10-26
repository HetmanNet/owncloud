#!/bin/bash
# Viktor Matvieienko <hetman.net@gmail.com>
# 2016

SCRIPT_PID=$$
SCRIPT_PPID=$PPID
SCRIPT_NAME=`basename "$0"`

CRON_PATH="/usr/share/owncloud/cron.php"
LOCK_PATH="/srv/owncloud/data/cron.lock"
OCC_PATH="/usr/share/owncloud/occ.php"
PATH_BACKUP="/srv/backup"
PATH_OWNCLOUD="/var/www/html"
$PASSWD_ROOT_MYSQL="passwd"

############################### PRINT ##########################################

# ------------------------ Табуляція рівнів ------------------------------------

# $1 Кількість Tab

function TabL {

    local tabs

    if [ $1 -gt 0 ]
    then
        for ((lvl=3; lvl<=$1; lvl++));
        do
            tabs=$tabs"\t"
        done
    fi

    echo $tabs
    return 0

}

# ---------------------- Декодування кольорів ----------------------------------

# $1 Назва кольору

function EncColor {

    local result

    case "$1" in
        black|bk    ) result=0  ;;
        red|r       ) result=1  ;;
        green|g     ) result=2  ;;
        yellow|y    ) result=3  ;;
        blue|bl     ) result=4  ;;
        purple|p    ) result=5  ;;
        cyan|c      ) result=6  ;;
        white|w     ) result=7  ;;
        lblack|lbk  ) result=60  ;;
        lred|lr     ) result=61  ;;
        lgreen|lg   ) result=62  ;;
        lyellow|ly  ) result=63  ;;
        lblue|lbl   ) result=64  ;;
        lpurple|lp  ) result=65  ;;
        lcyan|lc    ) result=66  ;;
        lwhite|lw   ) result=67  ;;
        *           ) result=7  ;;
    esac

    echo $result
    return 0

}

# -------------------------- Стиль тексту --------------------------------------

# $1 Скорочена назва стилю
# n     - normal (reset all)
# b     - bold
# i     - italic
# u     - underlined
# r     - highlighted
# p     - blink
# $2 Текст

function StyleTXT {

    local MESG
    local style
    local ends

    case "$1" in
        n   )
            style="21;23;24;27;25"
            ends=""
            ;;
        b   )
            style="1"
            ends="21"
            ;;
        i   )
            style="3"
            ends="23"
            ;;
        u   )
            style="4"
            ends="24"
            ;;
        r   )
            style="7"
            ends="27"
            ;;
        p   )
            style="5"
            ends="25"
            ;;
        *   )
            style="21;23;24;27;25"
            ends=""
            ;;
    esac

    for ((arg=2; arg<=$#; arg++));
    do
        MESG=$MESG" "${!arg}
    done

    echo "\e["$style"m"$MESG"\e["$ends"m"
    return 0

}

# -------------------------- Колір тексту --------------------------------------

# $1 Назва кольору
# $2 Текст

function ColorTXT {

    local MESG
    local color=$(EncColor $1)

    for ((arg=2; arg<=$#; arg++));
    do
        MESG=$MESG" "${!arg}
    done

    let " color = $color + 30 "

    echo "\e["$style"m"$MESG"\e[39m"
    return 0

}

# ------------------------ Колір фону тексту -----------------------------------

# $1 Назва кольору
# $2 Текст

function ColorBgTXT {

    local MESG
    local color=$(EncColor $1)

    for ((arg=2; arg<=$#; arg++));
    do
        MESG=$MESG" "${!arg}
    done

    let " color = $color + 40 "

    echo "\e["$style"m"$MESG"\e[49m"
    return 0

}

################################ LOG ###########################################

# ------------- Формування заголовку строки для запису у лог -------------------

function HStr {

    local result

    result=$SCRIPT_NAME[$SCRIPT_PID]
    echo $result

    return 0
}

# ---------- Формування початку строки для запису у власний лог ----------------

function PrStr {

    local result

    result=`date "+%b %d %H:%M:%S"`"\t"`cat /etc/hostname`"\t$(HStr)\t"
    echo $result

    return 0
}

# Рівень деталізації логу по умовчанню
LOG_LEVEL_SCRIPT="2"
# Початковиц рівень вкладення повідомлень
TAB_LEVEL=0
# --------- Декодування назви рівня деталізації ведення логу в число -----------

# $1 Назва рівня деталізації логу

function EncLogLevel {

    local result
    if [ $# -gt 0 ]
    then
        case "$1" in
            DEBUG   )   result=0 ;;
            INFO    )   result=1 ;;
            ERROR   )   result=2 ;;
            *       )
                        echo "EncLogLevel: Error! Function EncLogLevel. Invalid argument ."
                        exit 128
                        ;;
        esac
        echo $result
    else
        echo "EncLogLevel: Error! Function EncLogLevel. No arguments to decode."
        exit 128
    fi

    return 0
}

# ------------------------------- Запис до логу --------------------------------

# $1 Тип повідомлення (рівень деталізації): DEBUG, INFO, ERROR
# $2 Назва процесу: INSTALL, HELP, CRON and etc.
# $3 Повідомлення

function Log {

    local LOG_LEVEL_MESG=$(EncLogLevel $1)
    local SCRIPT_MODE=$2
    local MESG
    for ((arg=3; arg<=$#; arg++));
    do
        MESG=$MESG" "${!arg}
    done
    local color

    if [ $LOG_LEVEL_MESG -ge $LOG_LEVEL_SCRIPT ]
    then
        logger -t "$(HStr)" "$SCRIPT_MODE $1: $MESG!"
        if [ $? -ne 0 ]
        then
            echo -e "$(PrStr) $(TabL $TAB_LEVEL) $(ColorBgTXT red "Error! Can not write to the log system.")"
            echo -e "$(PrStr) $SCRIPT_MODE $1: $MESG!" >> /var/log/$SCRIPT_NAME.log
            echo -e "$(PrStr) $SCRIPT_MODE ERROR: Can not write to the log system.!" >> /var/log/$SCRIPT_NAME.log
            if [ $? -ne 0 ]
            then
                echo -e "$(PrStr) $(TabL $TAB_LEVEL) $(ColorBgTXT red "ERROR! Can not create a log in the /var/log.")"
                echo -e "$(PrStr) $SCRIPT_MODE $1: $MESG!" >> ./$SCRIPT_NAME.log
                echo -e "$(PrStr) $SCRIPT_MODE ERROR! Can not create a log in the /var/log." >> ./$SCRIPT_NAME.log
                if [ $? -ne 0 ]
                then
                     echo -e "$(PrStr) $(TabL $TAB_LEVEL) $(ColorBgTXT red "Error! Can not create a log in the current folder.")"
                     exit 2
                fi
                exit 2
            fi
        fi

        # Друк повідомлень відлагодження

        if [ $LOG_LEVEL_SCRIPT -eq 0 ]
        then

            if [ $1 = "ERROR" ]
            then
                color="red"
            else
                color="white"
            fi

            echo -e "$(PrStr) $(TabL $TAB_LEVEL) $(StyleTXT b $SCRIPT_MODE $(ColorBgTXT red $1)):\t $MESG!"

            if [ $MESG = "START" ]
            then
                let "TAB_LEVEL = $TAB_LEVEL + 1"
            elif [ $MESG = "END." ]
            then
                let "TAB_LEVEL = $TAB_LEVEL + 1"
            fi
        fi

    fi

    return 0

}

################################### HELP #######################################

# ---------------------------- Вивід довідки -----------------------------------

function PrintHelp {
    exit 0
}

#
# Визначення релізу лінукс
#

################################## SYSTEM ######################################

function DetectRelease {

    Log DEBUG DetectRelease START

    # Пошук інформації про реліз
    if [ -r "/etc/os-release" ]
    then
        source /etc/os-release
        $DIST_OS=$ID
        $VERS_OS=$VERSION_ID
        return 0
    elif [ -r "/usr/lib/os-release" ]
    then
        source /usr/lib/os-release
        $DIST_OS=$ID
        $VERS_OS=$VERSION_ID
        return 0
    else
        Log ERROR "no detect os release!"
        exit 1
    fi

    if [ $DIST_OS = "Fedora" ]
    then
        APACHE_USER="apache"
        NGINX_USER="nginx"
    else
        Log ERROR "no detect os release!"
    fi

    Log DEBUG DetectRelease END.

}


WEB_SERVER_NAME="apache"
################################### RUN ########################################

# $1 Ім'я користувача від якого виконується команда
# $2 Команда з аргументами

function Run {

    Log DEBUG Run START

    local user
    local web_var
    if [ $1 = web ]
    then
        WEB_SERVER_NAME=${WEB_SERVER_NAME^^}
        user=
    fi

    for ((arg=2; arg<=$#; arg++));
    do
        CMD=$CMD" "${!arg}
    done
    Log DEBUG Run "USER: $(id -u -n $UID), CMD: $CMD"

    local CUSER=`id -u $1`
    if [ $? -ne 0 ]
    then
        Log ERROR Run "not exists user"
        exit 128
    fi

    if [ $UID -eq $APACHE_ID ]
    then
        eval $@
    elif [ $UID -eq 0 ]
    then
        sudo -u apache $@
    else
        Log ERROR RunCron "Error! No apache or root user"
        exit 2
    fi

    if [ $? -ne 0 ]
    then
        Log ERROR Run "$@"
        exit 1
    else
        Log DEBUG Run "$@"
    fi

    Log DEBUG Run END.
    return 0

}

################################## UPGRADE #####################################

# -------------- Функція запуску процесу оновлення Owncloud --------------------

function RunUpgrade {

    Log DEBUG RunUpgrade START
    Log DEBUG RunUpgrade USER:$(id -u -n $UID)
    Log INFO UPGRADE "OWNCLOUD: maintenance mode on.."

    Run php $OCC_PATH maintenance:mode --on
    Run php $OCC_PATH upgrade
    Run php $OCC_PATH maintenance:mode --off

    Log INFO UPGRADE "OWNCLOUD: maintenance mode off.."
    Log INFO UPGRADE completed.
    Log DEBUG RunUpgrade END.
}

#################################### CRON ######################################

# --------------------- Функція запуску OwnCloud cron --------------------------

function RunCron {

    Log DEBUG RunCron START
    Log DEBUG RunCron USER:$(id -u -n $UID)

    # Пошук файлу блокування одночасного запуску кількох екземплярів owncloud cron
    find $LOCK_PATH -cmin +15 -delete 2> /dev/null
    if [ $? -eq 0 ]
    then
        Log INFO TIMER "delete old cron.lock"
    fi

    Run php -f $CRON_PATH

    Log INFO TIMER completed.
    Log DEBUG RunCron END.
    exit 0
}

#################################### BACKUP ####################################

# --------------- Функція резервного копіювання для OwnCloud -------------------

function RunBackup
{

    Log DEBUG BACKUP RunBackup

    Log INFO BACKUP "OWNCLOUD: maintenance mode on.."
    Run php /var/www/html/occ maintenance:mode --on

    logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "SEARCH: old backup.."
    FOUND=`find $PATH_BACKUP/owncloud/mariadb-*.sql.gz -mtime +7 2>/dev/null | wc -l`
    if [ $FOUND -ne 0 ];
    then
        logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "FOUND: $FOUND old backup."
        find $PATH_BACKUP/owncloud/mariadb-*.sql.gz -mtime +7 -delete
        if [ $? -eq 0 ];
        then
                logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "DELETE: old backup."
        else
                logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "ERROR!"
                exit 1
        fi
    else
        logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "NOT FOUND: old backup"
    fi
    logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "CREATION: db backup.."
    mysqldump -u root -p"$PASSWD_ROOT_MYSQL" -A | gzip -9 -c > $PATH_BACKUP/owncloud/mariadb-`date "+%Y-%m-%d-%H-%M-%S"`.sql.gz
    logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "CREATED: db backup."

    logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "SEARCH: owncloud backup.."
    FOUND=`find $PATH_BACKUP/owncloud/owncloud-*.zip -mtime +7 2>/dev/null | wc -l`
    if [ $FOUND -ne 0 ];
    then
        logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "FOUND: $FOUND old owncloud backup."
        find $PATH_BACKUP/owncloud/owncloud-*.zip -mtime +7 -delete
        if [ $? -eq 0 ];
        then
                logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "DELETE: old owncloud backup."
        else
                logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "ERROR!"
                exit 1
        fi
    else
        logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "NOT FOUND: old owncloud backup"
    fi
    logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "CREATION: owncloud backup.."
    zip -9 -r $PATH_BACKUP/owncloud/owncloud-`date "+%Y-%m-%d-%H-%M-%S"`.zip $PATH_OWNCLOUD 2>/dev/null
    logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "CREATED: owncloud backup."

    sudo -u apache php /var/www/html/occ maintenance:mode --off
    logger -t "$SCRIPT_NAME[$SCRIPT_PID]" "OWNCLOUD: maintenance mode off.."

    exit 0
}

#
# Тіло скрипта
#

if [ $SCRIPT_NAME = "owncloud-cron" ]
then
	RunCron
elif [ $SCRIPT_NAME = "owncloud-backup" ]
then
	RunBackup
elif [ $SCRIPT_NAME = "owncloud-upgrade" ]
then
	RunUpgrade
else
	PrintHelp
fi

if [ $# -gt 0 ]
then
    for ((arg=1; arg<=$#; arg++));
    do
        if [ ${!arg:0:2} = "--" ]
        then

        fi
        import[$arg]=${!arg}

    done
fi

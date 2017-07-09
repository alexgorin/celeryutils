#!/usr/bin/env bash
# Utility that allows to quickly apply changes to celery workers
# Author: Alex Gorin, alex.gorin@tophatmonocle.com

QUEUES_TO_PURGE=
CHECK_CELERY_MONITORING=
RESTART_APP=
RESTART_ALL=
RELOAD_CELERY_WORKERS=

function show_help() {
	cat << EOF
Applies changes made to Celery tasks.
Arguments:
	-h: Show this help message
	-q QUEUE_NAMES: Comma-separated list of rabbitmq queues to purge. Default - 'all' (purge all queues)
	-m: Check celery events monitoring
	-c: Reload Celery workers by sending HUP signal
	-r: Restart the application ('re')
	-R: Restart all ('rere')
	-s: Start all
	-s: Stop all
	-a: Shortcut for -m -q all
EOF
}

function items() {
	COMMA_SEPARATED_ITEMS=$1
	echo $COMMA_SEPARATED_ITEMS | tr "," "\n"
}

function queues_list() {
	sudo rabbitmqctl list_queues | grep -v Listing | awk '{print $1}'
}

function purge_queues() {
	QUEUES_TO_PURGE=$1
	if [ -n "$QUEUES_TO_PURGE" ]; then
		stop_all
		if [ "$QUEUES_TO_PURGE" == "all" ]; then
			# Alternative - ./manage.py celery amqp queue.purge {}
			queues_list | xargs -I {} sudo rabbitmqctl purge_queue {}
		else
			items $QUEUES_TO_PURGE | xargs -I {} sudo rabbitmqctl purge_queue {}
		fi
		start_all
	fi
}

function check_celery_events_monitoring() {
	if ps aux | grep "manage.py\ celery\ events"; then
		echo "Celery tasks monitoring is running"
	else
		echo "Celery tasks monitoring is not running. Try running './manage.py celery events' in a separate tab."
	fi
}

function reload_celery_workers() {
	ps auxww | grep 'celery worker' | awk '{print $2}' | xargs kill -HUP
}

function restart_celery_workers() {
	sudo supervisorctl restart workers:
}

function re() {
	sudo supervisorctl restart webserver:app_tophat
}

function rere() {
	sudo supervisorctl restart all
}

function start_all() {
	sudo supervisorctl start all
}

function stop_all() {
	sudo supervisorctl stop all
}

OPTIND=1 # Variable used by getopts. Don't touch.
while getopts "marchRqsS:" opt; do
	case "$opt" in
	h)
		show_help
		exit 0
		;;
	q)
		purge_queues $OPTARG
		;;
	m)
		check_celery_events_monitoring
		;;
	c)
		reload_celery_workers
		;;
	r)
		re
		;;
	R)
		rere
		;;
	s)
		start_all
		;;
	S)
		stop_all
		;;
	a)
		check_celery_events_monitoring
		purge_queues all
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		show_help
		exit 1
		;;
	esac
done


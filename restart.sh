#!/usr/bin/env bash
# Utility that allows to quickly apply changes to celery workers
# Author: Alex Gorin, alex.gorin@tophatmonocle.com
MANAGE_PY=${MANAGE_PY:-/vagrant/manage.py}
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
	-S: Stop all
	-w QUEUE_NAMES: Start queue workers
	-W QUEUE_NAMES: Stop queue workers
	-a: Shortcut for -m -S -q all -s
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
		if [ "$QUEUES_TO_PURGE" == "all" ]; then
			# Alternative - sudo rabbitmqctl purge_queue {}
			queues_list | xargs -I {} $MANAGE_PY celery amqp queue.purge {}
		else
			items $QUEUES_TO_PURGE | xargs -I {} $MANAGE_PY celery amqp queue.purge {}
		fi
	fi
}

function check_celery_events_monitoring() {
	if ps aux | grep "manage.py\ celery\ events" >/dev/null 2>&1; then
		echo "Celery tasks monitoring is running"
	else
		echo "Celery tasks monitoring is not running. Try running './manage.py celery events' in a separate tab."
	fi
}

function reload_celery_workers() {
	echo "Sending HUP to Celery workers"
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

function stop_queue_workers() {
	QUEUES=$1
	if [ -n "$QUEUES" ]; then
		if [ "$QUEUES" == "all" ]; then
			# Alternative - ./manage.py celery amqp queue.purge {}
			sudo supervisorctl stop worker:
		else
			items $QUEUES | xargs -I {} sudo supervisorctl stop worker:{}
		fi
	fi
}

function start_queue_workers() {
	QUEUES=$1
	if [ -n "$QUEUES" ]; then
		if [ "$QUEUES" == "all" ]; then
			# Alternative - ./manage.py celery amqp queue.purge {}
			sudo supervisorctl start worker:
		else
			items $QUEUES | xargs -I {} sudo supervisorctl start worker:{}
		fi
	fi
}

OPTIND=1 # Variable used by getopts. Don't touch.
while getopts "marchRq:w:W:sS" opt; do
	case "$opt" in
	h)
		show_help
		exit 0
		;;
	q)
		purge_queues $OPTARG
		;;
	W)
		stop_queue_workers $OPTARG
		;;
	w)
		start_queue_workers $OPTARG
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
		stop_all
		purge_queues all
		start_all
		;;
	\?)
		echo "Invalid option: -$OPTARG" >&2
		show_help
		exit 1
		;;
	esac
done


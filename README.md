# Celery utils
This script is meant to help reload celery tasks to pick up the changes.
Currently it is in experimental mode.

## Usage
Each CLI option represents one action. The actions will be performed in the same order as the options are present (so the order of the options matters)

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

## Examples
 - ```celeryutils/restart.sh -W celery_email -q email -w celery_email``` - purge email queue and restart corresponding workers
 - ```celeryutils/restart.sh -q all``` - purge all queues
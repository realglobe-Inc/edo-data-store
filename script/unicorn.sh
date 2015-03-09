#!/bin/bash

. $(cd $(dirname $0) && pwd)/rails_script.sh
. $(cd $(dirname $0) && pwd)/god_script.sh

case $1 in
    start|stop|load|restart|reload)
        god_action unicorn $@
        ;;
    *)
        echo "invalid action $1"
        ;;
esac

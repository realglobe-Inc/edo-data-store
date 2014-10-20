#!/bin/bash

. $(cd $(dirname $0) && pwd)/rails_script.sh
. $(cd $(dirname $0) && pwd)/god_script.sh

function precompile_assets() {
    echo "precompile assets? (type 'y' to compile)"
    read answer
    if [ ${answer:=""} = y ]; then
        bundle exec rake assets:precompile
    fi
}

case $1 in
    start|load|restart|reload)
        precompile_assets
        god_action unicorn $@
        ;;
    *)
        god_action unicorn $@
        ;;
esac

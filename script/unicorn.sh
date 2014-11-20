#!/bin/bash

. $(cd $(dirname $0) && pwd)/rails_script.sh
. $(cd $(dirname $0) && pwd)/god_script.sh

function precompile_assets() {
    echo "precompile assets..."
    bundle exec rake assets:precompile
    echo "done."
}

case $1 in
    start|load|restart|reload)
        precompile_assets
        god_action unicorn $@
        ;;
    stop|*)
        god_action unicorn $@
        ;;
esac

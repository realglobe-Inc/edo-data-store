#!/bin/bash

export RAILS_ROOT=$(cd $(dirname $(dirname $0)) && pwd)
function rails_env_check() {
    echo "skip"
    env
}

. $(cd $(dirname $0) && pwd)/god_script.sh

case $1 in
    start|stop|load|*)
        god_action redis $@
        ;;
esac

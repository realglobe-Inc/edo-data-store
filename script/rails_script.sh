#!/bin/bash

export RAILS_ROOT=$(cd $(dirname $(dirname $0)) && pwd)

function rails_env_check() {
    if [ ! ${RAILS_ENV} ]; then
        echo "***** error *****"
        echo "RAILS_ENV is not set"
        echo "env RAILS_ENV=xxx $0"
        exit 1
    fi
}

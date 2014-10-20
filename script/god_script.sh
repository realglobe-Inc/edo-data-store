#!/bin/bash

function port_check() {
    if [ ! ${GOD_PORT} ]; then
        echo "***** error *****"
        echo "GOD_PORT is not set"
        echo "env GOD_PORT=xxx $0"
        exit 1
    fi
}

function start_god() {
    god_config_file=$1
    god_pid_file=${RAILS_ROOT}/tmp/pids/god_${GOD_PORT}.pid
    god_log_file=${RAILS_ROOT}/log/god.log

    port_check
    rails_env_check

    if bundle exec god status -p ${GOD_PORT}; then
        echo "***** error *****"
        echo "port ${GOD_PORT} is already used"
        exit 1
    fi

    bundle exec god -c ${god_config_file} -p ${GOD_PORT} -P ${god_pid_file} -l ${god_log_file}
}

function stop_god() {
    task_name=$1

    port_check

    bundle exec god stop ${task_name} -p ${GOD_PORT}
    bundle exec god remove ${task_name} -p ${GOD_PORT}
}

function restart_task() {
    task_name=$1

    port_check

    bundle exec god restart ${task_name} -p ${GOD_PORT}
}

function load_god {
    god_script_file=$1

    if ! bundle exec god status -p ${GOD_PORT}; then
        echo "***** error *****"
        echo "port ${GOD_PORT} is not used"
        exit 1
    fi

    bundle exec god load ${god_script_file} -p ${GOD_PORT}
}

function switch_god() {
    task_name=$1
    god_script_file=$2
    old_port=$3
    new_port=$4

    if ! bundle exec god status -p ${old_port}; then
        echo "***** error *****"
        echo "port ${old_port} is not used"
        exit 1
    fi
    if ! bundle exec god status ${task_name} -p ${old_port}; then
        echo "***** warning *****"
        echo "task ${task_name} on port ${old_port} is not monitored"
    fi
    if ! bundle exec god status -p ${new_port}; then
        echo "***** error *****"
        echo "task ${task_name} on port ${new_port} is already monitored"
        exit 1
    fi

    bundle exec god remove ${task_name} -p ${old_port}
    bundle exec god load ${god_script_file} -p ${new_port}
}

function god_action() {
    task_name=$1
    action_name=$2
    god_config_file=${RAILS_ROOT}/script/${task_name}.god

    cd ${RAILS_ROOT}

    case ${action_name} in
        start)
            echo "Starting ${task_name}..."
            start_god ${god_config_file}

            echo "Done"
            ;;
        stop)
            echo "Stopping ${task_name}..."
            stop_god ${task_name}

            echo "Done"
            ;;
        load)
            echo "Loading ${task_name}..."
            load_god ${god_config_file}

            echo "Done"
            ;;
        switch)
            old_port=$3
            new_port=$4

            echo "Switching ${task_name} monitoring port from ${old_port} to ${new_port} ..."
            switch_god ${task_name} ${god_config_file} ${old_port} ${new_port}

            echo "Done"
            ;;
        restart|reload)
            echo "Restarting ${task_name}..."
            restart_task ${task_name}

            echo "Done"
            ;;
        *)
            echo "unknown action"
            exit 1
            ;;
    esac
}

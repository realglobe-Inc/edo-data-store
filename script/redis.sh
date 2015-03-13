#!/bin/bash

# Copyright 2015 realglobe, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

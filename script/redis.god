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

require "#{RAILS_ROOT}/script/shared.god"

set_default_email_sender("redis")

God.watch do |w|
  set_default_watching(w)

  redis_root = "/home/azureuser/redis"

  w.name = "redis"
  w.pid_file = "#{redis_root}/redis.pid"

  w.start = "cd #{redis_root} && #{redis_root}/redis-server #{redis_root}/redis.conf"
  w.stop = "kill -QUIT `cat #{w.pid_file}`"

  options = GOD_DEFAULT_OPTIONS
  generic_monitoring(w, options)
end

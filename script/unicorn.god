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

RAILS_ROOT = ENV["RAILS_ROOT"]
RAILS_ENV = ENV["RAILS_ENV"]
unicorn_conf_file = "#{RAILS_ROOT}/config/unicorn.conf"

require "#{RAILS_ROOT}/script/shared.god"

set_default_email_sender("unicorn")

God.watch do |w|
  set_default_watching(w)

  w.name = "unicorn"
  w.pid_file = File.join(RAILS_ROOT, "/tmp/pids/rails.pid")

  w.start = "bundle exec unicorn_rails -c #{unicorn_conf_file} -E #{RAILS_ENV} -D"
  w.stop = "kill -QUIT `cat #{w.pid_file}`"
  w.restart = "kill -USR2 `cat #{w.pid_file}`"

  options = GOD_DEFAULT_OPTIONS
  generic_monitoring(w, options)
end

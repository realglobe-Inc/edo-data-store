#--
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
#++

FactoryGirl.define do
  stored_at = Time.now
  factory "test_statement", :class => Statement.with_collection(user_uid: "user_xxx", service_uid: "service_xxx") do
    id "xxx-xxx-xxx-xxx"
    actor ({mbox: "oku@realglobe.jp"})
    verb ({id: "http://realglobe.jp", display: {"en-US" => "did"}})
    object ({id: "http://realglobe.jp/test"})
    stored stored_at
    timestamp stored_at
  end
end

(1..9).each do |i|
  case i
  when 1..2
    user_id = "user_001"
    service_id = "service_001"
  when 3..6
    user_id = "user_001"
    service_id = "service_002"
  else
    user_id = "user_002"
    service_id = "service_001"
  end

  FactoryGirl.define do
    stored_at = Time.now - i
    factory "statement_00#{i}", :class => Statement.with_collection(user_uid: user_id, service_uid: service_id) do
      actor ({mbox: "oku@realglobe.jp"})
      verb ({id: "http://realglobe.jp", display: {"en-US" => "did"}})
      object ({id: "http://realglobe.jp/#{i}"})
      stored stored_at
      timestamp stored_at
    end
  end
end

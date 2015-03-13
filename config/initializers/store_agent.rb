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

StoreAgent.configure do |c|
  c.storage_root = File.expand_path(GlobalSettings.personal_cloud_dir)
  c.version_manager = StoreAgent::VersionManager::RuggedGit
  c.storage_data_encoders = [] <<
    StoreAgent::DataEncoder::GzipEncoder.new <<
    StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
  c.attachment_data_encoders = [] <<
    StoreAgent::DataEncoder::GzipEncoder.new <<
    StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
  c.json_indent_level = 2
end

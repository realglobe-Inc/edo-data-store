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

class ServicesController < ApplicationController
  include StorageManager
  include ContentTypeChecker
  include ResponseJsonNotificationsAdder

  before_action :require_content_type_json, only: %w(create)
  before_action :validates_user_to_be_superuser
  before_action :validates_user_to_be_present
  before_action :validates_service_to_be_present, only: %w(destroy)
  before_action :validates_service_to_be_absent, only: %w(create)

  def index
    render json: service_root.read# {status: :ok, data: {services: service_root.read}}
  end

  def create
    service_root.create do |root_dir|
      root_dir.initial_owner = storage_user_identifier
      root_dir.initial_permission = {
        storage_user_identifier => StoreAgent.config.default_owner_permission
      }
    end
    @current_user = @workspace = @service_root = nil
    service_root.file(".statements").create
    render nothing: true, status: 201
  end

  def destroy
    service_root.delete
    render nothing: true, status: 204
  end
end

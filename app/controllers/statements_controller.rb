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

class StatementsController < ApplicationController
  include ResponseJsonNotificationsAdder
  include ResponseJsonTemplateRenderer
  include StorageManager
  include StatementBuilder

  before_action :check_read_permission, only: %w(index)
  before_action :check_write_permission, only: %w(create)
  before_action :build_new_statement, only: %w(create)
  before_action :render_error_response, only: %w(create)

  def index
    statements = Statement.with_collection(user_uid: params[:user_uid], service_uid: params[:service_uid]).all
    response.header["X-Experience-API-Consistent-Through"] = Time.now.iso8601
    if params[:attachments] == "true"
      content_type, response_body = build_multipart_statement_response(statements)
      send_data response_body, type: content_type, disposition: :inline
    else
      render json: statements.map(&:properties)
    end
  end

  def users_index
    service_uids = params[:service_uids].split(",")
    statements = get_last_statements(user_uid: params[:user_uid], service_uids: service_uids)
    render json: statements
  end

  def last_statements
    user_uids = params[:user_uids].split(",")
    service_uids = params[:service_uids].split(",")
    statements = user_uids.inject({}) do |r, user_uid|
      r[user_uid] = get_last_statements(user_uid: user_uid, service_uids: service_uids)
      r
    end
    render json: statements
  end

  def create
    if Statement.with_collection(user_uid: params[:user_uid], service_uid: params[:service_uid]).where(id: @statement.id).present?
      render json_template: :duplicated_id, template_params: {id: @statement.id}, status: 409
    elsif @statement.save
      Statement.with(collection: @statement.collection_name).create_indexes
      render text: @statement.id
    else
      render_error_response
    end
  end

  private

  def search_params
    params.permit(:user_uid, :service_uid, :attachments)
  end

  def check_read_permission
    if !service_root.file(".statement").permission.allow?("read")
      render json_template: :permission_denied, status: 403
    end
  end

  def check_write_permission
    if !service_root.file(".statement").permission.allow?("write")
      render json_template: :permission_denied, status: 403
    end
  end

  def build_new_statement
    case request.content_type
    when "application/json"
      @statement = Statement.build_simple(user_uid: params[:user_uid], service_uid: params[:service_uid], json_string: request.raw_post)
    when "multipart/mixed"
      @statement = Statement.build_mixed(user_uid: params[:user_uid], service_uid: params[:service_uid], multipart_body: request.raw_post, content_type: request.headers["Content-Type"])
    else
      render json_template: :invalid_content_type, template_params: {content_type: "application/json または multipart/mixed"}, status: 400
    end
  end

  def get_last_statements(user_uid: "", service_uids: [])
    service_uids.inject({}) do |r, service_uid|
      statements = Statement.with_collection(user_uid: user_uid, service_uid: service_uid).limit(1)
      r[service_uid] = statements.first.try(:properties)
      r
    end
  end

  def render_error_response
    if @statement.errors.present?
      render json_template: :invalid_statement_value, descriptions: @statement.errors.full_messages, status: 400
    end
  end
end

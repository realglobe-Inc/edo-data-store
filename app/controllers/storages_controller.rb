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

class StoragesController < ApplicationController
  include ContentTypeChecker
  include StorageManager
  include ResponseJsonNotificationsAdder
  include ResponseJsonTemplateRenderer

  before_action :require_content_type_json, only: %w(set_permissions unset_permissions)
  before_action :validates_user_to_be_superuser, only: %w(permissions set_permissions unset_permissions)
  before_action :validates_user_to_be_present
  before_action :validates_service_to_be_present
  before_action :validates_object_to_be_present, only: %w(remove_directory remove_file copy move permissions set_permissions unset_permissions)
  before_action :validates_object_to_be_present_if_no_revision, only: %w(list_files read_file)
  before_action :validates_object_to_be_directory, only: %w(list_files remove_directory)
  before_action :validates_object_to_be_not_directory, only: %w(write_file)
  before_action :validates_object_to_be_file, only: %w(remove_file)
  before_action :validates_object_to_be_file_if_no_revision, only: %w(read_file)
  before_action :validates_object_to_be_absent, only: %w(make_directory)
  before_action :validates_parent_to_be_present, only: %w(make_directory write_file)
  before_action :validates_dest_object_to_be_writable, only: %w(copy move)
  before_action :check_target, only: %w(set_permissions unset_permissions)

  def list_files
    filenames = directory.read
    reject_parameters = %w(owner directory_size_limit directory_bytes_limit)
    file_list = filenames.map do |filename|
      if params["metadata"] == "true"
        file = directory.find_object(filename)
        metadata = file.get_metadata.reject{|key, value| reject_parameters.include?(key)}
        {name: filename}.merge(metadata)
      else
        {
          name: filename,
          is_dir: File.directory?("#{directory.storage_object_path}#{filename}")
        }
      end
    end
    render json: file_list
  end

  def make_directory
    directory.create
    render nothing: true, status: 201
  end

  def remove_directory
    directory.delete
    render nothing: true, status: 204
  end

  def read_file
    send_data file.read(revision: params[:revision])
  rescue StoreAgent::InvalidRevisionError => e
    render json: {status: :error, message: "invalid revision '#{params[:revision]}' to #{params[:path]}"}, status: 403
  end

  def write_file
    file_body = request.raw_post
    case
    when !file.exists?
      file.create(file_body)
      render nothing: true, status: 201
    when !object.file?
      validates_object_to_be_file
    when params[:overwrite] != "true"
      cannot_overwrite_error(params[:path])
    else
      file.update(file_body)
      render nothing: true
    end
  end

  def remove_file
    file.delete
    render nothing: true, status: 204
  end

  def copy
    object.copy(dest_path)
    render nothing: true
  end

  def move
    object.move(dest_path)
    render nothing: true
  end

  def permissions
    render json: object.get_permissions["users"]
  end

  def set_permissions
    object.set_permission(identifier: @target, permission_values: params[:permissions])
    render json: object.get_permissions["users"]
  end

  def unset_permissions
    object.unset_permission(identifier: @target, permission_names: params[:permissions])
    render json: object.get_permissions["users"]
  end

  def revisions
    render json: object.revisions
  end

  private

  def object
    @object ||= service_root.find_object(params[:path])
  end

  def dest_object
    workspace.find_object(dest_path)
  end

  def dest_path
    service_root.file(params[:dest_path]).path
  end

  def directory
    @directory ||= service_root.directory(params[:path])
  end

  def file
    @file ||= service_root.file(params[:path])
  end

  def validates_object_to_be_present
    if !object.exists?
      render json_template: :resource_not_found, template_params: {path: params[:path]}, status: 404
    end
  end

  def validates_object_to_be_present_if_no_revision
    if !params[:revision]
      validates_object_to_be_present
    end
  end

  def validates_object_to_be_absent
    if object.exists?
      render json_template: :resource_already_exists, template_params: {path: params[:path]}, status: 409
    end
  end

  def validates_object_to_be_directory
    if !object.directory?
      render json_template: :is_not_directory, template_params: {path: params[:path]}, status: 403
    end
  end

  def validates_object_to_be_not_directory
    if object.directory?
      render json_template: :is_directory, template_params: {path: params[:path]}, status: 403
    end
  end

  def validates_object_to_be_file
    if !object.file?
      render json_template: :is_not_file, template_params: {path: params[:path]}, status: 403
    end
  end

  def validates_object_to_be_file_if_no_revision
    if !params[:revision]
      validates_object_to_be_file
    end
  end

  def validates_parent_to_be_present
    parent = object.parent_directory
    if !parent.exists?
      render json_template: :resource_not_found, template_params: {path: File.dirname(params[:path])}, status: 404
    end
  end

  def validates_dest_object_to_be_writable
    case
    when !dest_object.exists?
    when dest_object.directory?
      render json_template: :directory_already_exists, template_params: {dest_path: params[:dest_path]}, status: 409
    when object.directory?
      render json_template: :con_not_copy_directory_to_file, template_params: {path: params[:path], dest_path: params[:dest_path]}, status: 409
    when params[:overwrite] != "true"
      cannot_overwrite_error(params[:dest_path])
    end
  end

  def check_target
    params.require(:target_user)
    params.require(:target_service)
    @target = "#{params[:target_user]}:#{params[:target_service]}"
  rescue
    render json_template: :required_target_params, status: 400
  end

  def cannot_overwrite_error(path)
    render json_template: :overwrite_is_not_true, template_params: {path: params[:path]}, status: 403
  end
end

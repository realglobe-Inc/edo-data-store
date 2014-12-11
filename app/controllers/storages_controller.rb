class StoragesController < ApplicationController
  include ContentTypeChecker
  include StorageManager
  include ResponseJsonNotificationsAdder

  before_action :require_content_type_json, only: %w(set_permissions unset_permissions)
  before_action :validates_user_to_be_superuser, only: %w(permissions set_permissions unset_permissions)
  before_action :validates_user_to_be_present
  before_action :validates_service_to_be_present
  before_action :validates_object_to_be_present, only: %w(list_files remove_directory read_file remove_file copy move permissions set_permissions unset_permissions)
  before_action :validates_object_to_be_directory, only: %w(list_files remove_directory)
  before_action :validates_object_to_be_not_directory, only: %w(write_file)
  before_action :validates_object_to_be_file, only: %w(read_file remove_file)
  before_action :validates_object_to_be_absent, only: %w(make_directory)
  before_action :validates_parent_to_be_present, only: %w(make_directory write_file)
  before_action :check_target, only: %w(set_permissions unset_permissions)

  def list_files
    filenames = object.read
    if params["metadata"] || true
      file_list = filenames.map do |filename|
        file = object.find_object(filename)
        metadata = file.get_metadata
        {name: filename}.merge(metadata)
      end
    else
      file_list = filenames.map{|filename| {name: filename}}
    end
    render json: file_list
  end

  def make_directory
    directory.create
    render json: {status: :ok, data: {directory: directory.path}}, status: 201
  end

  def remove_directory
    object.delete
    render json: {status: :ok, data: {result: true}}
  end

  def read_file
    send_data object.read
  end

  def write_file
    file_body = request.raw_post
    if file.exists?
      file.update(file_body)
      status_code = 200
    else
      file.create(file_body)
      status_code = 201
    end
    render json: {status: :ok, data: {path: file.path, size: file.metadata.disk_usage}}, status: status_code
  end

  def remove_file
    object.delete
    render json: {status: :ok, data: {result: true}}
  end

  def copy
    object.copy(dest_path)
    render json: {status: :ok, data: {result: true}}
  end

  def move
    object.move(dest_path)
    render json: {status: :ok, data: {result: true}}
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

  private

  def object
    @object ||= service_root.find_object(params[:path])
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
      render json: {status: :error, message: "#{params[:path]} not found"}, status: 404
    end
  end

  def validates_object_to_be_absent
    if object.exists?
      render json: {status: :error, message: "#{params[:path]} is already exists"}, status: 403
    end
  end

  def validates_object_to_be_directory
    if !object.directory?
      render json: {status: :error, message: "#{params[:path]} is not directory"}, status: 403
    end
  end

  def validates_object_to_be_not_directory
    if object.directory?
      render json: {status: :error, message: "#{params[:path]} is directory"}, status: 403
    end
  end

  def validates_object_to_be_file
    if !object.file?
      render json: {status: :error, message: "#{params[:path]} is not file"}, status: 403
    end
  end

  def validates_parent_to_be_present
    parent = object.parent_directory
    if !parent.exists?
      render json: {status: :error, message: "directory #{parent.path} not exists"}, status: 404
    end
  end

  def check_target
    params.require(:target_user)
    params.require(:target_service)
    @target = "#{params[:target_user]}:#{params[:target_service]}"
  rescue
    render json: {status: :error, message: "target_user and target_service is required"}, status: 400
  end
end

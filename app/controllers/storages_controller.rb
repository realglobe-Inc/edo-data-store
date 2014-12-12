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
  before_action :validates_dest_object_to_be_writable, only: %w(copy move)
  before_action :check_target, only: %w(set_permissions unset_permissions)

  def list_files
    filenames = object.read
    reject_parameters = %w(owner directory_size_limit directory_bytes_limit)
    file_list = filenames.map do |filename|
      if params["metadata"] == "true"
        file = object.find_object(filename)
        metadata = file.get_metadata.reject{|key, value| reject_parameters.include?(key)}
        {name: filename}.merge(metadata)
      else
        {
          name: filename,
          is_dir: File.directory?("#{object.storage_object_path}#{filename}")
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
    object.delete
    render nothing: true, status: 204
  end

  def read_file
    send_data object.read(revision: params[:revision])
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
    object.delete
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

  def validates_dest_object_to_be_writable
    case
    when !dest_object.exists?
    when dest_object.directory?
      render json: {status: :error, message: "directory #{params[:dest_path]} is already exists"}, status: 409
    when object.directory?
      render json: {status: :error, message: "can't copy #{params[:path]}(directory) to #{params[:dest_path]}(file)"}, status: 409
    when params[:overwrite] != "true"
      cannot_overwrite_error(params[:dest_path])
    end
  end

  def check_target
    params.require(:target_user)
    params.require(:target_service)
    @target = "#{params[:target_user]}:#{params[:target_service]}"
  rescue
    render json: {status: :error, message: "target_user and target_service is required"}, status: 400
  end

  def cannot_overwrite_error(path)
    render json: {status: :error, message: "file #{path} is already exists. overwrite=true to overwrite"}, status: 403
  end
end

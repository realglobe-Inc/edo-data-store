class StoragesController < ApplicationController
  include StorageManager

  before_action :validates_user_to_be_present
  before_action :validates_service_to_be_present
  before_action :validates_object_to_be_directory, only: %w(ls rmdir)
  before_action :validates_object_to_be_file, only: %w(show destroy)
  before_action :validates_object_to_be_absent, only: %w(mkdir)
  before_action :validates_parent_to_be_present, only: %w(mkdir create)

  def ls
    render json: {status: :ok, data: {files: object.read}}
  end

  def mkdir
    directory.create
    render json: {status: :ok, data: {directory: directory.path}}
  end

  def rmdir
    object.delete
    render json: {status: :ok, data: {result: true}}
  end

  def show
    send_data object.read
  end

  # TODO check Content-Type header
  # TODO add extension
  def create
    file_body = request.raw_post
    if file.exists?
      # TODO check params[:overwrite] true/false
      file.update(file_body)
    else
      file.create(file_body)
    end
    render json: {status: :ok, data: {path: file.path, size: file.metadata.disk_usage}}
  end

  def destroy
    object.delete
    render json: {status: :ok, data: {result: true}}
  end

  private

  def object
    @object ||= service_root.find_object(params[:path])
  end

  def directory
    @directory ||= service_root.directory(params[:path])
  end

  def file
    @file ||= service_root.file(params[:path])
  end

  def validates_object_to_be_present
    if !object.exists?
      render json: {status: :error, message: "#{params[:path]} not found"}
    end
  end

  def validates_object_to_be_absent
    if object.exists?
      render json: {status: :error, message: "#{params[:path]} is already exists"}
    end
  end

  def validates_object_to_be_directory
    if !object.directory?
      render json: {status: :error, message: "#{params[:path]} is not directory"}
    end
  end

  def validates_object_to_be_file
    if object.file?
      render json: {status: :error, message: "#{params[:path]} is directory"}
    end
  end

  def validates_parent_to_be_present
    parent = object.parent_directory
    if !parent.exists?
      render json: {status: :error, message: "directory #{parent.path} not exists"}
    end
  end
end

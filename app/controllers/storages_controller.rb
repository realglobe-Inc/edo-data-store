class StoragesController < ApplicationController
  before_action :find_workspace
  before_action :find_service_node
  before_action :find_directory, only: %w(ls mkdir rmdir)
  before_action :find_file, only: %w(show create destroy)

  def ls
    if @directory.exists?
      render json: {status: :ok, data: {files: @directory.read}}
    else
      render json: {status: :error, message: "directory not found"}
    end
  end

  def mkdir
    if @directory.exists?
      render json: {status: :error, message: "already exists"}
    else
      @directory.create
      render json: {status: :ok, data: {directory: @directory.path}}
    end
  end

  def rmdir
    if @directory.exists?
      @directory.delete
      render json: {status: :ok, data: {result: true}}
    else
      render json: {status: :error, message: "directory not found"}
    end
  end

  def show
    if @file.exists?
      send_data @file.read
    else
      render json: {status: :error, message: "file not found"}
    end
  end

  # TODO check Content-Type header
  # TODO add extension
  def create
    file_body = request.raw_post
    if @file.exists?
      # TODO check params[:overwrite] true/false
      @file.update(file_body)
    else
      @file.create(file_body)
    end
    render json: {status: :ok, data: {path: @file.path, size: @file.metadata.disk_usage}}
  end

  def destroy
    if @file.exists?
      @file.delete
      render json: {status: :ok, data: {result: true}}
    else
      render json: {status: :error, message: "file not found"}
    end
  end

  private

  def find_workspace
    user_id = params[:user_uuid]
    user = StoreAgent::User.new(user_id)
    @workspace = user.workspace(user_id)
  end

  def find_service_node
    service_id = params[:service_uuid]
    @service_node = @workspace.directory(service_id)
  end

  def find_directory
    dir_path = params[:path]
    @directory = @service_node.directory(dir_path)
  end

  def find_file
    file_path = params[:path]
    @file = @service_node.file(file_path)
  end
end

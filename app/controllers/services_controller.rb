class ServicesController < ApplicationController
  before_action :find_workspace

  def create
    dir_id = params[:uuid]
    dir = @workspace.directory(dir_id)
    if dir.exists?
      render json: {status: :error, message: "already exists"}
    else
      dir.create
      render json: {status: :ok, data: {uuid: dir_id}}
    end
  end

  private

  def find_workspace
    user_id = params[:user_uuid]
    user = StoreAgent::User.new(user_id)
    @workspace = user.workspace(user_id)
  end
end

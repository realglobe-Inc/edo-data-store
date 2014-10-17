class UsersController < ApplicationController
  def create
    user_id = params["uuid"]
    user = StoreAgent::User.new(user_id)
    workspace = user.workspace(user_id)
    if workspace.exists?
      render json: {status: :error, message: "already exists"}
    else
      workspace.create
      render json: {status: :ok, data: {uuid: user_id}}
    end
  end
end

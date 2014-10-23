class UsersController < ApplicationController
  include StorageManager

  before_action :validates_user_to_be_absent, only: %w(create)

  def create
    workspace.create
    render json: {status: :ok, data: {uid: params["user_uid"]}}
  end
end

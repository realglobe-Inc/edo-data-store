class UsersController < ApplicationController
  include StorageManager
  include ContentTypeChecker
  include ResponseJsonNotificationsAdder

  before_action :require_content_type_json
  before_action :validates_user_to_be_absent, only: %w(create)

  def create
    workspace.create
    render json: {status: :ok, data: {uid: params["user_uid"]}}, status: 201
  end
end

class UsersController < ApplicationController
  include StorageManager
  include ContentTypeChecker
  include ResponseJsonNotificationsAdder

  before_action :require_content_type_json, only: %w(create)
  before_action :validates_user_to_be_superuser
  before_action :validates_user_to_be_present, only: %w(destroy)
  before_action :validates_user_to_be_absent, only: %w(create)

  def index
    user_identifiers = StoreAgent::Workspace.name_list
    render json: user_identifiers
  end

  def create
    workspace.create
    render nothing: true, status: 201
  end

  def destroy
    workspace.delete
    render nothing: true, status: 204
  end
end

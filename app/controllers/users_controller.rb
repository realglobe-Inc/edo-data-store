class UsersController < ApplicationController
  include StorageManager
  include ContentTypeChecker
  include ResponseJsonNotificationsAdder

  before_action :require_content_type_json
  before_action :validates_user_to_be_absent, only: %w(create)

  def index
    user_identifiers = []
    FileUtils.cd(StoreAgent.config.storage_root) do
      user_identifiers = Dir.glob("*", File::FNM_DOTMATCH)
    end
    user_identifiers = (user_identifiers - StoreAgent.reserved_filenames).sort
    render json: {status: :ok, data: {users: user_identifiers}}
  end

  def create
    workspace.create
    render json: {status: :ok, data: {uid: params["user_uid"]}}, status: 201
  end
end

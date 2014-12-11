class ServicesController < ApplicationController
  include StorageManager
  include ContentTypeChecker
  include ResponseJsonNotificationsAdder

  before_action :require_content_type_json, only: %w(create)
  before_action :validates_user_to_be_superuser
  before_action :validates_user_to_be_present
  before_action :validates_service_to_be_present, only: %w(destroy)
  before_action :validates_service_to_be_absent, only: %w(create)

  def index
    render json: service_root.read
  end

  def create
    service_root.create do |root_dir|
      root_dir.initial_owner = storage_user_identifier
      root_dir.initial_permission = {
        storage_user_identifier => StoreAgent.config.default_owner_permission
      }
    end
    @current_user = @workspace = @service_root = nil
    service_root.file(".statements").create
    render json: {status: :ok, data: {uid: params["service_uid"]}}, status: 201
  end

  def destroy
    service_root.delete
    render json: {status: :ok, data: {result: true}}
  end
end

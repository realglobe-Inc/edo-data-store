class ServicesController < ApplicationController
  include StorageManager
  include ContentTypeChecker
  include ResponseJsonNotificationsAdder

  before_action :require_content_type_json
  before_action :validates_user_to_be_present
  before_action :validates_service_to_be_absent, only: %w(create)

  def index
    render json: {status: :ok, data: {services: service_root.read}}
  end

  def create
    service_root.create
    render json: {status: :ok, data: {uid: params["service_uid"]}}, status: 201
  end
end

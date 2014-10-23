class ServicesController < ApplicationController
  include StorageManager

  before_action :validates_user_to_be_present
  before_action :validates_service_to_be_absent, only: %w(create)

  def create
    service_root.create
    render json: {status: :ok, data: {uid: params["service_uid"]}}
  end
end

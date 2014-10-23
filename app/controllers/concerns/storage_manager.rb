module StorageManager
  extend ActiveSupport::Concern

  def current_user
    # TODO check X-EDO-xxx header
    # TODO check root/guest user
    @current_user ||= StoreAgent::User.new(params["user_uid"])
  end

  def workspace
    @workspace ||= current_user.workspace(params["user_uid"])
  end

  def service_root
    @service_root ||= @workspace.directory(params["service_uid"])
  end

  def validates_user_to_be_present
    if !workspace.exists?
      render json: {status: :error, message: "user not found"}
    end
  end

  def validates_user_to_be_absent
    if workspace.exists?
      render json: {status: :error, message: "user already exists"}
    end
  end

  def validates_service_to_be_present
    if !service_root.exists?
      render json: {status: :error, message: "service not found"}
    end
  end

  def validates_service_to_be_absent
    if service_root.exists?
      render json: {status: :error, message: "service already exists"}
    end
  end
end

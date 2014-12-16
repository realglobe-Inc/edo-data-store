module StorageManager
  extend ActiveSupport::Concern
  include ResponseJsonTemplateRenderer

  private

  def user_uid
    # TODO request.headers["HTTP_X_EDO_USER_ID"]
    params["user_uid"]
  end

  def service_uid
    # TODO request.headers["HTTP_X_EDO_TA_ID"]
    params["service_uid"]
  end

  def storage_user_identifier
    "#{user_uid}:#{service_uid}"
  end

  def current_user
    @current_user ||= StoreAgent::User.new(storage_user_identifier)
  end

  def workspace
    @workspace ||= current_user.workspace(params["user_uid"])
  end

  def service_root
    @service_root ||= workspace.directory(params["service_uid"])
  end

  def validates_user_to_be_present
    if !workspace.exists?
      render json_template: :user_not_found, template_params: {user_uid: user_uid}, status: 404
    end
  end

  def validates_user_to_be_absent
    if workspace.exists?
      render json_template: :user_already_exists, template_params: {user_uid: user_uid}, status: 409
    end
  end

  def validates_service_to_be_present
    if !service_root.exists?
      render json_template: :service_not_found, template_params: {service_uid: service_uid}, status: 404
    end
  end

  def validates_service_to_be_absent
    if service_root.exists?
      render json_template: :service_already_exists, template_params: {service_uid: service_uid}, status: 409
    end
  end

  # TODO check request header
  def validates_user_to_be_superuser
    @current_user = StoreAgent::Superuser.new
  end
end

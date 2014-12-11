module ContentTypeChecker
  extend ActiveSupport::Concern

  private

  def require_content_type_json
    require_content_type("application/json")
  end

  def require_content_type(required_content_type)
    content_type = request.headers["Content-Type"]
    if content_type != required_content_type
      response_json = {
        status: :error,
        message: "invalid Content-Type '#{content_type}'. required '#{required_content_type}'"
      }
      render json: response_json, status: 400
      return
    end
    x_original_content_type = request.headers["X-Original-Content-Type"]
    if x_original_content_type && (x_original_content_type != required_content_type)
      notifications << "invalid Content-Type '#{x_original_content_type}'. required '#{required_content_type}'"
    end
  end
end

module ContentTypeChecker
  extend ActiveSupport::Concern
  include ResponseJsonTemplateRenderer

  private

  def require_content_type_json
    require_content_type("application/json")
  end

  def require_content_type(required_content_type)
    content_type = request.headers["Content-Type"]
    if content_type != required_content_type
      render json_template: :invalid_content_type, template_params: {content_type: required_content_type}, status: 400
      return
    end
    x_original_content_type = request.headers["X-Original-Content-Type"]
    if x_original_content_type && (x_original_content_type != required_content_type)
      notifications << "invalid Content-Type '#{x_original_content_type}'. required '#{required_content_type}'"
    end
  end
end

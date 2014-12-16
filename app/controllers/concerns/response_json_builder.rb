module ResponseJsonBuilder
  module_function

  def build(template_name, **params)
    status_code = params[:status] || 200
    message = params.delete(:message) || I18n.t("json.template.#{template_name}.message")
    descriptions = params.delete(:descriptions)
    if !descriptions
      template_params = params.delete(:template_params)
      %i(path dest_path).each do |path_params|
        if path_value = template_params.try(:[], path_params)
          template_params[path_params] = File.absolute_path("/./#{path_value}")
        end
      end
      descriptions = [I18n.t("json.template.#{template_name}.description", template_params)]
    end
    {
      status_code: status_code,
      message: message,
      descriptions: descriptions
    }
  end
end

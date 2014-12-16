module ResponseJsonBuilder
  module_function

  def build(template_name, **params)
    status_code = params[:status] || 200
    message = params.delete(:message) || I18n.t("json.template.#{template_name}.message")
    descriptions = params.delete(:descriptions) ||
      [I18n.t("json.template.#{template_name}.description", params.delete(:template_params))]
    {
      status_code: status_code,
      message: message,
      descriptions: descriptions
    }
  end
end

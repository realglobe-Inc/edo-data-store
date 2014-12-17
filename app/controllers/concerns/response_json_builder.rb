module ResponseJsonBuilder
  module_function

  def build(template_name, **params)
    status_code = params[:status] || 200
    error_code = template_name.to_s.classify
    descriptions = params.delete(:descriptions)
    if !descriptions
      template_params = params.delete(:template_params)
      %i(path dest_path).each do |path_params|
        if path_value = template_params.try(:[], path_params)
          template_params[path_params] = File.absolute_path("/./#{path_value}")
        end
      end
      descriptions = [I18n.t("json.template.description.#{template_name}", template_params)]
    end
    {
      status_code: status_code,
      error_code: error_code,
      descriptions: descriptions
    }
  end
end

module ResponseJsonTemplateRenderer
  extend ActiveSupport::Concern

  prepend Module.new{
    def render(**params)
      if template_name = params.delete(:json_template)
        params[:json] = {
          status_code: params[:status] || 200,
          message: params.delete(:message) || t("json.template.#{template_name}.message"),
          descriptions: params.delete(:descriptions) || [t("json.template.#{template_name}.description", params.delete(:template_params))]
        }
      end
      super
    end
  }
end

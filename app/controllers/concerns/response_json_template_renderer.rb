module ResponseJsonTemplateRenderer
  extend ActiveSupport::Concern

  prepend Module.new{
    def render(**params)
      if template_name = params.delete(:json_template)
        params[:json] = ResponseJsonBuilder.build(template_name, params)
      end
      super
    end
  }
end

#--
# Copyright 2015 realglobe, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

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

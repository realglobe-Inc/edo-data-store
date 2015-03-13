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

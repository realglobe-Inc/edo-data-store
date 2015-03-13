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

class RequestParamsParser
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      request = ActionDispatch::Request.new(env.dup)
      request.params
      @app.call(env)
    rescue ArgumentError => e
      status_code = 400
      response_header = {"Content-Type" => "application/json"}
      response_json_object = ::ResponseJsonBuilder.build(:parse_params_error, status: status_code)
      [status_code, response_header, [Oj.dump(response_json_object)]]
    end
  end
end

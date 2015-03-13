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

class ErrorResponseNotifier
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env).tap do |status_code, response_header, response_body|
      begin
        if status_code >= 400
          env["rack.input"].rewind
          exception_params = {
            status_code: status_code,
            response_header: response_header,
            response_body: response_body,
            request_body: env["rack.input"].read
          }
          exception = ErrorResponseException.new(exception_params)
          if MailerSettings.exception_notification.notify_errors
            ExceptionNotifier.notify_exception(exception, env: env, verbose_subject: false)
          else
            DebugLogger.debug_message{exception.message}
          end
        end
      rescue => e
        ExceptionNotifier.notify_exception(e, env: env, verbose_subject: false)
      end
    end
  end

  class ErrorResponseException < RuntimeError
    attr_reader :message

    def initialize(status_code: 500, response_header: {}, response_body: [], request_body: "")
      body_string = ""
      response_body.each{|body_part| body_string += body_part}
      messages = [] <<
        "status_code: #{status_code}" <<
        "" <<
        "response_header: #{Oj.dump(response_header, indent: 2)}" <<
        "response_body: #{body_string}" <<
        "" <<
        "request_body: #{request_body.truncate(2 ** 10)}"
      @message = messages.join("\n")
    end
  end
end

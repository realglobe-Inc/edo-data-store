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

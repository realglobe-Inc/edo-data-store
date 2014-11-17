class ErrorResponseNotifier
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env).tap do |status_code, response_header, response_body|
      begin
        if (status_code >= 400) && ::MailerSettings.exception_notification.notify_errors
          exception = ErrorResponseException.new(status_code: status_code, response_header: response_header, response_body: response_body, request_body: env["rack.input"].read)
          ExceptionNotifier.notify_exception(exception, env: env, verbose_subject: false)
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
      response_body.each do |body|
        body_string += "#{body}\n"
      end
      @message = "status_code: #{status_code}\n\nresponse_header:\n#{response_header}\n\nresponse_body:\n#{body_string}"
      @message += "\n\nrequest_body:\n#{request_body.truncate(2 ** 10)}"
    end
  end
end

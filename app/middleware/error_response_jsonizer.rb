class ErrorResponseJsonizer
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      code, header, body = @app.call(env)
      if code >= 400
        response_body = ""
        body.each{|body_part| response_body += body_part}
        Oj.load(response_body)
      end
      [code, header, body]
    rescue => e
      status_code = 404
      response_header = {"Content-Type" => "application/json"}
      response_json_object = ::ResponseJsonBuilder.build(:unexpected_error, status: status_code)
      [status_code, response_header, [Oj.dump(response_json_object)]]
    end
  end
end

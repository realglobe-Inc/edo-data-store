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
      [400, {"Content-Type" => "application/json"}, [Oj.dump({status: :error, message: "unexpected error"})]]
    end
  end
end

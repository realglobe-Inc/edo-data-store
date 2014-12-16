class CatchJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError => error
      status_code = 400
      response_header = {
        "Content-Type" => "application/json"
      }
      response_json_object = ::ResponseJsonBuilder.build(:json_parse_error, status: status_code)
      [status_code, response_header, [Oj.dump(response_json_object)]]
    end
  end
end

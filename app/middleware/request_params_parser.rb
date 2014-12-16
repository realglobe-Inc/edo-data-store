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

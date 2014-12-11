class CatchJsonParseErrors
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      @app.call(env)
    rescue ActionDispatch::ParamsParser::ParseError => error
      [400, {"Content-Type" => "application/json"}, [Oj.dump({status: :error, message: "Bad Request: JSON parse error"})]]
    end
  end
end

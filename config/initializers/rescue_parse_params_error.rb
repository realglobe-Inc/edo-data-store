class Rack::MethodOverride
  prepend Module.new {
    def call(env)
      begin
        super
      rescue ArgumentError => e
        [400, {"Content-Type" => "application/json"}, [Oj.dump({status: 400, message: "maybe invalid content_type"})]]
      end
    end
  }
end

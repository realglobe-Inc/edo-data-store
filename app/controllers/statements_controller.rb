class StatementsController < ApplicationController
  def index
    statements = Statement.where(user_identifier: params[:user_uuid], service_identifier: params[:service_uuid])
    statement_objects = Oj.load("[#{statements.pluck(:json_statement).join(",")}]")
    render json: {status: :ok, data: {statements: statement_objects}}
  end

  def create
    # TODO check user_id, service_id

    json_statement = request.raw_post
    begin
      Oj.load(json_statement)
    rescue => e
      render json: {status: :error, message: "invalid JSON"}
      return
    end
    create_params = {
      user_identifier: params[:user_uuid],
      service_identifier: params[:service_uuid],
      json_statement: json_statement
    }
    Statement.create(create_params)
    render json: {status: :ok, data: {result: true}}
  end
end

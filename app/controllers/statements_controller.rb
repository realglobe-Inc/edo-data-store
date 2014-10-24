class StatementsController < ApplicationController
  include ContentTypeChecker
  include ResponseJsonNotificationsAdder

  before_action :require_content_type_json

  def index
    statements = Statement.where(user_uid: params[:user_uid], service_uid: params[:service_uid])
    statement_objects = Oj.load("[#{statements.pluck(:json_statement).join(",")}]")
    render json: {status: :ok, data: {statements: statement_objects}}
  end

  def create
    # TODO check user_id, service_id

    json_statement = request.raw_post
    begin
      Oj.load(json_statement)
    rescue => e
      render json: {status: :error, message: "invalid JSON"}, status: 400
      return
    end
    create_params = {
      user_uid: params[:user_uid],
      service_uid: params[:service_uid],
      json_statement: json_statement
    }
    Statement.create(create_params)
    render json: {status: :ok, data: {result: true}}, status: 201
  end
end

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
    json_statement = request.raw_post
    create_params = {
      user_uid: params[:user_uid],
      service_uid: params[:service_uid],
      json_statement: json_statement
    }
    statement = Statement.create(create_params)
    if statement.errors.empty?
      render json: {status: :ok, data: {result: true}}, status: 201
    else
      statement.errors.full_messages.each{|message| notifications << message}
      render json: {status: :error, message: "invalid uid"}, status: 403
    end
  end
end

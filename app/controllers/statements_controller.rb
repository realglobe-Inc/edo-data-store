class StatementsController < ApplicationController
  include ResponseJsonNotificationsAdder

  def index
    statements = Statement.where(user_uid: params[:user_uid], service_uid: params[:service_uid])
    statements_properties = Oj.load("[#{statements.pluck(:json_statement).join(",")}]")
    render json: {status: :ok, data: {statements: statements_properties}}
  end

  def create
    case request.content_type
    when "application/json"
      statement = Statement.create_simple(user_uid: params[:user_uid], service_uid: params[:service_uid], raw_body: request.raw_post)
    when "multipart/mixed"
      statement = Statement.create_mixed(user_uid: params[:user_uid], service_uid: params[:service_uid], raw_body: request.raw_post, content_type: request.headers["Content-Type"])
    else
      render json: {status: :error, message: "invalid Content-Type"}, status: 400
      return
    end
    if statement.errors.present?
      render json: {status: :error, message: statement.errors.full_messages}, status: 403
    else
      render json: {status: :ok, data: statement.properties}, status: 201
    end
  end
end

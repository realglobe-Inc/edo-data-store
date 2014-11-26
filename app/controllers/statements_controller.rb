class StatementsController < ApplicationController
  include ResponseJsonNotificationsAdder
  include StatementBuilder

  def index
    statements = Statement.where(user_uid: params[:user_uid], service_uid: params[:service_uid])
    # TODO check params[:attachments] == true
    if statements.pluck(:attachments).present?
      content_type, response_body = build_multipart_statement_response(statements)
      send_data response_body, type: content_type, disposition: :inline
    else
      render json: {status: :ok, data: {statements: statements.map(&:properties)}}
    end
  end

  def create
    case request.content_type
    when "application/json"
      statement = Statement.create_simple(user_uid: params[:user_uid], service_uid: params[:service_uid], json_string: request.raw_post)
    when "multipart/mixed"
      statement = Statement.create_mixed(user_uid: params[:user_uid], service_uid: params[:service_uid], multipart_body: request.raw_post, content_type: request.headers["Content-Type"])
    else
      render json: {status: :error, message: "invalid Content-Type"}, status: 400
      return
    end
    if statement.save
      render json: {status: :ok, data: statement.properties}, status: 201
    else
      render json: {status: :error, message: statement.errors.full_messages}, status: 403
    end
  end
end

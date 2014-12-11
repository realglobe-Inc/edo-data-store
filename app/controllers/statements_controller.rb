class StatementsController < ApplicationController
  include ResponseJsonNotificationsAdder
  include StorageManager
  include StatementBuilder

  before_action :check_read_permission, only: %w(index)
  before_action :check_write_permission, only: %w(create)

  def index
    statements = Statement.with_collection(user_uid: params[:user_uid], service_uid: params[:service_uid]).all
    response.header["X-Experience-API-Consistent-Through"] = Time.now.iso8601
    if params[:attachments] == "true"
      content_type, response_body = build_multipart_statement_response(statements)
      send_data response_body, type: content_type, disposition: :inline
    else
      render json: statements.map(&:properties)
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
    if Statement.where(id: statement.id).present?
      render json: {status: :error, message: "statement(id: #{statement.id}) already exists"}, status: 409
    elsif statement.save
      Statement.with(collection: statement.collection_name).create_indexes
      render json: {status: :ok, data: statement.properties}, status: 201
    else
      render json: {status: :error, message: statement.errors.full_messages}, status: 403
    end
  end

  private

  def search_params
    params.permit(:user_uid, :service_uid, :attachments)
  end

  def check_read_permission
    if !service_root.file(".statement").permission.allow?("read")
      render json: {status: :error, message: "permission denied"}, status: 403
    end
  end

  def check_write_permission
    if !service_root.file(".statement").permission.allow?("write")
      render json: {status: :error, message: "permission denied"}, status: 403
    end
  end
end

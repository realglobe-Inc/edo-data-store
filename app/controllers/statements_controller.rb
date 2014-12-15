class StatementsController < ApplicationController
  include ResponseJsonNotificationsAdder
  include ResponseJsonTemplateRenderer
  include StorageManager
  include StatementBuilder

  before_action :check_read_permission, only: %w(index)
  before_action :check_write_permission, only: %w(create)
  before_action :build_new_statement, only: %w(create)
  before_action :render_error_response, only: %w(create)

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
    if Statement.where(id: @statement.id).present?
      render json_template: :duplicated_id, template_params: {id: @statement.id}, status: 409
    elsif @statement.save
      Statement.with(collection: @statement.collection_name).create_indexes
      render nothing: true, status: 204
    else
      render_error_response
    end
  end

  private

  def search_params
    params.permit(:user_uid, :service_uid, :attachments)
  end

  def check_read_permission
    if !service_root.file(".statement").permission.allow?("read")
      render json_template: :permission_denied, status: 403
    end
  end

  def check_write_permission
    if !service_root.file(".statement").permission.allow?("write")
      render json_template: :permission_denied, status: 403
    end
  end

  def build_new_statement
    case request.content_type
    when "application/json"
      @statement = Statement.build_simple(user_uid: params[:user_uid], service_uid: params[:service_uid], json_string: request.raw_post)
    when "multipart/mixed"
      @statement = Statement.build_mixed(user_uid: params[:user_uid], service_uid: params[:service_uid], multipart_body: request.raw_post, content_type: request.headers["Content-Type"])
    else
      render json_template: :invalid_content_type, status: 400
    end
  end

  def render_error_response
    if @statement.errors.present?
      render json_template: :invalid_value, descriptions: @statement.errors.full_messages, status: 400
    end
  end
end

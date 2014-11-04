class StatementsController < ApplicationController
  include ResponseJsonNotificationsAdder

  def index
    statements = Statement.where(user_uid: params[:user_uid], service_uid: params[:service_uid])
    statement_objects = Oj.load("[#{statements.pluck(:json_statement).join(",")}]")
    render json: {status: :ok, data: {statements: statement_objects}}
  end

  def create
    case request.content_type
    when "application/json"
      json_statement = request.raw_post
      # TODO
      create_params = {
        user_uid: params[:user_uid],
        service_uid: params[:service_uid],
        json_statement: json_statement
      }
      statement = Statement.new(create_params)
      if statement.save
        render json: {status: :ok, data: {result: true}}, status: 201
      else
        statement.errors.full_messages.each{|message| notifications << message}
        render json: {status: :error, message: "invalid uid"}, status: 403
      end
    when "multipart/mixed"
      mail_body = request.raw_post
      mail_string = "Content-Type: #{request.headers["Content-Type"]}\r\n\r\n#{mail_body}"
      mail = Mail.read_from_string(mail_string)
      json_statement = mail.parts.shift.body.to_s
      # TODO
      create_params = {
        user_uid: params[:user_uid],
        service_uid: params[:service_uid],
        json_statement: json_statement
      }
      begin
        Statement.transaction do
          statement = Statement.create!(create_params)
          mail.parts.each do |part|
            sha2 = part.header_fields.find{|f| f.name == "X-Experience-API-Hash"}.value
            content = part.body.to_s
            Attachment.create!(sha2: sha2, content: content)
          end
          render json: {status: :ok, data: {result: true}}, status: 201
        end
      rescue
        statement.errors.full_messages.each{|message| notifications << message}
        render json: {status: :error, message: "invalid request"}, status: 403
      end
    else
      render json: {status: :error, message: "invalid Content-Type"}, status: 400
    end
  end
end

module StatementBuilder
  extend ActiveSupport::Concern

  private

  def build_multipart_statement_response(statements)
    attachment_hashsums = statements.pluck(:attachments).flatten.map{|a| a["sha2"]}
    attachments = Attachment.where(sha2: attachment_hashsums)
    boundary = rand(36**16).to_s(36)
    body = [] <<
      "--#{boundary}" <<
      "Content-Type: application/json" <<
      "" <<
      Oj.dump(statements.map(&:properties))
    attachments.each do |attachment|
      body <<
        "--#{boundary}" <<
        attachment.multipart_response_format
    end
    body << "--#{boundary}--"
    response_body = body.join("\r\n")
    ["multipart/mixed; boundary=#{boundary}", response_body]
  end
end

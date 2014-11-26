class Attachment
  include Mongoid::Document

  SHA2_HASH_REGEXP = "[0-9a-f]+"
  SHA2_HASH_HEADER_NAME = "X-Experience-API-Hash"

  field :sha2, type: String
  field :content_type, type: String
  field :content, type: BSON::Binary
  field :stored_at, type: DateTime, default: -> {Time.now}

  index sha2: 1

  attr_readonly *%w(sha2 content_type content stored_at)

  validates :sha2, presence: true, uniqueness: true

  class << self
    def build_multipart_attachment(statement: nil, headers: nil, body: nil)
      sha2_header = headers.find{|h| h.start_with?("#{SHA2_HASH_HEADER_NAME}:")}
      if !sha2_header
        raise "#{SHA2_HASH_HEADER_NAME} header required."
      end
      sha2 = sha2_header.match(/#{SHA2_HASH_HEADER_NAME}:\s*(#{SHA2_HASH_REGEXP})/)[1]
      if !sha2
        raise "#{SHA2_HASH_HEADER_NAME} header is invalid format"
      end
      if Attachment.where(sha2: sha2).present?
        return
      end
      content_type_header = headers.find{|h| h.start_with?("Content-Type:")}
      if content_type_header
        content_type = content_type_header.match(/Content-Type:\s*(.*)/)[1]
      else
        attachment_property = statement.properties["attachments"].find{|a| a["sha2"] == sha2}
        content_type = attachment_property["contentType"]
      end
      Attachment.new(sha2: sha2, content: BSON::Binary.new(body), content_type: content_type)
    end
  end

  def content
    super.data
  end

  def multipart_response_format
    body_lines = (content_type ? ["Content-Type: #{content_type}"] : []) <<
      "Content-Transfer-Encoding: binary" <<
      "X-Experience-API-Hash: #{sha2}" <<
      "" <<
      content
    body_lines.join(Statement::CRLF)
  end

  def statements
    Statement.elem_match(attachments: {sha2: sha2})
  end
end

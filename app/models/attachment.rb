class Attachment < ActiveRecord::Base
  has_many :attachment_relations
  has_many :statements, through: :attachment_relations

  validates :sha2, presence: true, uniqueness: true

  class << self
    def build_multipart_attachment(statement: nil, headers: nil, body: nil)
      sha2_header = headers.find{|h| h.start_with?("#{Statement::SHA2_HASH_HEADER_NAME}:")}
      sha2_header =~ /#{Statement::SHA2_HASH_HEADER_NAME}:\s*(#{Statement::BOUNDARY_REGEXP})/
      sha2 = $1
      content_type_header = headers.find{|h| h.start_with?("Content-Type:")}
      if content_type_header
        content_type_header =~ /Content-Type:\s*(.*)/
        content_type = $1
      else
        content_type = statement.properties["attachments"].find{|a| a["sha2"] == sha2}["contentType"]
      end
      statement.attachments.new(sha2: sha2, content: body, content_type: content_type)
    end
  end

  def multipart_response_format
    body_lines = (content_type ? ["Content-Type: #{content_type}"] : []) <<
      "Content-Transfer-Encoding: binary" <<
      "X-Experience-API-Hash: #{sha2}" <<
      "" <<
      content
    body_lines.join(Statement::CRLF)
  end
end

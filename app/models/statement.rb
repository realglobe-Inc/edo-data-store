class Statement
  include Mongoid::Document

  CRLF = "\r\n"
  BOUNDARY_REGEXP = "[0-9A-Za-z'()+_,-.\/:=?]+"
  PROPERTIES = {
    recommended: %w(id),
    required: %w(actor verb object),
    optional: %w(result context timestamp authority attachments),
    set_by_lrs: %w(stored),
    not_recommended: %w(version)
  }
  PROPERTY_NAMES = PROPERTIES.values.flatten

  field :_id, type: String, default: -> {SecureRandom.uuid}
  %w(actor verb object result context authority).each do |property_name|
    field property_name, type: Hash
  end
  field :timestamp, type: DateTime, default: -> {new_record? ? stored : timestamp}
  field :stored, type: DateTime, default: -> {new_record? ? Time.now : stored}
  field :version, type: String
  field :attachments, type: Array

  index stored: 1

  attr_readonly *PROPERTY_NAMES
  attr_writer :multipart_attachments

  default_scope -> {order_by(:stored.desc)}

  validates :actor, presence: true
  validates :verb, presence: true
  validates :object, presence: true

  # before_save :validates_user_to_be_present, :validates_service_to_be_present, on: :create
  before_validation :set_datetimes
  before_save :validates_multipart_attachments
  after_save :save_multipart_attachments

  class << self
    def with_collection(user_uid: nil, service_uid: nil)
      with(collection: "statements_#{user_uid}:#{service_uid}")
    end

    def parse_params(raw_message)
      raw_header, body = raw_message.split("#{CRLF}#{CRLF}")
      headers = raw_header.split("#{CRLF}")
      [headers, body]
    end

    def search(user_uid: nil, service_uid: nil)
      Statement.with_collection(user_uid: user_uid, service_uid: service_uid).all
    end

    def build_simple(user_uid: nil, service_uid: nil, json_string: "")
      statement = Statement.with_collection(user_uid: user_uid, service_uid: service_uid).new
      statement.properties = json_string
      statement
    end

    def build_mixed(user_uid: nil, service_uid: nil, multipart_body: "", content_type: "")
      if content_type !~ /boundary=(#{BOUNDARY_REGEXP})/
        raise content_type.inspect
      end
      boundary = $1
      parts = multipart_body.split(/(?:#{CRLF})?--#{boundary}(?:#{CRLF}|--)/).reject(&:blank?)
      statement_string = parts.shift
      statement_headers, statement_body = parse_params(statement_string)
      statement_params = {
        user_uid: user_uid,
        service_uid: service_uid,
        json_string: statement_body
      }
      statement = build_simple(statement_params)
      statement.multipart_attachments = parts.map do |attachment_string|
        attachment_headers, attachment_body = parse_params(attachment_string)
        attachment_params = {
          statement: statement,
          headers: attachment_headers,
          body: attachment_body
        }
        Attachment.build_multipart_attachment(attachment_params)
      end.compact
      statement
    end
  end

  def multipart_attachments
    @multipart_attachments ||= []
  end

  def properties
    @properties ||= raw_attributes.inject({}) do |r, pair|
      key, value = pair
      case key
      when "_id"
        r["id"] = value
      when *PROPERTY_NAMES
        r[key] = value
      end
      r
    end
  end

  def []=(attr_name, value)
    begin
      super
    rescue Mongoid::Errors::InvalidValue => e
      errors.add attr_name, :invalid_value
    end
  end

  def properties=(json_string)
    Oj.load(json_string).each do |key, value|
      if PROPERTY_NAMES.include?(key)
        self[key] = value
      end
    end
  end

  private

  def workspace
    StoreAgent::Guest.new.workspace(user_uid)
  end

  def service_root
    workspace.directory(service_uid)
  end

  def set_datetimes
    self.stored = Time.now.iso8601
    self.timestamp ||= stored
  end

  def validates_multipart_attachments
    multipart_attachments.each do |attachment|
      if !attachment.valid?
        # TODO set error message
        errors.add :base, :invalid_attachment
      end
    end
    errors.blank?
  end

  def save_multipart_attachments
    multipart_attachments.each(&:save)
  end

  def validates_user_to_be_present
    if !workspace.exists?
      errors.add :base, "user not found"
      false
    end
  end

  def validates_service_to_be_present
    if !service_root.exists?
      errors.add :base, "service not found"
      false
    end
  end
end

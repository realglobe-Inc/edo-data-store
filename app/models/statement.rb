class Statement < ActiveRecord::Base
  CRLF = "\r\n"
  BOUNDARY_REGEXP = "[0-9A-Za-z'()+_,-.\/:=?]+"
  SHA2_HASH_HEADER_NAME = "X-Experience-API-Hash"
  PROPERTIES = {
    recommended: %w(id),
    required: %w(actor verb object),
    optional: %w(result context timestamp authority attachments),
    set_by_lrs: %w(stored),
    not_recommended: %w(version)
  }
  PROPERTY_NAMES = PROPERTIES.values.flatten

  PROPERTY_NAMES.each do |property_name|
    define_method "#{property_name}_property" do
      properties[property_name]
    end
    define_method "#{property_name}_property=" do |value|
      properties[property_name] = value
    end
  end

  validates :actor_property, presence: true
  validates :verb_property, presence: true
  validates :object_property, presence: true

  validates :user_uid, presence: true
  validates :service_uid, presence: true
  validates :json_statement, presence: true

  before_validation :set_properties, :dump_properties
  #  before_save :validates_user_to_be_present, :validates_service_to_be_present, on: :create

  class << self
    def create_simple(user_uid: nil, service_uid: nil, raw_body: "")
      Statement.create(build_params(user_uid: user_uid, service_uid: service_uid, json_object: Oj.load(raw_body)))
    end

    def parse_params(raw_message)
      raw_header, body = raw_message.split("#{CRLF}#{CRLF}")
      headers = raw_header.split("#{CRLF}")
      [headers, body]
    end

    def create_mixed(user_uid: nil, service_uid: nil, raw_body: "", content_type: "multipart/mixed")
      content_type =~ /boundary=(#{BOUNDARY_REGEXP})/
      boundary = $1
      parts = raw_body.split(/(?:#{CRLF})?--#{boundary}(?:#{CRLF}|--)/).reject(&:blank?)
      statement_string = parts.shift
      statement_headers, statement_body = parse_params(statement_string)
      create_params = build_params(user_uid: user_uid, service_uid: service_uid, json_object: Oj.load(statement_body))
      statement = Statement.new(create_params)
      attachments = parts.map do |attachment_string|
        attachment_headers, attachment_body = parse_params(attachment_string)
        Attachment.build_multipart_attachment(statement: statement, headers: attachment_headers, body: attachment_body)
      end
      begin
        Statement.transaction do
          statement.save!
          attachments.each(&:save!)
        end
      rescue => e
        logger.info e.inspect
      end
      statement
    end

    def build_params(user_uid: nil, service_uid: nil, json_object: nil)
      PROPERTY_NAMES.inject({user_uid: user_uid, service_uid: service_uid}) do |properties, property_name|
        if json_object.has_key?(property_name)
          properties["#{property_name}_property"] = json_object[property_name]
        end
        properties
      end
    end
  end

  def properties
    @properties ||= (json_statement? ? Oj.load(json_statement) : {})
  end

  def attachment_hashsums
    properties["attachments"].map{|a| a["sha2"]}
  rescue
    nil
  end

  private

  def workspace
    StoreAgent::Guest.new.workspace(user_uid)
  end

  def service_root
    workspace.directory(service_uid)
  end

  def dump_properties
    self.json_statement = Oj.dump(properties)
  end

  def set_properties
    self.id_property ||= SecureRandom.uuid
    self.stored_property = Time.now.iso8601
    self.timestamp_property ||= stored_property
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

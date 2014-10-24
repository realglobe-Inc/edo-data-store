class Statement < ActiveRecord::Base
  validates :user_uid, presence: true
  validates :service_uid, presence: true
  validates :json_statement, presence: true

  before_save :validates_user_to_be_present, :validates_service_to_be_present, on: :create

  private

  def workspace
    StoreAgent::Guest.new.workspace(user_uid)
  end

  def service_root
    workspace.directory(service_uid)
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

  # TODO
  def validates_json_statement_to_be_valid_format
    begin
      Oj.load(json_statement)
      true
    rescue => e
      errors.add :json_statement, :invalid
      false
    end
  end
end

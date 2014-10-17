class BasicSettings < Settingslogic
  def self.inherited(child)
    child.class_eval do
      source "#{Rails.root}/config/settings_logic/#{self.to_s.underscore}.yml"
      namespace Rails.env
    end
  end
end

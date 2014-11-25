class AttachmentRelation < ActiveRecord::Base
  belongs_to :statement
  belongs_to :attachment
end

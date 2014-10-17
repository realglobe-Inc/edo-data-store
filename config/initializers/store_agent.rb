StoreAgent.configure do |c|
  c.storage_root = "#{Rails.root}/tmp/store_agent"
  c.version_manager = StoreAgent::VersionManager::RuggedGit
  c.storage_data_encoders = [] <<
    StoreAgent::DataEncoder::GzipEncoder.new <<
    StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
  c.attachment_data_encoders = [] <<
    StoreAgent::DataEncoder::GzipEncoder.new <<
    StoreAgent::DataEncoder::OpensslAes256CbcEncoder.new
  c.json_indent_level = 2
end

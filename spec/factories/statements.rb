FactoryGirl.define do
  stored_at = Time.now
  factory "test_statement", :class => Statement.with_collection(user_uid: "user_xxx", service_uid: "service_xxx") do
    id "xxx-xxx-xxx-xxx"
    actor ({mbox: "oku@realglobe.jp"})
    verb ({id: "http://realglobe.jp", display: {"en-US" => "did"}})
    object ({id: "http://realglobe.jp/test"})
    stored stored_at
    timestamp stored_at
  end
end

(1..9).each do |i|
  case i
  when 1..2
    user_id = "user_001"
    service_id = "service_001"
  when 3..6
    user_id = "user_001"
    service_id = "service_002"
  else
    user_id = "user_002"
    service_id = "service_001"
  end

  FactoryGirl.define do
    stored_at = Time.now - i
    factory "statement_00#{i}", :class => Statement.with_collection(user_uid: user_id, service_uid: service_id) do
      actor ({mbox: "oku@realglobe.jp"})
      verb ({id: "http://realglobe.jp", display: {"en-US" => "did"}})
      object ({id: "http://realglobe.jp/#{i}"})
      stored stored_at
      timestamp stored_at
    end
  end
end

require 'rails_helper'

RSpec.describe ServicesController, :type => :controller do
  before :all do
    user = StoreAgent::User.new("user_001")
    user.workspace("user_001").create
  end
  before do
    request.headers["Content-Type"] = "application/json"
  end
  let :user_uid do
    "user_001"
  end

  context "POST /users/xxx/services" do
    it "Content-Type が application/json でないと 403 エラーを返す" do
      request.headers["Content-Type"] = "text/html"
      post :create, {user_uid: user_uid, service_uid: :service_001}
      expect(response.status).to eq 403
    end
    it "service_uid パラメータが無いと 500 エラーを返す" do
      pending

      post :create, {user_uid: user_uid}
      expect(response.status).to eq 500
    end
    it "user_uid、service_uid パラメータが正しければサービス登録され、201 を返す" do
      post :create, {user_uid: user_uid, service_uid: :service_001}
      expect_201_ok(data: {uid: "service_001"})
    end
    it "service_uid が重複したら 403 エラーを返す" do
      post :create, {user_uid: user_uid, service_uid: :service_002}
      post :create, {user_uid: user_uid, service_uid: :service_002}
      expect_403_error(error_message: "service already exists")
    end
  end
end

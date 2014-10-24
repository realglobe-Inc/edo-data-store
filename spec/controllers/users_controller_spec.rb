require 'rails_helper'

RSpec.describe UsersController, :type => :controller do
  before do
    request.headers["Content-Type"] = "application/json"
  end

  context "POST /users" do
    it "Content-Type が application/json でないと 403 エラーを返す" do
      request.headers["Content-Type"] = "text/html"
      post :create, {user_uid: :foobar}
      expect(response.status).to eq 403
    end
    it "user_uid パラメータが無いと 500 エラーを返す" do
      pending

      post :create, {}
      expect(response.status).to eq 500
    end
    it "user_uid が正しければユーザーが作成され、201 を返す" do
      post :create, {user_uid: :hoge}
      expect_201_ok(data: {uid: :hoge})
    end
    it "user_uid が重複したら 403 エラーを返す" do
      post :create, {user_uid: :fuga}
      post :create, {user_uid: :fuga}
      expect_403_error(error_message: "user already exists")
    end
  end
end

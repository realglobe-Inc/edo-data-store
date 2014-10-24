require 'rails_helper'

RSpec.describe StatementsController, :type => :controller do
  fixtures :statements

  before do
    request.headers["Content-Type"] = "application/json"
  end

  context "GET /users/xxx/services/yyy/statements" do
    it "user_uid, service_uid が一致する statement の一覧を返す" do
      get :index, {user_uid: "user_001", service_uid: "service_001"}
      expect(response.status).to eq 200
      expect(Oj.load(response.body)["data"]["statements"].length).to eq 2
    end
  end

  context "POST /users/xxx/services/yyy/statements" do
    it "statement が作成され、201 を返す" do
      request.env["RAW_POST_DATA"] = Oj.dump({foo: :bar})
      statements_size = Statement.all.size
      post :create, {user_uid: "user_002", service_uid: "service_002"}
      expect(response.status).to eq 201
      expect(Statement.all.size).to eq statements_size + 1
    end
  end
end

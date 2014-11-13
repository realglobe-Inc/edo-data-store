require 'rails_helper'

RSpec.describe StatementsController, :type => :controller do
  fixtures :statements

  before :all do
    user = StoreAgent::User.new("user_001")
    user.workspace("user_001").create
    user.workspace("user_001").directory("service_001").create
  end

  context "GET /users/xxx/services/yyy/statements" do
    it "user_uid, service_uid が一致する statement の一覧を返す" do
      get :index, {user_uid: "user_001", service_uid: "service_001"}
      expect(response.status).to eq 200
      expect(Oj.load(response.body)["data"]["statements"].length).to eq 2
    end
  end

  context "POST /users/xxx/services/yyy/statements" do
    context "添付ファイルがない（Content-Type が application/json）場合" do
      before do
        request.headers["Content-Type"] = "application/json"
      end

      it "user が登録されていなければ 403 を返す" do
        request.env["RAW_POST_DATA"] = Oj.dump({foo: :bar})
        statements_size = Statement.all.size
        post :create, {user_uid: "user_002", service_uid: "service_001"}
        expect(response.status).to eq 403
        expect(Statement.all.size).to eq statements_size
      end
      it "service が登録されていなければ 403 を返す" do
        request.env["RAW_POST_DATA"] = Oj.dump({foo: :bar})
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_002"}
        expect(response.status).to eq 403
        expect(Statement.all.size).to eq statements_size
      end
      it "statement に actor がなければ 403 を返す" do
        properties = {verb: "Did", object: "This"}
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 403
        expect(Statement.all.size).to eq statements_size
      end
      it "statement に verb がなければ 403 を返す" do
        properties = {actor: "I", object: "This"}
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 403
        expect(Statement.all.size).to eq statements_size
      end
      it "statement に object がなければ 403 を返す" do
        properties = {actor: "I", verb: "Did"}
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 403
        expect(Statement.all.size).to eq statements_size
      end
      it "actor、verb、object があれば statement が作成され、201 を返す" do
        properties = {actor: "I", verb: "Did", object: "This"}
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 201
        expect(Statement.all.size).to eq statements_size + 1
      end
    end
    context "添付ファイルがある（Content-Type が multipart/mixed）場合" do
      before do
        @boundary = rand(36**16).to_s(36)
        request.headers["Content-Type"] = "multipart/mixed;\r\n boundary=#{@boundary}"
      end

      it "statement と attachment が作成され、201 を返す" do
        attachments = [] <<
          {content_type: "text/plain", content_body: "plain text"} <<
          {content_type: "application/json", content_body: '{"name": "foo", "state": "bar"}'} <<
          {content_type: "image/png", content_body: open("#{Rails.root}/tmp/rg-logo.png", "rb").read}
        attachments.each do |attachment|
          attachment[:sha2] = OpenSSL::Digest.hexdigest("sha256", attachment[:content_body])
        end
        attachment_properties = attachments.map do |attachment|
          {
            usageType: "http://example.com/test/attachment",
            display: {"en-US" => "A test attachment"},
            contentType: attachment[:content_type],
            content_type: attachment[:content_body].length,
            sha2: attachment[:sha2]
          }
        end
        properties = {actor: "I", verb: "Did", object: "This", attachments: attachment_properties}
        body = [] <<
          "--#{@boundary}" <<
          "Content-Type: application/json" <<
          "" <<
          Oj.dump(properties)
        attachments.each do |attachment|
          body <<
            "--#{@boundary}" <<
            "Content-Type: #{attachment[:content_type]}" <<
            "Content-Transfer-Encoding: binary" <<
            "X-Experience-API-Hash: #{attachment[:sha2]}" <<
            "" <<
            attachment[:content_body]
        end
        body << "--#{@boundary}--"
        request.env["RAW_POST_DATA"] = body.join("\r\n")
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 201
        expect(Statement.all.size).to eq statements_size + 1
        expect(Attachment.all.size).to eq attachments.size
        attachments.each do |attachment|
          expect(Attachment.where(sha2: attachment[:sha2]).first.content).to eq attachment[:content_body]
        end
      end
    end
  end
end

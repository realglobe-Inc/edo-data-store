require 'rails_helper'

RSpec.describe StatementsController, :type => :controller do
  before :all do
    user = StoreAgent::User.new("user_001")
    user.workspace("user_001").create
    user.workspace("user_001").directory("service_001").create
  end

  context "GET /users/xxx/services/yyy/statements" do
    context "添付ファイルがない場合" do
      context "パラメータがない場合" do
        it "user_uid, service_uid が一致する statement の一覧を返す" do
          get :index, {user_uid: "user_001", service_uid: "service_001"}
          expect(response.status).to eq 200
          expect(response.content_type).to eq "application/json"
          expect(Oj.load(response.body).length).to eq 2
        end
      end
      context "パラメータがある場合" do
        it "statementId パラメータがある場合、ID が一致するものだけを返す" do
          pending

          statement_id = Statement.first.id
          get :index, {user_uid: "user_001", service_uid: "service_001", statementId: statement_id}
          expect(response.status).to eq 200
          expect(response.content_type).to eq "application/json"
          expect(Oj.load(response.body).length).to eq 1
        end
      end
    end
    context "添付ファイルがある場合" do
      before do
        binary_string = open("#{Rails.root}/tmp/rg-logo.png", "rb").read
        sha2 = OpenSSL::Digest.hexdigest("sha256", binary_string)
        img_attachment = {
          usageType: "http://example.com/test/attachment",
          display: {"en-US" => "A test attachment"},
          contentType: "image/png",
          length: binary_string.length,
          sha2: sha2
        }
        json_object = {
          "actor" => {mbox: "mailto:edo_pc_test@realglobe.jp"},
          "verb" => {id: "http://realglobe.jp/test_verb"},
          "object" => {id: "http://realglobe.jp/test_object"},
          "attachments" => [img_attachment]
        }
        st = Statement.new({user_uid: "user_002", service_uid: "service_002"}.merge(json_object))
        st.save
        bson_binary_object = BSON::Binary.new(binary_string)
        Attachment.create(sha2: sha2, content: bson_binary_object, content_type: "image/png")
      end

      context "attachments パラメータが true の場合" do
        it "multipart/mixed 形式で返す" do
          get :index, {user_uid: "user_002", service_uid: "service_002", attachments: "true"}
          expect(response.status).to eq 200
          expect(response.content_type).to match "multipart/mixed; boundary=#{Statement::BOUNDARY_REGEXP}"
          expect(response.body.length).to be > 1000
        end
        it "添付ファイルがない statement でも、Content-Type は multipart/mixed" do
          get :index, {user_uid: "user_001", service_uid: "service_001", attachments: "true"}
          expect(response.status).to eq 200
          expect(response.content_type).to match "multipart/mixed; boundary=#{Statement::BOUNDARY_REGEXP}"
          expect(response.body.length).to be < 1000
        end
      end
      context "attachments パラメータがない場合" do
        it "ファイルは添付せず、application/json 形式で返す" do
          get :index, {user_uid: "user_002", service_uid: "service_002"}
          expect(response.status).to eq 200
          expect(response.content_type).to eq "application/json"
          expect(response.body.length).to be < 1000
        end
      end
      context "attachments パラメータが false の場合" do
        it "ファイルは添付せず、application/json 形式で返す" do
          get :index, {user_uid: "user_002", service_uid: "service_002", attachments: "false"}
          expect(response.status).to eq 200
          expect(response.content_type).to eq "application/json"
          expect(response.body.length).to be < 1000
        end
      end
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
        properties = {
          verb: {id: "http://realglobe.jp/test_verb"},
          object: {id: "http://realglobe.jp/test_object"}
        }
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 403
        expect(Statement.all.size).to eq statements_size
      end
      it "statement に verb がなければ 403 を返す" do
        properties = {
          actor: {mbox: "mailto:edo_pc_test@realglobe.jp"},
          object: {id: "http://realglobe.jp/test_object"}
        }
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 403
        expect(Statement.all.size).to eq statements_size
      end
      it "statement に object がなければ 403 を返す" do
        properties = {
          actor: {mbox: "mailto:edo_pc_test@realglobe.jp"},
          verb: {id: "http://realglobe.jp/test_verb"}
        }
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 403
        expect(Statement.all.size).to eq statements_size
      end
      it "actor、verb、object があれば statement が作成され、201 を返す" do
        properties = {
          actor: {mbox: "mailto:edo_pc_test@realglobe.jp"},
          verb: {id: "http://realglobe.jp/test_verb"},
          object: {id: "http://realglobe.jp/test_object"}
        }
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_001", service_uid: "service_001"}
        expect(response.status).to eq 201
        expect(Statement.all.size).to eq statements_size + 1
      end
      it "id が重複した場合、statement は作成されず、409 を返す" do
        properties = {
          id: "xxx-xxx-xxx-xxx",
          actor: {mbox: "mailto:edo_pc_test@realglobe.jp"},
          verb: {id: "http://realglobe.jp/test_verb"},
          object: {id: "http://realglobe.jp/test_object"}
        }
        request.env["RAW_POST_DATA"] = Oj.dump(properties)
        statements_size = Statement.all.size
        post :create, {user_uid: "user_xxx", service_uid: "service_xxx"}
        expect(response.status).to eq 409
        expect(Statement.all.size).to eq statements_size
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
            length: attachment[:content_body].length,
            sha2: attachment[:sha2]
          }
        end
        properties = {
          actor: {mbox: "mailto:edo_pc_test@realglobe.jp"},
          verb: {id: "http://realglobe.jp/test_verb"},
          object: {id: "http://realglobe.jp/test_object"},
          attachments: attachment_properties
        }
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

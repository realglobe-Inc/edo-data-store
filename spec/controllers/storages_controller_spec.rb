require 'rails_helper'

RSpec.describe StoragesController, :type => :controller do
  before :all do
    super_user = StoreAgent::Superuser.new
    super_user.workspace("user_001").create
    service_root = super_user.workspace("user_001").directory("service_001")
    service_root.create do |root_dir|
      root_dir.initial_metadata["owner"] = "user_001:service_001"
      root_dir.initial_permission = {"user_001:service_001" => StoreAgent.config.default_owner_permission}
    end
    user = StoreAgent::User.new("user_001:service_001")
    service_root = user.workspace("user_001").directory("service_001")
    service_root.file("file_000.txt").create
    dir = service_root.directory("dir_001")
    dir.create
    service_root.directory("dir_002").create
    service_root.directory("dir_002/delete_dir").create
    service_root.file("dir_002/delete_file.txt").create
    dir.file("file_001.txt").create("file_001.txt の中身")
    dir.file("file_002").create do |f|
      f.body = <<EOF
ファイル
file_002
の中身
EOF
    end
  end
  let :user_uid do
    "user_001"
  end
  let :service_uid do
    "service_001"
  end

  context "ディレクトリに対する操作" do
    context "GET /users/xxx/services/yyy/directory/*path" do
      it "path パラメータが無ければ root 直下のファイル、ディレクトリ一覧を返す" do
        get :list_files, {user_uid: user_uid, service_uid: service_uid}
        expect(response.status).to eq 200
        response_json_object = Oj.load(response.body)
        expect(response_json_object.map{|f| f["name"]}.sort).to eq ["dir_001", "dir_002", "file_000.txt"]
      end
      it "path がディレクトリなら、その直下のファイル、ディレクトリ一覧を返す" do
        get :list_files, {user_uid: user_uid, service_uid: service_uid, path: "dir_001"}
        expect(response.status).to eq 200
        response_json_object = Oj.load(response.body)
        expect(response_json_object.map{|f| f["name"]}.sort).to eq ["file_001.txt", "file_002"]
      end
      it "path がファイルなら 403 エラーを返す" do
        get :list_files, {user_uid: user_uid, service_uid: service_uid, path: "dir_001/file_001.txt"}
        expect_403_error(error_message: "dir_001/file_001.txt is not directory")
      end
      it "path にファイルが存在しなければ 404 エラーを返す" do
        get :list_files, {user_uid: user_uid, service_uid: service_uid, path: "file_003.txt"}
        expect_404_error(error_message: "file_003.txt not found")
      end
    end
    %w(post put).each do |method|
      context "#{method.upcase} /users/xxx/services/yyy/directory/*path" do
        it "path にファイルが存在しなければ、ディレクトリを作成する" do
          send method, :make_directory, {user_uid: user_uid, service_uid: service_uid, path: "dir_002/sub_dir_#{method}"}
          expect(response.status).to eq 201
#          expect(response.body).to eq Oj.dump({status: :ok, data: {directory: "/dir_002/sub_dir_#{method}"}})
          expect(response.body).to eq Oj.dump({status: :ok, data: {directory: "/service_001/dir_002/sub_dir_#{method}/"}})
        end
        it "path にファイルやディレクトリが存在すれば、403 エラーを返す" do
          send method, :make_directory, {user_uid: user_uid, service_uid: service_uid, path: "dir_001"}
          expect_403_error(error_message: "dir_001 is already exists")
        end
      end
    end
    context "DELETE /users/xxx/services/yyy/directory/*path" do
      it "path がディレクトリなら、削除される" do
        file_path = "tmp/store_agent_test/user_001/storage/service_001/dir_002/delete_dir"
        expect(File.exists?(file_path)).to be true
        delete :remove_directory, {user_uid: user_uid, service_uid: service_uid, path: "dir_002/delete_dir"}
        expect(response.status).to eq 200
        expect(response.body).to eq Oj.dump({status: :ok, data: {result: true}})
        expect(File.exists?(file_path)).to be false
      end
      it "path がファイルなら 403 エラーを返す" do
        delete :remove_directory, {user_uid: user_uid, service_uid: service_uid, path: "dir_001/file_001.txt"}
        expect_403_error(error_message: "dir_001/file_001.txt is not directory")
      end
      it "path にファイルやディレクトリが存在しなければ 404 エラーを返す" do
        delete :remove_directory, {user_uid: user_uid, service_uid: service_uid, path: "file_003.txt"}
        expect_404_error(error_message: "file_003.txt not found")
      end
    end
  end

  context "ファイルに対する操作" do
    context "GET /users/xxx/services/yyy/file/*path" do
      # path パラメータが無いと routing エラー
      it "path がファイルなら、その中身を返す" do
        get :read_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_001/file_002"}
        expect(response.status).to eq 200
        expect(response.body).to eq <<EOF
ファイル
file_002
の中身
EOF
      end
      it "path がディレクトリなら 403 エラーを返す" do
        get :read_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_001"}
        expect_403_error(error_message: "dir_001 is not file")
      end
      it "path にファイルが存在しなければ 404 エラーを返す" do
        get :read_file, {user_uid: user_uid, service_uid: service_uid, path: "file_003.txt"}
        expect_404_error(error_message: "file_003.txt not found")
      end
    end
    %w(post put).each do |method|
      context "#{method.upcase} /users/xxx/services/yyy/file/*path" do
        it "path にファイルが存在しなければ、ファイルを作成する" do
          request.env["RAW_POST_DATA"] = "file body"
          send method, :write_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_002/new_file_#{method}"}
          expect(response.status).to eq 201
#          expect(response.body).to eq Oj.dump({status: :ok, data: {path: "dir_002/new_file_#{method}", size: 9}})
          expect(response.body).to eq Oj.dump({status: :ok, data: {path: "/service_001/dir_002/new_file_#{method}", size: 9}})
        end
        it "path にファイルが存在する場合、上書きする" do
          body_str = "update file body #{method}"
          request.env["RAW_POST_DATA"] = body_str
          send method, :write_file, {user_uid: user_uid, service_uid: service_uid, path: "file_000.txt"}
          expect(response.status).to eq 200
#          expect(response.body).to eq Oj.dump({status: :ok, data: {path: "file_000.txt", size: body_str.length}})
          expect(response.body).to eq Oj.dump({status: :ok, data: {path: "/service_001/file_000.txt", size: body_str.length}})
        end
        it "path にディレクトリが存在する場合、403 エラーを返す" do
          send method, :write_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_001"}
          expect_403_error(error_message: "dir_001 is directory")
        end
      end
    end
    context "DELETE /users/xxx/services/yyy/file/*path" do
      it "path にファイルが存在する場合、削除する" do
        delete :remove_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_002/delete_file.txt"}
        expect(response.status).to eq 200
        expect(response.body).to eq Oj.dump({status: :ok, data: {result: true}})
      end
      it "path にディレクトリが存在する場合、403 エラーを返す" do
        delete :remove_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_001"}
        expect_403_error(error_message: "dir_001 is not file")
      end
      it "path にファイルやディレクトリが存在しなければ 404 エラーを返す" do
        delete :remove_file, {user_uid: user_uid, service_uid: service_uid, path: "file_003.txt"}
        expect_404_error(error_message: "file_003.txt not found")
      end
    end
  end
end

#--
# Copyright 2015 realglobe, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

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
        it "path にファイルが存在しなければディレクトリを作成し、201 を返す" do
          send method, :make_directory, {user_uid: user_uid, service_uid: service_uid, path: "dir_002/sub_dir_#{method}"}
          expect_201_created(data: {directory: "/service_001/dir_002/sub_dir_#{method}/"})
#          expect(response.status).to eq 201
#          expect(response.body).to eq Oj.dump({status: :ok, data: {directory: "/service_001/dir_002/sub_dir_#{method}/"}})
        end
        it "path にファイルやディレクトリが存在すれば、409 エラーを返す" do
          send method, :make_directory, {user_uid: user_uid, service_uid: service_uid, path: "dir_001"}
          expect_409_error(error_message: "dir_001 is already exists")
        end
      end
    end
    context "DELETE /users/xxx/services/yyy/directory/*path" do
      it "path がディレクトリなら削除され、204 を返す" do
        file_path = "tmp/store_agent_test/user_001/storage/service_001/dir_002/delete_dir"
        delete :remove_directory, {user_uid: user_uid, service_uid: service_uid, path: "dir_002/delete_dir"}
        expect_204_no_content
#        expect(response.status).to eq 200
#        expect(response.body).to eq Oj.dump({status: :ok, data: {result: true}})
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
        it "path にファイルが存在しなければファイルを作成し、201 を返す" do
          request.env["RAW_POST_DATA"] = "file body"
          send method, :write_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_002/new_file_#{method}"}
          expect_201_created(data: {path: "/service_001/dir_002/new_file_#{method}", size: 9})
#          expect(response.status).to eq 201
#          expect(response.body).to eq Oj.dump({status: :ok, data: {path: "/service_001/dir_002/new_file_#{method}", size: 9}})
        end
        context "path にファイルが存在する場合" do
          it "overwrite=true が指定されていなければ 403 エラーを返す" do
            body_str = "update file body #{method}"
            request.env["RAW_POST_DATA"] = body_str
            send method, :write_file, {user_uid: user_uid, service_uid: service_uid, path: "file_000.txt"}
            expect_403_error(error_message: "overwrite is not true")
          end
          it "overwrite=true が指定されていれば上書きする" do
            body_str = "update file body #{method}"
            request.env["RAW_POST_DATA"] = body_str
            send method, :write_file, {user_uid: user_uid, service_uid: service_uid, path: "file_000.txt", overwrite: "true"}
            expect(response.status).to eq 200
            expect(response.body.blank?).to be true
#          expect(response.body).to eq Oj.dump({status: :ok, data: {path: "/service_001/file_000.txt", size: body_str.length}})
          end
        end
        it "path にディレクトリが存在する場合、403 エラーを返す" do
          send method, :write_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_001"}
          expect_403_error(error_message: "dir_001 is directory")
        end
      end
    end
    context "DELETE /users/xxx/services/yyy/file/*path" do
      it "path にファイルが存在する場合は削除し、204 を返す" do
        delete :remove_file, {user_uid: user_uid, service_uid: service_uid, path: "dir_002/delete_file.txt"}
        expect_204_no_content
#        expect(response.status).to eq 200
#        expect(response.body).to eq Oj.dump({status: :ok, data: {result: true}})
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

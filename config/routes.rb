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

Rails.application.routes.draw do
  # API
  scope "v1", format: false do
    # ユーザー管理サーバーから利用するAPI
    resources :users, only: %w(index create destroy), param: :user_uid
    resources :users, only: %w(), param: :uid do
      # 認証サーバーから利用するAPI
      resources :services, only: %w(index create destroy), param: :service_uid
      resources :services, only: %w(), param: :uid, service_uid: /.*/ do
        # サービスから利用するAPI
        resources :directory, only: %w() do
          collection do
            get "/(*path)" => "storages#list_files"
            match "/(*path)" => "storages#make_directory", via: %w(post put)
            delete "/(*path)" => "storages#remove_directory"
          end
        end
        resources :file, only: %w() do
          collection do
            get "/*path" => "storages#read_file"
            match "/*path" => "storages#write_file", via: %w(post put)
            delete "/*path" => "storages#remove_file"
          end
        end
        resources :permissions, only: %w() do
          collection do
            get "/(*path)" => "storages#permissions"
            match "/(*path)" => "storages#set_permissions", via: %w(post put patch)
            delete "/(*path)" => "storages#unset_permissions"
          end
        end
        get "revisions/(*path)" => "storages#revisions"
        post "copy/*path" => "storages#copy"
        post "move/*path" => "storages#move"
        resources :statements, only: %w() do
          collection do
            get "/" => "statements#index"
            match "/" => "statements#create", via: %w(post put)
          end
        end
      end
      resources :statements, only: %w() do
        collection do
          get "/" => "statements#users_index"
        end
      end
      resources :permissions, only: %w(index)
    end
    resources :statements, only: %w() do
      collection do
        get "/" => "statements#last_statements"
      end
    end
  end

  resources :users, only: %w(), param: :uid do
    # 利用許可
    resources :permissions, only: %w(new create)
  end
end

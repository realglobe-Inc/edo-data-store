Rails.application.routes.draw do
  # API
  scope "v1", format: false do
    # ユーザー管理サーバーから利用するAPI
    resources :users, only: %w(index create destroy), param: :user_uid
    resources :users, only: %w(), param: :uid do
      # 認証サーバーから利用するAPI
      resources :services, only: %w(index create destroy), param: :service_uid
      resources :services, only: %w(), param: :uid do
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
            post "/(*path)" => "storages#set_permissions"
            delete "/(*path)" => "storages#unset_permissions"
          end
        end
        post "copy/*path" => "storages#copy"
        post "move/*path" => "storages#move"
        resources :statements, only: %w(index create)
      end
      resources :permissions, only: %w(index)
    end
  end

  resources :users, only: %w(), param: :uid do
    # 利用許可
    resources :permissions, only: %w(new create)
  end
end

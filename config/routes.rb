Rails.application.routes.draw do
  # API
  scope "v1", format: false do
    # ユーザー管理サーバーから利用するAPI
    resources :users, only: %w(index show create update destroy), param: :user_uid
    resources :users, only: %w(), param: :uid do
      # 認証サーバーから利用するAPI
      resources :services, only: %w(index show create update destroy), param: :service_uid
      resources :services, only: %w(), param: :uid do
        # サービスから利用するAPI
        resources :directory, only: %w() do
          collection do
            get "/(*path)" => "storages#ls"
            match "/*path" => "storages#mkdir", via: %w(post put)
            delete "/*path" => "storages#rmdir"
          end
        end
        resources :file, only: %w() do
          collection do
            get "/*path" => "storages#show"
            match "/*path" => "storages#create", via: %w(post put)
            delete "/*path" => "storages#destroy"
          end
        end
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

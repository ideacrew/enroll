Notifier::Engine.routes.draw do
  mount Ckeditor::Engine => '/notifier/ckeditor'

  resources :notice_kinds do
    member do
      get :preview
    end

    collection do
      post :delete_notices
      get :download_notices
      get :get_tokens
      get :get_placeholders
    end
  end
end
Notifier::Engine.routes.draw do
  mount Ckeditor::Engine => '/notifier/ckeditor'

  resources :notice_kinds do
    member do
      get :preview
    end

    collection do
      post :delete_notices
    end
  end
end
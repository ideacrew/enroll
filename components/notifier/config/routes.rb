Notifier::Engine.routes.draw do

  resources :notice_kinds do
    member do
      get :preview
    end
  end
end

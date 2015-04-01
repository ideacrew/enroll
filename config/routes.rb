Rails.application.routes.draw do

  # You can have the root of your site routed with "root"
  root 'welcome#index'

  # get 'user/index'

  namespace :broker_agencies do
    root 'welcome#index'
    get 'new'
    get 'my_account'

    resources :broker_profile do
      get 'new'
      get 'my_account'
    end
  end

  namespace :employers do
    root 'welcome#index'

    resources :employer_profiles do
      get 'new'
      get 'my_account'
      resources :family
    end
  end

  resources :employee_roles do
    get 'new'
    get 'my_account'
  end

  resources :people do
    get 'select_employer'
    get 'my_account'
    collection do
      get 'plans_converson'
      post 'match_person'
      get 'get_employer'
      post 'person_confirm'
      post 'person_landing'
      get 'person_landing'
      post 'plan_details'
      post 'dependent_details'
      post 'add_dependents'
      get 'dependent_details'
      post 'save_dependents'
      delete 'remove_dependents'
      
      get 'select_plan'
    end
    
  end



  devise_for :users, :controllers => { registrations: "registrations",
                                        sessions: "sessions" }
  # devise_scope :user do
  #   get "/sign_in" => "devise/sessions#new"
  #   get "/sign_up" => "devise/registrations#new"
  # end

  resources :families do
    get 'page/:page', :action => :index, :on => :collection

    resources :family_members, only: [:index, :new, :create]
    resources :households
  end
 
  resources :family_members, only: [:show, :edit, :update] do
     member do
       get :link_employee
       get :challenge_identity
     end
   end

  resources :employee_roles, :only => [:new, :create]
 

  # Temporary for Generic Form Template
  match 'templates/form-template', to: 'welcome#form_template', via: [:get, :post]

  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".


  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end

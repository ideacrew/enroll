Rails.application.routes.draw do

  devise_for :users

  namespace :exchanges do
    resources :hbx_profiles do
      root 'hbx_profiles#show'

      collection do
        get :employer_index
        get :family_index
      end

      # resources :hbx_staff_roles, shallow: true do
      resources :hbx_staff_roles do
        # root 'hbx_profiles/hbx_staff_roles#show'
      end
    end

    # get 'hbx_profiles', to: 'hbx_profiles#welcome'
    # get 'hbx_profiles/:id', to: 'hbx_profiles#show', as: "my_account"
    # get 'hbx_profiles/new'
    # get 'hbx_profiles/create'
    # get 'hbx_profiles/update'
    # get 'hbx_profiles/broker_agency_index'
    # get 'hbx_profiles/insured_index'
  end

  namespace :insured do
    resources :families, :only => [:show] do
    end

    resources :plan_shoppings, :only => [:show] do
      member do
        post 'checkout'
        post 'thankyou'
      end
    end

    resources :families do
      get 'new'

      resources :people do
        collection do
          get 'search'
        end
      end
    end
  end

  namespace :employers do
    root 'employer_profiles#new'

    resources :premium_statements, :only => [:show]

    #TODO REFACTOR
    resources :people do
      collection do
        get 'search'
        post 'match'
      end
    end
    resources :employer_profiles do
      get 'new'
      get 'my_account'
      collection do
        get 'welcome'
        get 'search'
        post 'match'
      end
      resources :plan_years do
        get 'recommend_dates', on: :collection
      end
      resources :family do
        get 'delink'
        get 'terminate'
        get 'rehire'
        get 'benefit_group', on: :member
        patch 'assignment_benefit_group', on: :member
      end
    end
  end

  namespace :carriers do
    resources :carrier_profiles do
    end
  end

  namespace :broker_agencies do
    root 'profiles#new'
    resources :profiles, only: [:new, :create, :show, :index]
  end

  resources :translations

  ############################# TO DELETE BELOW ##############################

  # FIXME: Do this properly later
  namespace :products do
    resources :plans, controller: :qhp, :only => [] do
      collection do
        get 'comparison'
        get 'summary'
      end
    end
  end

  namespace :consumer do
    resources :employee_dependents do
      collection do
        get :group_selection
      end
    end

    resources :employee, :controller=>"employee_roles" do
      collection do
        get :match
        get 'welcome'
        get 'search'
      end
    end
    root 'employee_roles#show'
  end

  # used to select which people are going to be covered before plan selection
  get 'group_selection/new', to: 'group_selection#new'
  post 'group_selection/new', to: 'group_selection#new'
  post 'group_selection/create', to: 'group_selection#create'

  resources :people do #TODO Delete
    get 'select_employer'
    get 'my_account'
    get 'person_landing'

    collection do
      post 'person_confirm'
      post 'plan_details'
      get 'check_qle_marriage_date'
    end

    member do
      get 'get_member'
    end

  end

  resources :consumer_profiles, :only => [] do
    collection do
      get 'home'
      get 'plans'
      get 'personal'
      get 'family'
    end
  end

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
  #
  # You can have the root of your site routed with "root"
  root 'welcome#index'
end

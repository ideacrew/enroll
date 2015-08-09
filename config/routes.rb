Rails.application.routes.draw do

  devise_for :users

  namespace :exchanges do
    resources :inboxes, only: [:show, :destroy]

    resources :hbx_profiles do
      root 'hbx_profiles#show'

      collection do
        get :family_index
        get :employer_index
        get :broker_agency_index
        get :issuer_index
        get :product_index
        get :configuration
        post :set_date
      end

      member do
        get :home
        get :inbox
      end

      # resources :hbx_staff_roles, shallow: true do
      resources :hbx_staff_roles do
        # root 'hbx_profiles/hbx_staff_roles#show'
      end
    end


    resources :broker_applicants

    # get 'hbx_profiles', to: 'hbx_profiles#welcome'
    # get 'hbx_profiles/:id', to: 'hbx_profiles#show', as: "my_account"
    # get 'hbx_profiles/new'
    # get 'hbx_profiles/create'
    # get 'hbx_profiles/update'
    # get 'hbx_profiles/broker_agency_index'
    # get 'hbx_profiles/insured_index'
  end

  namespace :insured do
    resources :plan_shoppings, :only => [:show] do
      member do
        get 'receipt'
        get 'print_waiver'
        post 'checkout'
        post 'thankyou'
        post 'waive'
        post 'terminate'
      end
    end

    resources :inboxes, only: [:new, :create, :show, :destroy]
    resources :families, only: [:show] do
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
    resources :inboxes, only: [:new, :create, :show, :destroy]
    resources :employer_profiles do
      get 'new'
      get 'my_account'
      get 'show_profile'
      get 'consumer_override'
      collection do
        get 'welcome'
        get 'search'
        post 'match'
        get 'inbox'
      end
      resources :plan_years do
        get 'recommend_dates', on: :collection
        get 'reference_plan_options', on: :collection
        post 'publish'
        post 'force_publish'
        get 'search_reference_plan', on: :collection
        get 'calc_employer_contributions', on: :collection
      end

      resources :broker_agency, only: [:index, :show, :create] do
        collection do
          get :active_broker
        end
        get :terminate
      end

      resources :census_employees, only: [:new, :create, :edit, :update, :show] do
        get :delink
        get :terminate
        get :rehire
        get :benefit_group, on: :member
        patch :assignment_benefit_group, on: :member
      end
    end
  end

  # match 'thank_you', to: 'broker_roles#thank_you', via: [:get]
  match 'broker_registration', to: 'broker_agencies/broker_roles#new_broker', via: [:get]

  namespace :carriers do
    resources :carrier_profiles do
    end
  end

  namespace :broker_agencies do
    root 'profiles#new'
    resources :inboxes, only: [:new, :create, :show, :destroy] do
      get :msg_to_portal
    end
    resources :profiles, only: [:new, :create, :show, :index] do
      get :inbox

      collection do
        get :employers
        get :messages
      end

      resources :applicants
    end
    resources :broker_roles, only: [:create] do
      root 'broker_roles#new_broker'
      collection do
        get :new_broker
        get :new_staff_member
        get :new_broker_agency
        get :search_broker_agency
      end
    end
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
      get 'check_qle_date'
      get 'inbox'
      get 'purchase'
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

  resources :invitations, only: [] do
    member do
      get :claim
    end
  end
  resources :office_locations, only: [:new]

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

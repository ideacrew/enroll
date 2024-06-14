# frozen_string_literal: true

Rails.application.routes.draw do

  get 'errors/not_found'
  get 'errors/internal_server_error'
  # For custom exceptions controller
  resources :exceptions, only: [:show]
  # https://gist.github.com/mlanett/a31c340b132ddefa9cca
  # Make sure all exception throwing status codes get sent to the "friendly" exception page
  (400..510).to_a.map(&:to_s).each do |code|
    get code, :to => "exceptions#show", via: :all
  end

  default_url_options Rails.application.config.action_mailer.default_url_options
  require 'resque/server'

  require 'sidekiq/web'

#  mount Resque::Server, at: '/jobs'
  mount BenefitSponsors::Engine,      at: "/benefit_sponsors"
  mount BenefitMarkets::Engine,       at: "/benefit_markets"
  mount SponsoredBenefits::Engine,    at: "/sponsored_benefits"
  mount TransportGateway::Engine,     at: "/transport_gateway"
  mount TransportProfiles::Engine,    at: "/transport_profiles"
  mount Notifier::Engine,             at: "/notifier" if EnrollRegistry.feature_enabled?(:notices_tab)
  mount FinancialAssistance::Engine,  at: '/financial_assistance'

  devise_for :users, :controllers => { :registrations => "users/registrations", :sessions => 'users/sessions', :passwords => 'users/passwords' }

  authenticate :user, ->(u) { u.has_hbx_staff_role? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  get 'datatables/*path.:json', to: 'application#resource_not_found'
  get 'insured/consumer_role/help_paying_coverage.:inc', to: 'application#resource_not_found'
  get 'check_time_until_logout' => 'session_timeout#check_time_until_logout', :constraints => { :only_ajax => true }
  get 'reset_user_clock' => 'session_timeout#reset_user_clock', :constraints => { :only_ajax => true }
  get 'unsupported_browser' => 'users#unsupported_browser'

  match "hbx_admin/about_us" => "hbx_admin#about_us", as: :about_us, via: :get
  match "hbx_admin/registry" => "hbx_admin#registry", as: :registry, via: :get
  match "hbx_admin/update_aptc_csr" => "hbx_admin#update_aptc_csr", as: :update_aptc_csr, via: [:get, :post]
  match "hbx_admin/edit_aptc_csr" => "hbx_admin#edit_aptc_csr", as: :edit_aptc_csr, via: [:get, :post], defaults: { format: 'js' }
  match "hbx_admin/calculate_aptc_csr" => "hbx_admin#calculate_aptc_csr", as: :calculate_aptc_csr, via: :get
  post 'show_hints' => 'welcome#show_hints', :constraints => { :only_ajax => true }
  get "qna_bot", to: 'welcome#qna_bot'
  post 'submit_notice' => "hbx_admin#submit_notice", as: :submit_notice

  namespace :users do
    resources :orphans, only: [:index, :show, :destroy]
    post :challenge, controller: 'security_question_responses', action: 'challenge'
    post :authenticate, controller: 'security_question_responses', action: 'authenticate'
  end

  resources :users do
    resources :security_question_responses, controller: "users/security_question_responses"
    post "/security_question_responses/replace", controller: "users/security_question_responses", action: 'replace'

    member do
      get :reset_password, :lockable, :confirm_lock, :login_history, :change_username_and_email
      put :confirm_reset_password, :confirm_change_username_and_email

      post :unlock
    end
  end

  resources :saml, only: [] do
    collection do
      post :login
      post :redirection_test
      get :logout
      get :navigate_to_assistance
      get :account_expired
    end
  end

  get 'payment_transactions/generate_saml_response', to: 'payment_transactions#generate_saml_response'

  namespace :exchanges do

    resources :bulk_notices, format: false

    resources :inboxes, only: [:show, :destroy]
    resources :announcements, format: false, only: [:index, :create, :destroy] do
      get :dismiss, on: :collection
    end
    resources :agents_inboxes, only: [:show, :destroy]

    resources :residents, only: [:create, :edit, :update] do
      get :search, on: :collection
      post :match, on: :collection
      post :build, on: :collection
      get :begin_resident_enrollment, on: :collection
      get :resume_resident_enrollment, on: :collection
      get :ridp_bypass, on: :collection
      get :find_sep, on: :collection
    end

    # TODO: Consider wrapping this in a preprod conditional
    resources :seeds, only: [:index, :new, :create, :edit, :update]

    if EnrollRegistry.feature_enabled?(:sep_types)
      resources :manage_sep_types, format: false do
        root 'manage_sep_types#sep_types_dt'
        collection do
          get 'sep_types_dt'
          get 'sorting_sep_types'
          patch 'sort'
          get 'sep_type_to_publish'
          get 'sep_type_to_expire'
          post 'publish_sep_type'
          post 'expire_sep_type'
          get 'clone'
        end
      end
    end

    resources :issuers, only: [:index] do
      post :bulk_upload
      resources :products, only: [:index]
    end

    resources :hbx_profiles do
      root 'hbx_profiles#show'

      collection do
        post :reinstate_enrollment
        get :family_index
        get :family_index_dt
        get :outstanding_verification_dt
        post :families_index_datatable
        get :employer_index
        get :employer_poc
        post :employer_poc_datatable
        get :employer_invoice
        get :employer_datatable
        post :employer_invoice_datatable
        post :generate_invoice
        post :disable_ssn_requirement
        get :edit_force_publish
        post :force_publish
        get :broker_agency_index
        get :general_agency_index
        get :configuration
        post :set_date
        post :update_setting
        get :staff_index
        get :assister_index
        get :request_help
        get :aptc_csr_family_index
        get :binder_index
        get :binder_index_datatable
        post :binder_paid
        get :verification_index
        get :cancel_enrollment
        post :update_cancel_enrollment
        get :terminate_enrollment
        post :update_terminate_enrollment
        get :drop_enrollment_member
        post :update_enrollment_member_drop
        post :add_new_sep
        get :update_effective_date
        get :calculate_sep_dates
        get :check_for_renewal_flag
        get :add_sep_form
        get :hide_form
        get :show_sep_history
        get :view_terminated_hbx_enrollments
        get :view_enrollment_to_update_end_date
        post :update_enrollment_terminated_on_date
        get :calendar_index
        get :user_account_index
        get :get_user_info
        get :oe_extendable_applications
        get :oe_extended_applications
        get :edit_open_enrollment
        post :extend_open_enrollment
        post :close_extended_open_enrollment
        get :new_benefit_application
        get :new_secure_message
        post :create_send_secure_message
        post :create_benefit_application
        get :edit_fein
        post :update_fein
        get :identity_verification
        post :identity_verification_datatable
        get :new_eligibility
      end

      member do
        post :transmit_group_xml
        get :transmit_group_xml
        get :home
        get :inbox
      end

      # resources :hbx_staff_roles, shallow: true do
      resources :hbx_staff_roles do
        # root 'hbx_profiles/hbx_staff_roles#show'
      end
    end

    resources :employer_applications do
      put :terminate
      put :cancel
      collection do
        get :term_reasons
        put :reinstate
      end
    end

    resources :agents do
      collection do
        get :home
        get :begin_consumer_enrollment
        get :begin_employee_enrollment
        get :resume_enrollment
        get :show
      end
      member do
        get :inbox
      end
    end

    resources :broker_applicants
    resources :security_questions, only: [:index, :new, :create, :edit, :update, :destroy]

    # get 'hbx_profiles', to: 'hbx_profiles#welcome'
    # get 'hbx_profiles/:id', to: 'hbx_profiles#show', as: "my_account"
    # get 'hbx_profiles/new'
    # get 'hbx_profiles/create'
    # get 'hbx_profiles/update'
    # get 'hbx_profiles/broker_agency_index'
    # get 'hbx_profiles/insured_index'
  end

  namespace :insured do
    get 'verification_documents/upload', to: 'verification_documents#upload'
    post 'verification_documents/upload', to: 'verification_documents#upload'
    get 'verification_documents/download/:key', to: 'verification_documents#download'
    get 'paper_applications/upload', to: 'paper_applications#upload'
    post 'paper_applications/upload', to: 'paper_applications#upload'
    get 'paper_applications/download/:key', to: 'paper_applications#download'
    get 'ridp_documents/upload', to: 'ridp_documents#upload'
    post 'ridp_documents/upload', to: 'ridp_documents#upload'
    get 'ridp_documents/download/:key', to: 'ridp_documents#download'
    resources :ridp_documents, only: [:destroy]


    resources :plan_shoppings, :only => [:show] do
      member do
        get 'plans'
        get 'receipt'
        get 'print_waiver'
        post 'checkout'
        get 'thankyou'
        get 'waive'
        post 'waive'
        post 'terminate'
        post 'set_elected_aptc'
        get 'plan_selection_callback'
      end
    end

    resources :interactive_identity_verifications, format: false, only: [:create, :new, :update] do
      collection do
        get 'failed_validation'
        get 'service_unavailable'
      end
    end

    resources :fdsh_ridp_verifications, format: false, only: [:create, :new] do
      collection do
        get 'failed_validation'
        get 'service_unavailable'
        get 'wait_for_primary_response'
        get 'wait_for_secondary_response'
        get 'check_primary_response_received'
        get 'check_secondary_response_received'
        get 'primary_response'
        get 'secondary_response'
      end
    end

    resources :inboxes, only: [:new, :create, :show, :destroy]
    resources :families, only: [:new] do
      member do
        delete 'delete_consumer_broker'
        get 'generate_out_of_pocket_url'
      end

      collection do
        get 'home'
        get 'manage_family'
        get 'personal'
        get 'inbox', format: false
        get 'healthcare_for_childcare_program'
        get 'event_logs'
        post 'event_logs'
        get 'healthcare_for_childcare_program_form'
        put 'update_osse_eligibilities'
        get 'brokers'
        get 'verification', format: false
        get 'upload_application'
        get 'document_upload'
        get 'find_sep'
        post 'record_sep'
        get 'check_qle_date'
        get 'sep_zip_compare'
        get 'check_move_reason'
        get 'check_insurance_reason'
        get 'check_marriage_reason'
        get 'purchase'
        get 'family'
        get 'upload_notice_form'
        post 'upload_notice'
        get 'transition_family_members'
        post 'transition_family_members_update'
        get 'enrollment_history'
      end

      resources :people do
        collection do
          get 'search'
        end
      end
    end

    resources :consumer_role, controller: 'consumer_roles', only: [:create, :edit, :update] do
      get :ssn_taken, on: :collection
      get :search, on: :collection
      get :privacy, on: :collection
      post :match, on: :collection
      post :build, on: :collection
      get :ridp_agreement, on: :collection
      get :help_paying_coverage, to: 'consumer_roles/help_paying_coverage', on: :collection, as: :help_paying_coverage
      get :help_paying_coverage_response, to: 'consumer_roles/help_paying_coverage_response', on: :collection, as: :help_paying_coverage_response
      post :update_application_type
      get :upload_ridp_document, on: :collection
      get :immigration_document_options, on: :collection
      ##get :privacy, on: :collection
    end

    resources :employee, :controller => "employee_roles", only: [:create, :edit, :update, :show] do
      collection do
        get 'new_message_to_broker'
        post 'send_message_to_broker'
        post :match
        get 'search'
        get 'privacy'
        get 'welcome'
      end
    end

    root 'families#home'

    resources :family_members do
      get :resident_index, on: :collection
      get :new_resident_dependent, on: :collection
      get :edit_resident_dependent, on: :member
      get :show_resident_dependent, on: :member
    end

    resources :group_selections, format: false, controller: "group_selection", only: [:new, :create] do
      collection do
        post :cancel
        post :edit_aptc
        post :term_or_cancel
        post :terminate
        get :edit_plan
        get :terminate_selection
        get :terminate_confirm
      end
    end

  end

  namespace :employers do

    # Redirect from Enroll old model to Enroll new model
    match '/employer_profiles/new', to: redirect('/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor'), via: [:get, :post]
    #match '/employer_profiles/:id/*path' , to: redirect('/'), via: [:get, :post]
    #match '/employer_profiles/:id' , to: redirect('/'), via: [:get, :post]
    match '/', to: redirect('/benefit_sponsors/profiles/registrations/new?profile_type=benefit_sponsor'), via: [:get, :post]

    post 'search', to: 'employers#search'

    resources :premium_statements, :only => [:show]

    resources :employer_staff_roles, :only => [:create, :destroy] do
      member do
        get :approve
      end
    end

    #TODO: refactor
    resources :people do
      collection do
        get 'search'
        post 'match'
      end
    end

    resources :employer_attestations do
      get 'authorized_download'
      get 'verify_attestation'
      delete 'delete_attestation_documents'
      #get 'revert_attestation'
    end
    resources :inboxes, only: [:new, :create, :show, :destroy]
    resources :employer_profiles do
      get 'new'
      get 'my_account'
      get 'show_profile'
      get 'link_from_quote'
      get 'consumer_override'
      get 'export_census_employees'
      get 'bulk_employee_upload_form'
      post 'bulk_employee_upload'

      member do
        #match '/:id/*path' , to: redirect('/'), via: [:get, :post]
        get "download_invoice"
        get 'new_document'
        post 'download_documents'
        post 'delete_documents'
        post 'upload_document'
        post 'generate_checkbook_urls'
      end

      collection do
        get 'welcome'
        get 'search'
        post 'match'
        get 'inbox'
        get 'counties_for_zip_code'
        get 'generate_sic_tree'
      end
      resources :plan_years do
        get "late_rates_check"
        get 'reference_plans'
        get 'dental_reference_plans'
        get 'generate_dental_carriers_and_plans'
        get 'generate_health_carriers_and_plans', on: :collection
        get 'plan_details' => 'plan_years#plan_details', on: :collection
        get 'recommend_dates', on: :collection
        get 'reference_plan_options', on: :collection
        post 'revert'
        post 'publish'
        post 'force_publish'
        get 'search_reference_plan', on: :collection
        post 'make_default_benefit_group'
        post 'delete_benefit_group'
        get 'calc_employer_contributions', on: :collection
        get 'calc_offered_plan_contributions', on: :collection
        get 'employee_costs', on: :collection
        get 'reference_plan_summary', on: :collection

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
        get :cobra
        collection do
          get :confirm_effective_date
          post :change_expected_selection
        end
        get :cobra_reinstate
        get :benefit_group, on: :member
      end
    end
  end

  # match 'thank_you', to: 'broker_roles#thank_you', via: [:get]

  match 'broker_registration', to: redirect('benefit_sponsors/profiles/registrations/new?profile_type=broker_agency'), via: [:get]
  # match 'general_agency_registration', to: redirect('benefit_sponsors/profiles/registrations/new?profile_type=general_agency'), via: [:get]

  namespace :carriers do
    resources :carrier_profiles do
    end
  end

  namespace :broker_agencies do
    root 'profiles#new'

    resources :profiles, except: [:new, :create, :show, :index, :edit, :update, :destory] do
      resources :applicants
    end

    resources :broker_roles do

      resources :quotes do
        root 'quotes#index'
        collection do
          post :quotes_index_datatable
          get :new_household, :format => "js"
          post :update_benefits
          post :publish_quote
          get :get_quote_info
          get :copy
          get :set_plan
          get :publish
          get :criteria
          get :plan_comparison
          get :health_cost_comparison
          get :dental_cost_comparison
          get 'published_quote/:id', to: 'quotes#view_published_quote'
          get :export_to_pdf
          get :download_pdf
          get :dental_plans_data
          get :my_quotes
          get :employees_list
          get :employee_type
        end
        member do
          get :upload_employee_roster
          post :build_employee_roster
          get :delete_quote #fits with our dropdown ajax pattern
          get :download_employee_roster
          post :delete_member
          delete :delete_household
          post :delete_benefit_group
          get :delete_quote_modal
        end

        resources :quote_benefit_groups do
          get :criteria
          get :get_quote_info
          post :update_benefits
          get :plan_comparison
        end
      end
    end
  end

  match 'general_agency_registration', to: 'general_agencies/profiles#new_agency', via: [:get]
  namespace :general_agencies do
    root 'profiles#new'
    resources :profiles do
      collection do
        get :new_agency_staff
        get :search_general_agency
        get :new_agency
        get :messages
        get :agency_messages
        get :inbox
        get :edit_staff
        post :update_staff
      end
      member do
        get :employers
        get :families
        get :staffs
      end
    end
    resources :inboxes, only: [:new, :create, :show, :destroy] do
      get :msg_to_portal
    end
  end

  resources :translations

  get 'event_logs', to: 'event_logs#index'
  post 'event_logs', to: 'event_logs#index'

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

  # TO-DO: this routes were split into costumer and employer namespaces
  # however a lot of helpers needs this magic methods, we need to do a further
  # refactor to remove this dependencies
  resources :people, only: [:show, :index, :update]

  match 'families/home', to: 'insured/families#home', via: [:get], as: "family_account"

  match "hbx_profiles/edit_dob_ssn" => "exchanges/hbx_profiles#edit_dob_ssn", as: :edit_dob_ssn, via: [:get, :post]
  match "hbx_profiles/update_dob_ssn" => "exchanges/hbx_profiles#update_dob_ssn", as: :update_dob_ssn, via: :post, defaults: 'js'
  match "hbx_profiles/verify_dob_change" => "exchanges/hbx_profiles#verify_dob_change", as: :verify_dob_change, via: :post, defaults: 'js'
  match "hbx_profiles/create_eligibility" => "exchanges/hbx_profiles#create_eligibility", as: :create_eligibility, via: :post, defaults: { format: 'js' }
  match "hbx_profiles/process_eligibility" => "exchanges/hbx_profiles#process_eligibility", as: :process_eligibility, via: [:post], defaults: { format: 'js' }

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

  get "document/employees_template_download" => "documents#employees_template_download", as: :document_employees_template_download
  get "document/authorized_download/:model/:model_id/:relation/:relation_id" => "documents#authorized_download", as: :authorized_document_download
  get "document/cartafact_download/:model/:model_id/:relation/:relation_id" => "documents#cartafact_download", as: :cartafact_document_download

  resources :documents, only: [:destroy] do
    get :product_sbc_download
    get :employer_attestation_document_download
    get :autocomplete_organization_legal_name, :on => :collection
    collection do
      put :change_person_aasm_state
      get :show_docs
      put :update_verification_type
      put :update_ridp_verification_type
      get :enrollment_verification
      put :extend_due_date
      get :fed_hub_request
      post :fed_hub_request
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

  resources :external_applications, only: [:show]

  namespace :api, defaults: {format: 'json'} do
    namespace :v1 do
      scope module: :api do
        get :ping
      end

      resources :brokers, only: %i[index show] do
        collection do
          get :broker_staff
        end
      end

      resources :agencies, only: %i[index] do
        collection do
          get :agency_staff
          get 'agency_staff/:person_id', to: 'agencies#agency_staff_detail'
          post 'agency_staff/:person_id/terminate/:role_id', to: 'agencies#terminate'
          patch 'agency_staff/:person_id', to: 'agencies#update_person'
          patch 'agency_staff/:person_id/email', to: 'agencies#update_email'
          get :primary_agency_staff
        end
      end

      resources :slcsp, :only => []  do
        collection do
          post :plan
        end
      end
    end

    namespace :v2 do
      resources :auth_tokens, only: [] do
        collection do
          post :refresh
          delete :logout
        end
      end

      resources :users, only: [] do
        collection do
          get :current
        end
      end

      resources :slcsp_calculator, :only => []  do
        collection do
          post :estimate
        end
      end
    end
  end

  root 'welcome#index'
end

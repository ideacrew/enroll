BenefitSponsors::Engine.routes.draw do
  namespace :profiles do
    namespace :broker_agencies do
      resources :broker_roles, only: [:create] do
        collection do
          get :new_broker
          get :new_staff_member
          get :new_broker_agency, as: 'broker_registration'
          get :search_broker_agency
        end
      end
    end
  end

  namespace :organizations do
    resource :office_locations do
      member do
        get :new
      end
    end
  end
end

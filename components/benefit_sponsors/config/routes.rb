BenefitSponsors::Engine.routes.draw do
  namespace :profiles do
    resources :registrations

    resources :employer_profile_registrations, only: [:new, :create]

    namespace :broker_agencies do
      resources :broker_agency_profiles, only: [:new, :create, :show, :index, :edit, :update] do

        collection do
          get :family_index
          get :messages
          get :agency_messages
          get :broker_portal
        end
        member do
          post :clear_assign_for_employer
          get :assign
          post :update_assign
          post :family_datatable
        end
      end
    end

    namespace :employers do
      resources :employer_profiles, only: [:show] do
        get :show_pending
      end
      resources :employer_staff_roles
    end
  end

  namespace :organizations do
    resource :office_locations do
      member do
        get :new
      end
    end
  end

  resources :benefit_sponsorships, only: [] do 
    resources :benefit_applications do
      resources :benefit_packages do
        resources :sponsored_benefits, only: :new
      end
    end
  end
end

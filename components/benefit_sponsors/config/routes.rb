BenefitSponsors::Engine.routes.draw do
  namespace :profiles do
    resources :registrations

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
          get :inbox
        end
      end
      resources :broker_applicants
    end

    namespace :employers do
      resources :employer_profiles, only: [:show] do
        get :show_pending

        member do
          get :inbox
        end
      end
      resources :employer_staff_roles
    end
  end

  namespace :inboxes do
    resources :messages, only: [:show, :destroy] do
      get :msg_to_portal
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
    resources :benefit_applications, controller: "benefit_applications/benefit_applications" do

      resources :benefit_packages do
        resources :sponsored_benefits, only: :new
      end
    end
  end
end

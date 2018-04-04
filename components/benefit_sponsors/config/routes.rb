BenefitSponsors::Engine.routes.draw do
  namespace :profiles do
    resources :registrations

    namespace :broker_agencies do
      resources :broker_agency_profiles, only: [:new, :create, :show, :index, :edit, :update] do

        collection do
          get :family_index
          get :messages
          get :agency_messages
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
      resources :employer_profiles
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
end

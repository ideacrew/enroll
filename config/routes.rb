SponsoredBenefits::Engine.routes.draw do

  namespace :sponsored_benefits do
    namespace :census_members do
      resources :plan_design_census_employees
    end
  end

  namespace :organizations do
    resources :profiles do
      get :employers
      member do
        get :new
        post :employer_datatable
      end
    end

    resource :office_locations do
      member do
        get :new
      end
    end
  end

  # namespace :benefit_sponsorships do
  #   resources :plan_design_employer_profiles
  # end
  #
  resources :benefit_sponsorships, only: [] do
    resources :benefit_applications, controller: 'benefit_applications/benefit_applications', only: [:index, :new, :create]
  end

  resources :benefit_applications, controller: 'benefit_applications/benefit_applications', only: [:show, :edit, :update, :destroy]

  resources :broker_agency_profile, path: 'broker', as: 'broker', only: [] do
    resources :plan_design_organization, path: 'client', as: 'client'
  end
end

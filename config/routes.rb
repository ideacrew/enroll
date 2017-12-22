SponsoredBenefits::Engine.routes.draw do

  namespace :benefit_sponsorships do
    resources :plan_design_proposals
  end

  namespace :census_members do
    resources :plan_design_census_employees
  end

  namespace :organizations do
    resources :profiles do
      get :employers
      member do
        get :new
        # post :employer_datatable
        get :edit
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
  # resources :benefit_sponsorships, only: [] do
  #   resources :benefit_applications, controller: 'benefit_applications/benefit_applications', only: [:index, :new, :create]
  # end
  #
  # resources :broker_agency_profile, path: 'broker', as: 'broker', only: [] do
  #   resources :plan_design_organization, path: 'customer', as: 'customer', only: [] do
  #     resources :plan_design_proposals, controller: 'benefit_sponsorships/plan_design_proposals', only: [:index, :new, :create]
  #   end
  # end

  resources :plan_design_organizations, only: [] do
    resources :plan_design_proposals, controller: 'benefit_sponsorships/plan_design_proposals'
  end

end

SponsoredBenefits::Engine.routes.draw do

  resources :plan_design_proposals, only: [] do
    resources :plan_design_census_employees, controller: 'census_members/plan_design_census_employees' do
      collection do
        post :bulk_employee_upload
        post :expected_selection
      end
    end
  end

  namespace :organizations do

    resources :broker_agency_profiles, only: :employers do
      get :employers, on: :member
    end

    resources :plan_design_organizations do
      resources :plan_design_proposals do
        resources :contributions, controller: 'plan_design_proposals/contributions', only: [:index]
      end
      resources :carriers, controller: 'plan_design_proposals/carriers', only: [:index]
      resources :plans, controller: 'plan_design_proposals/plans', only: [:index]
    end

    resources :plan_design_proposals, only: [:destroy, :create, :show] do
      resources :contributions, controller: 'plan_design_proposals/contributions', only: [:index]
      resources :plan_selections, controller: 'plan_design_proposals/plan_selections', only: [:new]
      resources :plan_reviews, controller: 'plan_design_proposals/plan_reviews', only: [:new]
      resources :proposal_copies, controller: 'plan_design_proposals/proposal_copies', only: [:create]
      resources :benefit_groups, controller: 'plan_design_proposals/benefit_groups', only: [:create]
      resources :plan_comparisons, controller: 'plan_design_proposals/plan_comparisons', only: [:new] do
        collection do
          get :export
        end
      end
      post :publish
      get :claim

    end

    resource :office_locations do
      member do
        get :new
      end
    end
  end
end

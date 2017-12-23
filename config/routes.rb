SponsoredBenefits::Engine.routes.draw do

  namespace :census_members do
    resources :plan_design_census_employees do 
      collection do
        post :bulk_employee_upload
      end
    end
  end

  namespace :organizations do
    resources :plan_design_organizations do
      get :employers
      member do
        get :new
        get :edit
      end
    end

    resource :office_locations do
      member do
        get :new
      end
    end
  end

  resources :plan_design_organizations, only: [] do
    resources :plan_design_proposals, controller: 'organizations/plan_design_proposals', only: [:index, :new, :create]
  end

  resources :plan_design_proposals, controller: 'organizations/plan_design_proposals', only: [:show, :edit, :destroy, :update]
end

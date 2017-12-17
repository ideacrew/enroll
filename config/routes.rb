SponsoredBenefits::Engine.routes.draw do

  namespace :sponsored_benefits do
    namespace :census_members do
      resources :plan_design_census_employees
    end
  end

  namespace :benefit_sponsorships do
    resources :plan_design_employer_profiles
  end

  resources :benefit_sponsorships, only: [] do
    resources :benefit_applications
  end
end

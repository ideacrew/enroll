SponsoredBenefits::Engine.routes.draw do
  namespace :benefit_sponsorships do
    resources :plan_design_employer_profiles
  end

  resources :benefit_sponsorships, only: [] do
    resources :benefit_applications
  end
end

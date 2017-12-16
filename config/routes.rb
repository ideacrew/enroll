SponsoredBenefits::Engine.routes.draw do
  namespace :benefit_sponsorships do
    resources :plan_design_employer_profiles
  end
end

Rails.application.routes.draw do
  mount SponsoredBenefits::Engine => "/sponsored_benefits"
  mount BenefitSponsors::Engine,      at: "/benefit_sponsors"
  devise_for :users
  root 'welcome#index'
end

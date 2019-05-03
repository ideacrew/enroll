Rails.application.routes.draw do
  mount SponsoredBenefits::Engine => "/sponsored_benefits"
  devise_for :users
  root 'welcome#index'
end

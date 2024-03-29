Rails.application.routes.draw do
  mount BenefitSponsors::Engine => "/benefit_sponsors"
  mount SponsoredBenefits::Engine,      at: "/sponsored_benefits"

  devise_for :users

  root "welcome#index"

  match 'broker_registration', to: redirect('benefit_sponsors/profiles/registrations/new?profile_type=broker_agency'), via: [:get]

  get "document/employees_template_download" => "documents#employees_template_download", as: :document_employees_template_download
  resources :documents, only: [:destroy] do
    get :product_sbc_download
    get :employer_attestation_document_download
  end

  namespace :employers do

    resources :employer_profiles do
      get 'export_census_employees'
      resources :census_employees, only: [:new, :create, :edit, :update, :show] do
      end
    end
  end
end

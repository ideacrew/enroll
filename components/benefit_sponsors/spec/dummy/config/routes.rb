Rails.application.routes.draw do
  mount BenefitSponsors::Engine => "/benefit_sponsors"
  mount SponsoredBenefits::Engine,      at: "/sponsored_benefits"

  devise_for :users

  root "welcome#index"
  get "document/employer_attestation_documents_download/:document_id" => "documents#employer_attestation_documents_download", as: :document_employer_attestation_documents_download
  get "document/employees_template_download" => "documents#employees_template_download", as: :document_employees_template_download
  get "document/product_sbc_download/:product_id" => "documents#product_sbc_download", as: :document_product_sbc_download

  match 'broker_registration', to: redirect('benefit_sponsors/profiles/registrations/new?profile_type=broker_agency'), via: [:get]

  namespace :employers do

    resources :employer_profiles do
      get 'export_census_employees'
      resources :census_employees, only: [:new, :create, :edit, :update, :show] do
      end
    end
  end
end

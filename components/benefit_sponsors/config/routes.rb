BenefitSponsors::Engine.routes.draw do
  namespace :broker_agencies do
    resources :broker_roles, only: [:create] do
      collection do
        get :new_broker
        get :new_staff_member
        get :new_broker_agency, as: 'broker_registration'
        get :search_broker_agency
      end
    end
  end

end

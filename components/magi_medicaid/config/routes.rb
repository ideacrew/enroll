# frozen_string_literal: true

MagiMedicaid::Engine.routes.draw do
  resources :applications do
    # get 'help_paying_coverage', on: :collection, action: 'help_paying_coverage', as: 'help_paying_coverage'
    get 'application_checklist', on: :member, action: 'application_checklist', as: 'application_checklist'
    get 'checklist_pdf', on: :collection, action: 'checklist_pdf', as: 'checklist_pdf'
  end
end

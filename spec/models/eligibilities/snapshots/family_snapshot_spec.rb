# frozen_string_literal: true

require 'rails_helper'
require 'models/eligibilities/eligibilities_shared_context'

RSpec.describe Eligibilities::Snapshots::FamilySnapshot,
               type: :model,
               dbclean: :after_each do
  include_context 'eligibilities'
  subject { described_class }

  context 'Given a Family with an ACA FAA Application' do
    before { create_faa_application }

    # it 'a Family and associated FAA Application should be present in the database' do
    #   expect(Family.all.size).to eq 1
    #   expect(FinancialAssistance::Application.all.size).to eq 1
    # end
  end
end

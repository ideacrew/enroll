# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'FaaReviewService' do
  include_examples 'submitted application with two active members and one applicant'

  describe 'service' do
    before do
      @service_instance = FinancialAssistance::Services::FaaReviewService.new(application.id)
    end

    context 'find' do
      it 'should return hash' do
        expect(@service_instance.send(:find).class).to eq Hash
      end
    end

    context 'attributes_to_form_params' do
      before do
        @serialized_application = @service_instance.send(:attributes_to_form_params, application)[:application]
      end

      it 'should match attribute values for application' do
        [:id, :is_requesting_voter_registration_application_in_mail, :years_to_renew, :parent_living_out_of_home_terms].each do |attribute|
          expect(@serialized_application[attribute]).to eq application.send(attribute)
        end
      end
    end
  end
end

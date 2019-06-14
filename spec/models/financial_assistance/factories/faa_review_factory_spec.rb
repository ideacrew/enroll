# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FinancialAssistance::Factories::FaaReviewFactory do
  include_examples 'submitted application with one member and one applicant'

  context 'factory' do
    subject do
      FinancialAssistance::Factories::FaaReviewFactory.new(application.id)
    end

    context '.initialize' do
      it 'should return application_id' do
        expect(subject.application_id).to eq application.id
      end
    end

    context 'for attr_accessors' do
      [:application_id, :application].each do |field|
        it "#{field} should have getter and setter methods" do
          subject.respond_to?(field) && subject.respond_to?("#{field}=")
        end
      end
    end

    context 'faa_application' do
      it { expect(subject.faa_application).to eq application }
    end
  end
end

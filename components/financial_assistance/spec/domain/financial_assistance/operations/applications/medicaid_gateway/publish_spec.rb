# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::FinancialAssistance::Operations::Applications::MedicaidGateway::Publish, dbclean: :after_each do
  context 'When connection is available' do
    before do
      @result = subject.call({test: "test"})
    end

    it 'should return success' do
      expect(@result).to be_success
    end
  end
end

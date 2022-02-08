# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::IvlNoticesNotifierJob, dbclean: :after_each do

  describe 'create ivl notice' do
    let(:person) { FactoryBot.create(:person, :with_consumer_role)}

    it 'performs the enrollment notice data appendment' do
      expect(Rails.logger).to receive(:error).at_least(:once)
      IvlNoticesNotifierJob.new.perform(person.id, 'fake')
    end
  end
end
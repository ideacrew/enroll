# frozen_string_literal: true

require 'rails_helper'
require 'sidekiq/testing'

describe CrmWorker, :dbclean => :after_each do
  describe "#perform" do
    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }

    before do
      EnrollRegistry[:crm_update_family_save].feature.stub(:is_enabled).and_return(true)
    end

    it "should perform CRM publishes asyncronously" do
      expect(CrmWorker.new.perform(family.id.to_s, family.class.to_s, :trigger_crm_family_update_publish).keys).to include(:family_members)
    end
  end
end

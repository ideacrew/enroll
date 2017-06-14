require 'rails_helper'

RSpec.shared_examples "updating carrier_specific_id attribute for Plan model" do |attributes|
  attributes.each do |attribute, value|
    it "should return #{value} from ##{attribute}" do
      expect(subject.send(attribute)).to eq(value)
    end
  end
end

RSpec.describe 'Migrating carrier specific super group Id', :type => :task do
  context "Invoking rake task" do
    before :all do
      Rake.application.rake_require "tasks/update_super_group_ids"
      Rake::Task.define_task(:environment)
    end
    before :context do
      invoke_task
    end

    context "it should update the carrier_specific_plan_id" do
      let(:plan) { FactoryGirl.create(:plan, hios_id: "88806MA0030001-01")}

      it "should update the carrier_specific_field_value" do
        expect(plan.carrier_special_plan_identifier).to eq "X226"
      end

      it "should not upate the carrier_specific_field_value" do
        expect(plan.carrier_special_plan_identifier).to be nil
      end
    end

    private

    def invoke_task
      Rake::Task["supergroup:update_plan_id"].invoke
    end
  end
end

require 'rails_helper'

RSpec.shared_examples "a service area reference" do |attributes|
  attributes.each do |attribute, value|
    it "should return #{value} from ##{attribute}" do
      expect(subject.send(attribute)).to eq(value)
    end
  end
end

RSpec.describe 'Service Area Task', :type => :task do

  context "service_area:update_service_area" do

    before :all do
      Rake.application.rake_require "tasks/migrations/load_service_area_data"
      Rake::Task.define_task(:environment)
    end

    before :context do
      invoke_task
    end

    imported_areas = ServiceAreaReference.all
    context "it creates ServiceArea elements correctly" do
      subject { imported_areas.first }
      it_should_behave_like "a service area reference", {
                                                  service_area_id: "MAS001",
                                                  service_area_name: "Service Area 1",
                                                  serves_entire_state: true,
                                                  county_name: nil,
                                                  serves_partial_county: nil,
                                                  service_area_zipcode: "",
                                                  partial_county_justification: nil
                                                }
    end

    context "for elements that serve partial state" do
      subject { imported_areas.second }
      it_should_behave_like "a service area reference", {
                                                  service_area_id: "MAS002",
                                                  service_area_name: "Service Area 2",
                                                  serves_entire_state: false,
                                                  county_name: "Barnstable - 25001",
                                                  serves_partial_county: false,
                                                  service_area_zipcode: "",
                                                  partial_county_justification: nil
                                                }
    end

    context "for elements that serve partial state and partial county" do
      subject { imported_areas.third }
      it_should_behave_like "a service area reference", {
                                                  service_area_id: "MAS002",
                                                  service_area_name: "Service Area 2",
                                                  serves_entire_state: false,
                                                  county_name: "Franklin - 25011",
                                                  serves_partial_county: true,
                                                  service_area_zipcode: "19020",
                                                  partial_county_justification: "XX"
                                                }
    end

    context "if it runs again it doesn't create duplicates or throw errors" do
      before do
        invoke_task
      end
      it "does not create any more elements" do
        expect(imported_areas.count).to eq(ServiceAreaReference.all.count)        
      end
    end

    private

    def invoke_task
      Rake::Task["load_service_reference:update_service_areas"].invoke
    end
  end
end

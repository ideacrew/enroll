require 'rails_helper'
require 'rake'
require 'roo'

RSpec.shared_examples "a service area reference" do |attributes|
  attributes.each do |attribute, value|
    it "should return #{value} from ##{attribute}" do
      expect(subject.send(attribute)).to eq(value)
    end
  end
end

RSpec.describe 'Service Area Task', :type => :task do

  context "service_area:update_service_area" do
    let(:file_path) { File.join(Rails.root,'lib', 'xls_templates', "ServiceArea_Example.xlsx") }

    before :all do
      Rake.application.rake_require "tasks/migrations/load_service_area_data"
      Rake::Task.define_task(:environment)
    end

    before :context do
      invoke_task
    end

    context "it creates ServiceArea elements correctly" do
      subject { ServiceReference.first }
      it_should_behave_like "a service area reference", { service_area_id: "MAS001",
                                                  service_area_name: "Service Area 1",
                                                  state: true,
                                                  county_name: nil,
                                                  partial_county: nil,
                                                  service_area_zipcode: "",
                                                  partial_county_justification: nil 
                                                }
    end

    private

    def invoke_task
      Rake::Task["load_service_reference:update_service_areas"].invoke
    end
  end
end
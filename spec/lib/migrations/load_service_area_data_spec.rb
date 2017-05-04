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
      Rake.application.rake_require 'tasks/migrations/load_service_area_data'
      Rake::Task.define_task(:environment)
      create(:rate_reference, county_name: 'Suffolk', zip_code: '10010')
    end

    before :context do
      invoke_task
    end

    imported_areas = ServiceAreaReference.all
    context "it creates ServiceArea elements correctly" do
      subject { imported_areas.first }
      it_should_behave_like "a service area reference", {
                                                  hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: true,
                                                  county_name: nil,
                                                  county_code: nil,
                                                  state_code: nil,
                                                  serves_partial_county: false,
                                                  service_area_zipcode: nil,
                                                  partial_county_justification: nil
                                                }
    end

    context "for elements that serve partial state but total county" do
      subject { imported_areas.second }
      it_should_behave_like "a service area reference", {
                                                  hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: false,
                                                  county_name: 'Suffolk',
                                                  county_code: '025',
                                                  state_code: '25',
                                                  serves_partial_county: false,
                                                  service_area_zipcode: '10010',
                                                  partial_county_justification: nil
                                                }
    end

    context "for elements that serve partial state and partial county" do
      subject { imported_areas.third }

      it_should_behave_like "a service area reference", {
                                                  hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: false,
                                                  county_name: 'Middlesex',
                                                  county_code: '017',
                                                  state_code: '25',
                                                  serves_partial_county: true,
                                                  service_area_zipcode: '01730',
                                                }
      it "assigns the partial county justification correctly" do
        expect(subject.partial_county_justification).to match(/Network adequacy for these products centers around the 4 hospitals that are in the network./)
      end
    end

    context "if it runs again it doesn't create duplicates or throw errors" do
      before do
        invoke_task
      end
      it "does not create any more elements" do
        expect(imported_areas.count).to eq(ServiceAreaReference.all.count)
      end
    end

    context "it created the correct number of zip code sub areas" do
      subject { ServiceAreaReference.where(county_name: "Middlesex", service_area_name: "BMC HealthNet Plan Select Network") }

      it "created many service areas for each imported zip code" do
        expect(subject.count).to eq 51
      end
    end

    private

    def invoke_task
      Rake.application.invoke_task("load_service_reference:update_service_areas[SHOP_SA_BMCHP.xlsx]")
    end
  end
end

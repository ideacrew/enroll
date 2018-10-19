require 'rails_helper'

RSpec.shared_examples "a carrier service area" do |attributes|
  attributes.each do |attribute, value|
    it "should return #{value} from ##{attribute}" do
      expect(subject.send(attribute)).to eq(value)
    end
  end
end

RSpec.describe 'Service Area Imports', :type => :task do

  before :all do

    issuer_profiles_file = File.join(Rails.root, "db/seedfiles/cca/issuer_profiles_seed.rb")
    load issuer_profiles_file
    load_cca_issuer_profiles_seed

    locations_file = File.join(Rails.root, "db/seedfiles/cca/locations_seed.rb")
    load locations_file
    load_cca_locations_county_zips_seed

    Rake.application.rake_require 'tasks/migrations/plans/load_service_area_data'
    Rake::Task.define_task(:environment)
    create(:rating_area, county_name: 'Suffolk', zip_code: '10010')
    invoke_service_area_task
  end

  context "service_area:update_service_area" do

    let!(:imported_areas) { CarrierServiceArea.all }    

    context "it creates ServiceArea elements correctly" do
      subject { imported_areas.where(:serves_entire_state => true).first }

      it_should_behave_like "a carrier service area", {
                                                  active_year: '2017',
                                                  issuer_hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: true,
                                                  county_name: nil,
                                                  county_code: nil,
                                                  state_code: nil,
                                                  service_area_zipcode: nil,
                                                  partial_county_justification: nil
                                                }
    end

    context "for elements that serve partial state but total county" do
      subject { imported_areas.where(:county_name => 'Suffolk', :county_code => '025', :state_code => '25', :service_area_zipcode => '10010', :service_area_id => "MAS001").first }
      it_should_behave_like "a carrier service area", {
                                                  active_year: '2017',
                                                  issuer_hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: false,
                                                  county_name: 'Suffolk',
                                                  county_code: '025',
                                                  state_code: '25',
                                                  service_area_zipcode: '10010',
                                                  partial_county_justification: nil
                                                }
    end

    context "for elements that serve partial state and partial county" do
      subject { imported_areas.where(:county_name => 'Middlesex', :county_code => "017", :state_code => '25', :service_area_zipcode => "01730").first}

      it_should_behave_like "a carrier service area", {
                                                  active_year: '2017',
                                                  issuer_hios_id: '82569',
                                                  service_area_id: 'MAS001',
                                                  service_area_name: 'BMC HealthNet Plan Select Network',
                                                  serves_entire_state: false,
                                                  county_name: 'Middlesex',
                                                  county_code: '017',
                                                  state_code: '25',
                                                  service_area_zipcode: '01730',
                                                }
      it "assigns the partial county justification correctly" do
        expect(subject.partial_county_justification).to match(/Network adequacy for these products centers around the 4 hospitals that are in the network./)
      end
    end

    context "it created the correct number of zip code sub areas" do
      subject { CarrierServiceArea.where(county_name: "Middlesex", service_area_name: "BMC HealthNet Plan Select Network") }

      it "created many service areas for each imported zip code" do
        expect(subject.count).to eq 51
      end
    end
  end

  context "service_area:update_service_areas_new_model" do

    let!(:imported_areas) { BenefitMarkets::Locations::ServiceArea.all }

    context "it creates ServiceArea elements correctly, for the elements that server entire state" do
      subject { imported_areas.where(:covered_states => "MA").first }

      it_should_behave_like "a carrier service area", {
                                                        active_year: 2017,
                                                        issuer_provided_title: 'BMC HealthNet Plan Select Network',
                                                        covered_states: ["MA"],
                                                        county_zip_ids: nil,
                                                        issuer_provided_code: "MAS001",
                                                      }
    end

    context "for elements that serve partial state but total county" do
      let!(:county_zip) {BenefitMarkets::Locations::CountyZip.all.where(county_name: "Franklin", zip: "01093", state: "MA")}
      subject { imported_areas.where(:county_zip_ids.in => [county_zip.first.id]).first }
      it_should_behave_like "a carrier service area", {
                                                        active_year: 2017,
                                                        issuer_provided_title: 'BMC HealthNet Plan Silver Network',
                                                        issuer_provided_code: 'MAS002'
                                                      }
    end

    context "it created the correct number of service areas" do
      it "created many service areas for each imported zip code" do
        expect( imported_areas.count ).to eq 2
      end
    end
  end

  after :all do
    DatabaseCleaner.clean
  end
end

private

def invoke_service_area_task
  file = "#{Rails.root}/spec/test_data/plan_data/service_areas/2017/SHOP_SA_BMCHP.xlsx"
  Rake.application.invoke_task("load_service_reference:update_service_areas[#{file}]")
  Rake.application.invoke_task("load_service_reference:update_service_areas_new_model[#{file}]")
end

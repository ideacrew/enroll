require 'rails_helper'

RSpec.describe EmployerProfile, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"

  it { should validate_presence_of :entity_kind }

  let(:organization) {FactoryGirl.create(:organization)}
  let(:entity_kind) {"partnership"}
  let(:bad_entity_kind) {"fraternity"}

  let(:entity_kind_error_message) {"#{bad_entity_kind} is not a valid business entity kind"}


  describe ".new" do
    let(:valid_params) do
      {
        organization: organization,
        entity_kind: entity_kind
      }
    end

    context "with no arguments" do
      let(:params) {{}}
      it "should not save" do
        expect(EmployerProfile.new(**params).save).to be_false
      end
    end

    context "with all valid arguments" do
      let(:params) {valid_params}
      let(:employer_profile) {EmployerProfile.new(**params)}

      it "should save" do
        expect(employer_profile.save).to be_true
      end

      context "and it is saved" do
        before do
          employer_profile.save
        end

        it "should be findable" do
          expect(EmployerProfile.find(employer_profile.id).id.to_s).to eq employer_profile.id.to_s
        end
      end
    end

    context "with no entity_kind" do
      let(:params) {valid_params.except(:entity_kind)}

      it "should fail validation " do
        expect(EmployerProfile.create(**params).errors[:entity_kind].any?).to be_true
      end
    end

    context "with improper entity_kind" do
      let(:params) {valid_params.deep_merge({entity_kind: bad_entity_kind})}
      it "should fail validation with improper entity_kind" do
        expect(EmployerProfile.create(**params).errors[:entity_kind].any?).to be_true
        expect(EmployerProfile.create(**params).errors[:entity_kind]).to eq [entity_kind_error_message]

      end
    end

  end
end

describe EmployerProfile, "Class methods", type: :model do

  let(:ee0) {FactoryGirl.build(:employer_census_employee, ssn: "369851245")}
  let(:ee1) {FactoryGirl.build(:employer_census_employee, ssn: "258741239")}

  let(:family0) {FactoryGirl.build(:employer_census_family, census_employee: ee0)}
  let(:family1) {FactoryGirl.build(:employer_census_family, census_employee: ee1)}

  let(:er0) {EmployerProfile.new(entity_kind: "partnership", employee_families: [family0])}
  let(:er1) {EmployerProfile.new(entity_kind: "partnership", employee_families: [family0, family1])}
  let(:er2) {EmployerProfile.new(entity_kind: "partnership", employee_families: [family1])}

  let(:home_office) {FactoryGirl.build(:office_location)}

  let(:organization0) {er0.create_organization(legal_name: "huey",  fein: "687654321", office_locations: [home_office])}
  let(:organization1) {er1.create_organization(legal_name: "dewey", fein: "587654321", office_locations: [home_office])}
  let(:organization2) {er2.create_organization(legal_name: "louie", fein: "487654321", office_locations: [home_office])}
  before { organization0; organization1; organization2 }


  describe ".all" do
    it "should return an array of all employer_profiles" do
      expect(EmployerProfile.all.first).to be_a EmployerProfile
      expect(EmployerProfile.all.size).to eq 3
    end
  end

  describe ".find_census_families_by_person" do
    context "with person not matching ssn" do
      let(:params) do
        {  ssn:        "019283746",
           first_name: ee0.first_name,
           last_name:  ee0.last_name
        }
      end
      let(:p0) {Person.new(**params)}

      it "should return an empty array" do
        expect(EmployerProfile.find_census_families_by_person(p0)).to eq []
      end
    end

    context "with person matching ssn" do
      let(:params) do
        {  ssn:        ee0.ssn,
           first_name: ee0.first_name,
           last_name:  ee0.last_name
        }
      end
      let(:p0) {Person.new(**params)}

      it "should return an instance of EmployerFamily" do
        # expect(organization0.save).errors.messages).to eq ""
        expect(EmployerProfile.find_census_families_by_person(p0).first).to be_a EmployerCensus::EmployeeFamily
      end

      it "should return employee_families where employee matches person" do
        expect(EmployerProfile.find_census_families_by_person(p0).size).to eq 2
      end

      it "returns employee_families where employee matches person" do
        expect(EmployerProfile.find_census_families_by_person(p0).first.census_employee.dob).to eq family0.census_employee.dob
      end
    end

  end

  describe '.find_by_broker_agency_profile' do
    let(:organization6)  {FactoryGirl.create(:organization, fein: "024897585")}
    let(:broker_agency_profile)  {organization6.create_broker_agency_profile(market_kind: "both", primary_broker_role_id: "8754985")}

    let(:organization3)  {FactoryGirl.create(:organization, fein: "034267123")}
    let(:organization4)  {FactoryGirl.create(:organization, fein: "027636010")}
    let(:organization5)  {FactoryGirl.create(:organization, fein: "076747654")}

    let(:er3) {organization3.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile)}
    let(:er4) {organization4.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile)}
    let(:er5) {organization5.create_employer_profile(entity_kind: "partnership")}
    before { broker_agency_profile; er3; er4; er5 }

    it 'returns employers represented by the specified broker agency' do
      expect(er3.broker_agency_profile_id).to eq broker_agency_profile.id
      expect(er4.broker_agency_profile_id).to eq broker_agency_profile.id
      expect(er5.broker_agency_profile_id).to be_nil

      employers_with_broker = EmployerProfile.find_by_broker_agency_profile(broker_agency_profile)
      expect(employers_with_broker.first).to be_a EmployerProfile
      expect(employers_with_broker.size).to eq 2
    end
  end
end

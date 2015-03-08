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

  let(:family0) {FactoryGirl.build(:employer_census_family, census_employee: ee0, employer_profile: nil)}
  let(:family1) {FactoryGirl.build(:employer_census_family, census_employee: ee1, employer_profile: nil)}

  let(:er0) {EmployerProfile.new(entity_kind: "partnership", employee_families: [family0])}
  let(:er1) {EmployerProfile.new(entity_kind: "partnership", employee_families: [family0, family1])}
  let(:er2) {EmployerProfile.new(entity_kind: "partnership", employee_families: [family1])}

  let(:home_office) {FactoryGirl.build(:office_location)}

  let(:organization0) {er0.create_organization(legal_name: "huey",  fein: "687654321", office_locations: [home_office])}
  let(:organization1) {er1.create_organization(legal_name: "dewey", fein: "587654321", office_locations: [home_office])}
  let(:organization2) {er2.create_organization(legal_name: "louie", fein: "487654321", office_locations: [home_office])}
  before { organization0; organization1; organization2 }


  describe ".all" do
    it "should return an array of with employer_profiles in it" do
      expect(EmployerProfile.all.first).to be_a EmployerProfile
    end

    it "should return the right number of employer_profiles" do
      expect(EmployerProfile.all.size).to eq 3
    end
  end

  describe ".find_by_fein" do
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

  describe ".find_by_writing_agent" do
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

  describe ".find_employer_profiles_by_person" do
    let(:valid_ssn) {ee0.ssn}
    let(:invalid_ssn) {"000000000"}
    let(:params) do
      {  
        first_name: ee0.first_name,
        last_name:  ee0.last_name,
        dob:        ee0.dob
      }
    end

    context "finds an EmployerProfile employee" do
      let(:valid_person) {Person.new(**params, ssn: valid_ssn)}

      it "should find the active employee in multiple employer_profiles" do
        # expect(valid_person.ssn).to eq valid_ssn
        expect(EmployerProfile.find_employer_profiles_by_person(valid_person).size).to eq 2
      end

      it "should return EmployerProfile" do
        expect(EmployerProfile.find_employer_profiles_by_person(valid_person).first).to be_a EmployerProfile
      end

      it "should include the matching employee" do
        expect(EmployerProfile.find_employer_profiles_by_person(valid_person).last).to eq ee0.employee_family.employer_profile
      end
    end

    context "fails to match an employee" do
      let(:invalid_person) {Person.new(**params, ssn: invalid_ssn)}

      it "should not return any matches" do
        # expect(invalid_person.ssn).to eq invalid_ssn
        expect(EmployerProfile.find_employer_profiles_by_person(invalid_person).size).to eq 0
      end
    end
  end

  describe ".match_census_employees" do
  end
end

describe EmployerProfile, "instance methods" do
  let (:census_employee) {FactoryGirl.build(:employer_census_employee, ssn: "069851240")}
  let (:census_family) {FactoryGirl.build(:employer_census_family, census_employee: census_employee, employer_profile: nil)}  
  let (:person) {Person.new(first_name: census_employee.first_name, last_name: census_employee.last_name, ssn: census_employee.ssn)}

  describe "#linkable_employee_family_by_person" do
    let (:employer_profile) {FactoryGirl.create(:employer_profile)}

    context "with no census_family employees matching SSN" do
      it "should return nil" do
        expect(employer_profile.linkable_employee_family_by_person(person)).to be_nil
      end
    end

    context "with matching census_family employee" do
      let (:employer_profile) {FactoryGirl.create(:employer_profile, employee_families: [census_family])}

      it "should return the matching census_family" do
        expect(employer_profile.linkable_employee_family_by_person(person)).to be_a EmployerCensus::EmployeeFamily
        expect(employer_profile.linkable_employee_family_by_person(person)).to eq census_family
      end

      context "with employee previously terminated" do
        let (:prior_census_employee) {FactoryGirl.build(:employer_census_employee, ssn: "069851240", terminated_on: Date.today )}
        let (:prior_census_family) {FactoryGirl.build(:employer_census_family, census_employee: prior_census_employee, linked_at: Date.today - 1,terminated: true, employer_profile: nil)}  
        let (:employer_profile) {FactoryGirl.create(:employer_profile, employee_families: [prior_census_family, census_family])}

        it "should return only the matching census family" do
          expect(employer_profile.linkable_employee_family_by_person(person)).to eq census_family
        end

        context "with employee who was never linked" do
          let (:prior_census_employee) {FactoryGirl.build(:employer_census_employee, ssn: "069851240", terminated_on: Date.today )}
          let (:prior_census_family) {FactoryGirl.build(:employer_census_family, census_employee: prior_census_employee, terminated: true, employer_profile: nil)}  
          let (:employer_profile) {FactoryGirl.create(:employer_profile, employee_families: [prior_census_family, census_family])}

          it "should return only the matching census family" do
            expect(employer_profile.linkable_employee_family_by_person(person)).to eq census_family
          end
        end
      end
    end

  end

end

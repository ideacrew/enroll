require 'rails_helper'

describe Employer, type: :model do
  it { should validate_presence_of :legal_name }
  it { should validate_presence_of :fein }
  it { should validate_presence_of :entity_kind }
  
  let(:legal_name) {"ACME Widgets, Inc"}
  let(:dba) {"Widgetworks"}
  let(:fein) {"034267123"}
  let(:kind) {"tax_exempt_organization"}
  
  let(:kind_error_message) {"test entity_kind is not a valid business entity"}
  let(:fein_error_message) {"123123 is not a valid FEIN"}
  
  
  describe ".new" do
    let(:valid_params) do
      {  legal_name: legal_name,
         fein: fein,
         entity_kind: kind
      }
    end
    
    context "with no arguments" do
      let(:params) {{}}
      it "should not save" do
        expect(Employer.new(**params).save).to be_false
      end
    end
    
    context "with all valid arguments" do
      let(:params) {valid_params}
      it "should save" do
        expect(Employer.new(**params).save).to be_true
      end
    end
    
    context "with no legal_name" do
      let(:params) {valid_params.except(:legal_name)}

      it "should fail validation " do
        expect(Employer.create(**params).errors[:legal_name].any?).to be_true
      end
    end
    
    context "with no fein" do
      let(:params) {valid_params.except(:fein)}

      it "should fail validation " do
        expect(Employer.create(**params).errors[:fein].any?).to be_true
      end
    end
    
    context "with no entity_kind" do
      let(:params) {valid_params.except(:entity_kind)}

      it "should fail validation " do
        expect(Employer.create(**params).errors[:entity_kind].any?).to be_true
      end
    end
    
    context "with improper entity_kind" do
      let(:params) {valid_params.deep_merge({entity_kind: "test entity_kind"})}
      it "should fail validation with improper entity_kind" do
        expect(Employer.create(**params).errors[:entity_kind].any?).to be_true
        expect(Employer.create(**params).errors[:entity_kind]).to eq [kind_error_message]
        
      end
    end
    
    context "with improper fein" do
      let(:params) {valid_params.deep_merge({fein: "123123"})}
      it "should fail validation with improper fein" do
        expect(Employer.create(**params).errors[:fein].any?).to be_true
        expect(Employer.create(**params).errors[:fein]).to eq [fein_error_message]
        
      end
    end
  end
end

describe Employer, "Class methods", type: :model do

  broker_agency = FactoryGirl.create(:broker_agency)

  employer_one = Employer.new(
      legal_name: "ACME Widgets",
      fein: "034267123",
      entity_kind: "s_corporation",
      broker_agency: broker_agency
    )

  employer_two = Employer.new(
      legal_name: "Megacorp, Inc",
      fein: "427636010",
      entity_kind: "c_corporation",
      broker_agency: broker_agency
    )

  employer_without_broker = Employer.new(
      legal_name: "Tiny Services",
      fein: "576747654",
      entity_kind: "partnership"
    )

  describe ".find_employee_families_by_person" do

    ee0 = FactoryGirl.build(:employer_census_employee, ssn: "369851245")
    ee1 = FactoryGirl.build(:employer_census_employee, ssn: "258741239")

    ef0 = FactoryGirl.build(:employer_census_employee_family, employee: ee0)
    ef1 = FactoryGirl.build(:employer_census_employee_family, employee: ee1)

    er0 = FactoryGirl.create(:employer, fein: "687654321", employee_families: [ef0])
    er1 = FactoryGirl.create(:employer, fein: "587654321", employee_families: [ef0, ef1])
    er2 = FactoryGirl.create(:employer, fein: "487654321", employee_families: [ef1])

    let(:valid_params) do
      {  ssn:        ee0.ssn,
         first_name: ee0.first_name,
         last_name:  ee0.last_name
      }
    end

    context "with person not matching ssn" do
      let(:params) {valid_params}
      let(:p0) {Person.new(**params)}

      it "should return an empty array" do
        expect(Employer.find_employee_families_by_person(p0)).to be_a Array
        expect(Employer.find_employee_families_by_person(p0).size).to eq 0
      end
    end

    context "with person matching ssn" do
      let(:params) {valid_params}
      let(:p0) {Person.new(**params)}

      it "should return an instance of EmployerFamily" do
        # expect(er0.employee_families.first.employee.inspect).to eq true
        expect(Employer.find_employee_families_by_person(p0).first).to be_a EmployerCensus::EmployeeFamily
      end

      it "should return employee_families where employee matches person" do
        expect(Employer.find_employee_families_by_person(p0).size).to eq 2
      end

      it "returns employee_families where employee matches person" do
        expect(Employer.find_employee_families_by_person(p0).first.employee.dob).to eq ef0.employee.employee.dob
      end
    end

  end
      
  describe '.find_by_broker_agency' do

    it 'returns employers represented by the specified broker agency' do

      expect(employer_one.broker_agency_id).to eq broker_agency.id
      expect(employer_two.broker_agency_id).to eq broker_agency.id

      expect(employer_one.errors.messages.size).to eq 0
      expect(employer_one.save).to eq true
      expect(employer_two.save).to eq true
      expect(employer_without_broker.save).to eq true

      expect(Employer.all.size).to eq 3

      employers_with_broker_agency = Employer.find_by_broker_agency(broker_agency)
      expect(employers_with_broker_agency.size).to eq 2
    end
  end
end

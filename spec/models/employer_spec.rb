require 'rails_helper'

describe Employer, type: :model do
  context ".new" do
    let(:legal_name) {"ACME Widgets, Inc"}
    let(:dba) {"Widgetworks"}
    let(:fein) {"034267123"}
    let(:kind) {"tax_exempt_organization"}

    let(:employer) {Employer.new(legal_name: legal_name, dba: dba, fein: fein, entity_kind: kind)}

    it { should validate_presence_of :legal_name }
    it { should validate_presence_of :fein }
    it { should validate_presence_of :entity_kind }

    it('.name'){ expect(employer.legal_name).to eq legal_name }
    it('.dba'){ expect(employer.dba).to eq dba }
    it('.fein'){ expect(employer.fein).to eq fein }
    it('.entity_kind'){ expect(employer.entity_kind).to eq kind }
    it('should be valid'){ expect(employer.valid?).to eq true }

    context ".save" do
      let(:saved?) {employer.save}

      it { expect(saved?).to eq true }
    end
  end
end

# Class methods
describe Employer, '.find_by_broker_agency', :type => :model do
  it 'returns employers represented by the specified broker agency' do
    # id = BSON::ObjectId.from_time(Time.now)
    # broker_agency = instance_double("BrokerAgency", _id: id)

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

require 'rails_helper'

describe EmployeeRole, type: :model do
  it { should delegate_method(:hbx_id).to :person }
  it { should delegate_method(:ssn).to :person }
  it { should delegate_method(:dob).to :person }
  it { should delegate_method(:gender).to :person }

  it { should validate_presence_of :ssn }
  it { should validate_presence_of :dob }
  it { should validate_presence_of :gender }
  it { should validate_presence_of :employer_profile_id }
  it { should validate_presence_of :hired_on }

  let(:ssn) {"987654321"}
  let(:dob) { 36.years.ago.to_date }
  let(:gender) {"female"}
  let(:hired_on) { 10.days.ago.to_date }

  describe "built" do
    let(:address) {FactoryGirl.build(:address)}
    let(:saved_person) {FactoryGirl.create(:person, first_name: "Annie", last_name: "Lennox", addresses: [address])}
    let(:new_person) {FactoryGirl.build(:person, first_name: "Carly", last_name: "Simon")}
    let(:employer_profile) {FactoryGirl.create(:employer_profile)}

    let(:valid_person_attributes) do
      {
        ssn: ssn,
        dob: dob,
        gender: gender,
      }
    end

    let(:valid_params) do
      {
        person_attributes: valid_person_attributes,
        employer_profile: employer_profile,
        hired_on: hired_on,
      }
    end

    context "with valid parameters" do
      let(:employee_role) {saved_person.employee_roles.build(valid_params)}

      # %w[employer_profile ssn dob gender hired_on].each do |m|
      %w[ssn dob gender hired_on].each do |m|
        it "should have the right #{m}" do
          expect(employee_role.send(m)).to eq send(m)
        end
      end

      it "should save" do
        expect(employee_role.save).to be_true
      end

      context "and it is saved" do
        before do
          employee_role.save
        end

        it "should be findable" do
          expect(EmployeeRole.find(employee_role.id).id.to_s).to eq employee_role.id.to_s
        end
      end
    end

    context "with no employer_profile" do
      let(:params) {valid_params.except(:employer_profile)}
      let(:employee_role) {saved_person.employee_roles.build(params)}
      before() {employee_role.valid?}

      it "should not be valid" do
        expect(employee_role.valid?).to be false
      end

      it "should have an error on employer_profile_id" do
        expect(employee_role.errors[:employer_profile_id].any?).to be true
      end
    end

    context "with no hired_on" do
      let(:params) {valid_params.except(:hired_on)}
      let(:employee_role) {saved_person.employee_roles.build(params)}
      before() {employee_role.valid?}

      it "should not be valid" do
        expect(employee_role.valid?).to be false
      end

      it "should have an error on hired_on" do
        expect(employee_role.errors[:hired_on].any?).to be true
      end
    end

    context "with no ssn" do
      let(:person_params) {valid_person_attributes.except(:ssn)}
      let(:params) {valid_params.merge(person_attributes: person_params)}
      let(:employee_role) {saved_person.employee_roles.build(params)}
      before() {employee_role.valid?}

      it "should not be valid" do
        expect(employee_role.valid?).to be false
      end

      it "should have an error on ssn" do
        expect(employee_role.errors[:ssn].any?).to be true
      end
    end

    context "with no gender" do
      let(:person_params) {valid_person_attributes.except(:gender)}
      let(:params) {valid_params.merge(person_attributes: person_params)}
      let(:employee_role) {saved_person.employee_roles.build(params)}
      before() {employee_role.valid?}

      it "should not be valid" do
        expect(employee_role.valid?).to be false
      end

      it "should have an error on gender" do
        expect(employee_role.errors[:gender].any?).to be true
      end
    end

    context "with no dob" do
      let(:employee_role) do
        FactoryGirl.build(:employee_role, dob: nil)
      end
      before() {employee_role.valid?}

      it "should not be valid" do
        expect(employee_role.valid?).to be false
      end

      it "should have an error on dob" do
        expect(employee_role.errors[:dob].any?).to be true
      end
    end
  end

  it 'properly intantiates the class using an existing person' do
    pending "replace with pattern"
    ssn = "987654321"
    date_of_hire = Date.today - 10.days
    dob = Date.today - 36.years
    gender = "female"

    employer_profile = EmployerProfile.create(
        legal_name: "ACME Widgets, Inc.",
        fein: "098765432",
        entity_kind: :c_corporation
      )

    person = Person.create(
        first_name: "annie",
        last_name: "lennox",
        addresses: [Address.new(
            kind: "home",
            address_1: "441 4th St, NW",
            city: "Washington",
            state: "DC",
            zip: "20001"
          )
        ]
      )

    employee_role = person.build_employee
    employee_role.ssn = ssn
    employee_role.dob = dob
    employee_role.gender = gender
    employee_role.employers << employer_profile._id
    employee_role.date_of_hire = date_of_hire
    expect(employee_role.touch).to eq true

    # Verify local getter methods
    expect(employee_role.employers.first).to eq employer_profile._id
    expect(employee_role.date_of_hire).to eq date_of_hire

    # Verify delegate local attribute values
    expect(employee_role.ssn).to eq ssn
    expect(employee_role.dob).to eq dob
    expect(employee_role.gender).to eq gender

    # Verify delegated attribute values
    expect(person.ssn).to eq ssn
    expect(person.dob).to eq dob
    expect(person.gender).to eq gender

    expect(employee_role.errors.messages.size).to eq 0
    expect(employee_role.save).to eq true
  end

  it 'properly intantiates the class using a new person' do
    pending "replace with pattern"
    ssn = "987654320"
    date_of_hire = Date.today - 10.days
    dob = Date.today - 26.years
    gender = "female"

    employer_profile = employer_profile.create(
        legal_name: "Ace Ventures, Ltd.",
        fein: "098765437",
        entity_kind: "s_corporation"
      )

    person = Person.new(first_name: "carly", last_name: "simon")

    employee_role = person.build_employee
    employee_role.ssn = ssn
    employee_role.dob = dob
    employee_role.gender = gender
    # employee_role.employer_profile << employer_profile
    employee_role.date_of_hire = date_of_hire

    # Verify local getter methods
    # expect(employee_role.employers.first).to eq employer_.id
    expect(employee_role.date_of_hire).to eq date_of_hire

    # Verify delegate local attribute values
    expect(employee_role.ssn).to eq ssn
    expect(employee_role.dob).to eq dob
    expect(employee_role.gender).to eq gender

    # Verify delegated attribute values
    expect(person.ssn).to eq ssn
    expect(person.dob).to eq dob
    expect(person.gender).to eq gender

    expect(person.errors.messages.size).to eq 0
    expect(person.save).to eq true

    expect(employee_role.touch).to eq true
    expect(employee_role.errors.messages.size).to eq 0
    expect(employee_role.save).to eq true
  end
  # it "updates instance timestamps" do
  #   er = FactoryGirl.build(:employer_profile)
  #   ee = FactoryGirl.build(:employee_role)
  #   pn = Person.create(first_name: "Ginger", last_name: "Baker")
  #   # ee = Employee_role.new(ssn: "345907654", dob: Date.today - 40.years, gender: "male", employer_profile: er, date_of_hire: Date.today)
  #   ee = FactoryGirl.build(:employee_role)
  #   pn.employees << ee
  #   pn.valid?
  #   expect(ee.errors.messages.inspect).to eq 0
  #   expect(pn.save).to eq true
  #   expect(ee.created_at).to eq ee.updated_at
  #   employee_role.date_of_termination = Date.today
  #   expect(ee.save).to eq true
  #   expect(ee.created_at).not_to eq ee.updated_at
  # end
end

describe EmployeeRole, type: :model do
  let(:person_created_at) { 10.minutes.ago }
  let(:person_updated_at) { 8.minutes.ago }
  let(:employee_role_created_at) { 9.minutes.ago }
  let(:employee_role_updated_at) { 7.minutes.ago }
  let(:ssn) { "019283746" }
  let(:dob) { 45.years.ago.to_date }
  let(:hired_on) { 2.years.ago.to_date }
  let(:gender) { "male" }

  context "when created" do
    let(:employer_profile) { FactoryGirl.create(:employer_profile) }

    let(:person) {
      FactoryGirl.create(:person,
        created_at: person_created_at,
        updated_at: person_updated_at
      )
    }

    let(:employee_role) {
      person.employee_roles.create(
        employer_profile: employer_profile,
        hired_on: hired_on,
        created_at: employee_role_created_at,
        updated_at: employee_role_updated_at,
        person_attributes: {
          ssn: ssn,
          dob: dob,
          gender: gender,
        }
      )
    }

    it "parent created_at should be right" do
      expect(person.created_at).to eq person_created_at
    end

    it "parent updated_at should be right" do
      expect(person.updated_at).to eq person_updated_at
    end

    it "created_at should be right" do
      expect(employee_role.created_at).to eq employee_role_created_at
    end

    it "updated_at should be right" do
      expect(employee_role.updated_at).to eq employee_role_updated_at
    end

    context "then parent updated" do
      let(:middle_name) { "Albert" }
      before do
        person.middle_name = middle_name
        person.save
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should not have changed" do
        expect(employee_role.updated_at).to eq employee_role_updated_at
      end
    end

    context "then parent touched" do
      before do
        person.touch
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should not have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should not have changed" do
        expect(employee_role.updated_at).to eq employee_role_updated_at
      end
    end

    context "then a nested parent attribute is updated" do
      before do
        employee_role.ssn = "647382910"
        employee_role.save
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should not have changed" do
        expect(employee_role.updated_at).to eq employee_role_updated_at
      end
    end

    context "then updated" do
      let(:new_hired_on) { 10.days.ago.to_date }

      before do
        employee_role.hired_on = new_hired_on
        employee_role.save
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should have changed" do
        expect(employee_role.updated_at).to be > employee_role_updated_at
      end
    end

    context "then touched" do
      before do
        employee_role.touch
      end

      it "parent created_at should not have changed" do
        expect(person.created_at).to eq person_created_at
      end

      it "parent updated_at should have changed" do
        expect(person.updated_at).to be > person_updated_at
      end

      it "created_at should not have changed" do
        expect(employee_role.created_at).to eq employee_role_created_at
      end

      it "updated_at should have changed" do
        expect(employee_role.updated_at).to be > employee_role_updated_at
      end
    end
  end

  describe EmployeeRole, "Inbox", type: :model do

    def ssn; "988854321"; end
    let(:dob) { 27.years.ago.to_date }
    let(:hired_on) { 10.weeks.ago.to_date }
    let(:gender) { "male" }

    let(:address) {FactoryGirl.build(:address)}
    let(:person) {FactoryGirl.create(:person, addresses: [address])}
    let(:employer_profile) {FactoryGirl.create(:employer_profile)}
    let(:message_subject) { "Welcome to DC HealthLink" }
    let(:employee_role) { person.employee_roles.build(person_attributes: { ssn: ssn, dob: dob, gender: gender },
                                                      employer_profile: employer_profile, hired_on: hired_on) }

    context "when an employee_role is created"
      before { employee_role.save }

      it "should create an associated inbox" do
        expect(employee_role.inbox).to_not be_nil
      end

      it "should add a welcome message to the inbox" do
        expect(employee_role.inbox.messages.size).to eq 1
        expect(employee_role.inbox.messages.first.subject).to match /Welcome to DC HealthLink/ 
      end
  end

end

require 'rails_helper'

describe EmployeeRole do
  before :each do
    subject.valid?
  end

  [:hired_on, :dob, :gender, :ssn, :employer_profile_id].each do |property|
    it "should require #{property}" do
      expect(subject).to have_errors_on(property)
    end
  end

end

describe EmployeeRole, "given a person" do
  let(:hbx_id) { "555553443" }
  let(:ssn) { "012345678" }
  let(:dob) { Date.new(2009, 2, 5) }
  let(:gender) { "female" }

  let(:person) { Person.new(
    :hbx_id => hbx_id,
    :ssn => ssn,
    :dob => dob,
    :gender => gender
  )}
  subject { EmployeeRole.new(:person => person) }

  it "should have access to dob" do
    expect(subject.dob).to eq dob
  end

  it "should have access to gender" do
    expect(subject.gender).to eq gender
  end

  it "should have access to ssn" do
    expect(subject.ssn).to eq ssn
  end
  it "should have access to hbx_id" do
    expect(subject.hbx_id).to eq hbx_id
  end

end

describe EmployeeRole, dbclean: :after_each do
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
        expect(employee_role.save).to be_truthy
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
  end

  # FIXME: Replace with pattern
  it 'properly intantiates the class using an existing person' # do
=begin
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
=end

  # FIXME: Replace with pattern
  it 'properly intantiates the class using a new person'# do
=begin
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
=end
end

describe EmployeeRole, dbclean: :after_each do
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

  describe EmployeeRole, "Inbox", dbclean: :after_each do

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


  context "with saved employee roles from multiple employers" do
    let(:match_size)                  { 5 }
    let(:non_match_size)              { 3 }
    let(:match_employer_profile)      { FactoryGirl.create(:employer_profile) }
    let(:non_match_employer_profile)  { FactoryGirl.create(:employer_profile) }
    let!(:match_employee_roles)        { FactoryGirl.create_list(:employee_role, 5, employer_profile: match_employer_profile) }
    let!(:non_match_employee_roles)    { FactoryGirl.create_list(:employee_role, 3, employer_profile: non_match_employer_profile) }


    it "should find all employee roles" do
      expect(EmployeeRole.all.size).to eq (match_size + non_match_size)
      expect(EmployeeRole.all.first).to be_an_instance_of EmployeeRole
    end

    it "should find first employee role" do
      expect(EmployeeRole.first).to be_an_instance_of EmployeeRole
    end

    it "should find employee roles from the provided employer profile" do
      expect(EmployeeRole.find_by_employer_profile(match_employer_profile).size).to eq match_size
      expect(EmployeeRole.find_by_employer_profile(match_employer_profile).first).to be_an_instance_of EmployeeRole
    end
  end


end

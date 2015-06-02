require 'rails_helper'

describe EmployerProfile, dbclean: :after_each do

  let(:entity_kind)     { "partnership" }
  let(:bad_entity_kind) { "fraternity" }
  let(:entity_kind_error_message) { "#{bad_entity_kind} is not a valid business entity kind" }

  let(:address)  { Address.new(kind: "work", address_1: "609 H St", city: "Washington", state: "DC", zip: "20002") }
  let(:phone  )  { Phone.new(kind: "main", area_code: "202", number: "555-9999") }
  let(:email  )  { Email.new(kind: "work", address: "info@sailaway.org") }

  let(:office_location) { OfficeLocation.new(
        is_primary: true,
        address: address,
        phone: phone,
        email: email
      )
    }

  let(:organization) { Organization.create(
      legal_name: "Sail Adventures, Inc",
      dba: "Sail Away",
      fein: "001223333",
      office_locations: [office_location]
      ) 
    }

  let(:valid_params) do
    {
      organization: organization,
      entity_kind: entity_kind
    }
  end

  it { should validate_presence_of :entity_kind }

  context ".new" do
    context "with no arguments" do
      let(:params)  { {} }
      let(:employer_profile) {EmployerProfile.new(**params)}

      it "should initialize nested models" do
        expect(employer_profile.inbox).not_to be_nil
      end

      it "should not save" do
        expect(employer_profile.save).to be_falsey
      end
    end

    context "with no entity_kind" do
      def params; valid_params.except(:entity_kind); end

      it "should fail validation " do
        expect(EmployerProfile.create(**params).errors[:entity_kind].any?).to be_truthy
      end
    end

    context "with improper entity_kind" do
      def params; valid_params.deep_merge({entity_kind: bad_entity_kind}); end
      it "should fail validation with improper entity_kind" do
        expect(EmployerProfile.create(**params).errors[:entity_kind].any?).to be_truthy
        expect(EmployerProfile.create(**params).errors[:entity_kind]).to eq [entity_kind_error_message]
      end
    end

    context "with all valid arguments" do
      def params; valid_params; end
      def employer_profile; EmployerProfile.new(**params); end

      it "should initialize employer profile workflow state to applicant" do
        expect(employer_profile.applicant?).to be_truthy
      end

      it "should save" do
        expect(employer_profile.save).to be_truthy
      end

      context "and it is saved" do
        let!(:saved_employer_profile) do
          er = employer_profile
          er.save
          er
        end

        it "should save all nested models" do
          expect(saved_employer_profile.inbox?).to be_truthy
        end

        it "and should be findable" do
          expect(EmployerProfile.find(saved_employer_profile.id).id.to_s).to eq saved_employer_profile.id.to_s
        end
      end
    end
  end

  context "has registered and enters initial application process" do
    let(:benefit_group)     { FactoryGirl.build(:benefit_group)}
    let(:plan_year)         { FactoryGirl.build(:plan_year, benefit_groups: [benefit_group]) }
    let!(:employer_profile)  { EmployerProfile.new(**valid_params, plan_years: [plan_year]) }
    let(:min_non_owner_count )  { HbxProfile::ShopEnrollmentNonOwnerParticipationMinimum }

    it "should initialize in applicant status" do
      expect(employer_profile.applicant?).to be_truthy
    end

    context "and employer submits a valid plan year application with tomorrow as start open enrollment" do
      before do
        plan_year.open_enrollment_start_on = Date.current + 1
        plan_year.open_enrollment_end_on = Date.current + 5
        plan_year.start_on = (Date.current + 25).end_of_month + 1.day
        plan_year.end_on = plan_year.start_on + 1.year - 1.day
        # employer_profile.latest_plan_year.publish
        plan_year.publish
      end

      it "should transition to registered state" do
        expect(employer_profile.registered?).to be_truthy
      end
    end

    context "and employer submits a valid plan year application with today as start open enrollment" do
      before do
        plan_year.open_enrollment_start_on = Date.current
        plan_year.open_enrollment_end_on = Date.current + 5
        plan_year.start_on = (Date.current + 25).end_of_month + 1.day
        plan_year.end_on = plan_year.start_on + 1.year - 1.day
        # employer_profile.latest_plan_year.publish
        plan_year.publish
      end

      it "should transition directly to enrolling state" do
        expect(employer_profile.enrolling?).to be_truthy
      end

      context "and employer has enrolled" do

        context "and today is the day following close of open enrollment" do
          before do
            plan_year.open_enrollment_end_on = Date.current - 1
            plan_year.open_enrollment_start_on = plan_year.open_enrollment_end_on - 5
            plan_year.start_on = (Date.current + 32).end_of_month + 1.day
            plan_year.end_on = plan_year.start_on + 1.year - 1.day
          end

          context "and employer's enrollment is non-compliant" do

            context "because enrollment non-owner participation minimum not met" do
              let(:invalid_non_owner_count) { min_non_owner_count - 1 }
              let(:owner_census_family) { FactoryGirl.create(:census_family, census_roster: employer_profile.census_roster) }
              let(:non_owner_census_families) { FactoryGirl.create_list(:census_family, invalid_non_owner_count, census_roster: employer_profile.census_roster) }

              before do
                # owner_census_family.census_employee.is_owner = true

                # [owner_census_family].concat(non_owner_census_families).each do |cf|
                #   employee_role = FactoryGirl.create(:employee_role)
                #   cf.add_benefit_group_assignment(benefit_group)
                #   cf.link_employee_role(employee_role)

                  ## TODO Each census family needs to either enroll or waive coverage
                # end

                employer_profile.advance_enrollment_date
              end

              it "enrollment should be invalid" do
                # expect(employer_profile.census_roster.is_enrollment_valid?).to be_falsey
                # expect(employer_profile.census_roster.enrollment_errors[:non_owner_enrollment_count].present?).to be_truthy
                # expect(employer_profile.census_roster.enrollment_errors[:non_owner_enrollment_count]).to match(/non-owner employee must enroll/)
              end

              it "should advance state to canceled" do
                # expect(employer_profile.canceled?).to be_truthy                
              end
            end

            context "or the minimum enrollment ratio isn't met" do
              before do
              end

              pending
              context "and the effective date isn't January 1" do
                before do
                end

                pending                
                it "enrollment should be invalid" do
                #   expect(employer_profile.census_roster.is_enrollment_valid?).to be_falsey
                #   expect(employer_profile.census_roster.enrollment_errors[:enrollment_ratio].present?).to be_truthy
                #   expect(employer_profile.census_roster.enrollment_errors[:enrollment_ratio]).to match(/number of eligible participants enrolling/)
                end

                it "should advance state to canceled" do
                #   expect(employer_profile.canceled?).to be_truthy                
                end
              end

              context "and the effective date is January 1" do
                before do
                end

                it "enrollment should be valid" do
                #   expect(employer_profile.census_roster.is_enrollment_valid?).to be_truthy
                end

                it "should transition to binder pending" do
                #   expect(employer_profile.binder_pending?).to be_truthy
                end
              end
            end
          end

          context "and employer enrollment is compliant" do
            context "because the non-owner participation minimum is met" do
              before do
              end

              it "enrollment should be valid" do
              #   expect(employer_profile.census_roster.is_enrollment_valid?).to be_truthy
              end

              it "should transition to binder pending" do
              #   expect(employer_profile.binder_pending?).to be_truthy
              end
            end

            context "and the minimum enrollment ratio is met" do
              before do
              end

              it "enrollment should be valid" do
              #   expect(employer_profile.census_roster.is_enrollment_valid?).to be_truthy
              end

              it "should transition to binder pending" do
              #   expect(employer_profile.binder_pending?).to be_truthy
              end
            end

            it "should initialize a premium statement" do
              # expect(employer_profile.latest_premium_statement.effective_on).to eq Date.current
            end

            it "should be waiting for binder payment" do
              # expect(employer_profile.binder_pending?).to be_truthy
              # expect(employer_profile.latest_premium_statement.binder_pending?).to be_truthy
            end

            context "and employer doesn't post timely binder payment" do
              before do
                # employer_profile.latest_premium_statement.advance_billing_period
              end

              it "should advance state to canceled" do
                # expect(employer_profile.canceled?).to be_truthy                
              end
            end

            context "and employer pays binder premium on timely basis" do
              before do
                # employer_profile.latest_premium_statement.allocate_binder_payment
              end

              it "should transition employer to enrolled" do
                # expect(employer_profile.enrolled?).to be_truthy
              end
            end
          end
        end
      end
    end

    context "and today is the day following this month's deadline for start of open enrollment" do
      before do
        # employer_profile.advance_enrollment_period
      end

      context "and employer profile is in applicant state" do
        context "and effective date is next month" do
          it "should change status to canceled" do
          end
        end

        context "and effective date is later than next month" do
          pending
          it "should not change state" do
          end
        end
      end

      context "and employer is in ineligible or ineligible_appealing state" do
        pending "what should be done?"
      end
    end

    context "and enrolled employer enters Dunning process" do

      context "and employer transitions into late status" do
        it "should transmit notice to employer" do
        end

        it "should transmit notice to broker" do
        end

        it "should transmit notices to all employees" do
        end
      end

      context "and employer transitions into suspended status" do
        it "should transmit notice to employer" do
        end

        it "should transmit notice to broker" do
        end

        it "should transmit retroactive terminations to issuers" do
        end

        context "and employees are placed under a Special Enrollment Period" do
          it "should transmit notices to all employees" do
          end

          it "should create a IVL market QLE for all employees" do
          end

          it "SEP should be retroactive" do
          end
        end

        context "and employer pays in full" do
          pending "now what happens to SEP, etc?"
        end
      end

      context "and employer transitions to terminated status" do
        it "should transmit notice to employer" do
        end

        it "should transmit notice to broker" do
        end

        it "should transmit notices to all employees" do
        end
      end
    end
  end
end

describe EmployerProfile, "given multiple existing employer profiles", :dbclean => :after_all do
  before(:all) do
    home_office = FactoryGirl.build(:office_location)
    @er0 = EmployerProfile.new(entity_kind: "partnership")
    @er1 =  EmployerProfile.new(entity_kind: "partnership")
    @er2 = EmployerProfile.new(entity_kind: "partnership")
    @er0.create_organization(legal_name: "huey",  fein: "687654321", office_locations: [home_office])
    @er1.create_organization(legal_name: "dewey", fein: "587654321", office_locations: [home_office])
    @er2.create_organization(legal_name: "louie", fein: "487654321", office_locations: [home_office])
    @no_employer_org = Organization.create!(fein: "123456789", office_locations: [home_office], legal_name: "I AM NOT AN EMPLOYER")
  end


  it "should be able to find those profiles with the .all class method" do
    expect(EmployerProfile.all).to include(@er0)
    expect(EmployerProfile.all).to include(@er1)
    expect(EmployerProfile.all).to include(@er2)
  end

  it "should not return any organizations which do not have employers" do
    expect(EmployerProfile.all).not_to include(@no_employer_org)
  end
end

describe EmployerProfile, "given an unlinked, linkable census employee with a family" do
  let(:census_dob) { Date.new(1983,2,15) }
  let(:census_ssn) { "123456789" }

  let(:census_employee) { EmployerCensus::Employee.new(
    :ssn => census_ssn,
    :dob => census_dob
  ) }
  let(:census_family) { 
    fam = EmployerCensus::EmployeeFamily.new({ :census_employee => census_employee })
    allow(fam).to receive(:is_linkable?).and_return(true)
    fam
  }
  let(:employer_profile) { EmployerProfile.new(
    :employee_families => [census_family]
  )}

  it "should not find the linkable family when given a different ssn" do
    person = OpenStruct.new({
      :dob => census_dob,
      :ssn => "987654321"
    })
    expect(employer_profile.linkable_employee_family_by_person(person)).to eq nil
  end

  it "should not find the linkable family when given a different dob" do
    person = OpenStruct.new({
      :dob => Date.new(2012,1,1),
      :ssn => census_ssn
    })
    expect(employer_profile.linkable_employee_family_by_person(person)).to eq nil
  end

  it "should return the linkable employee when given the same dob and ssn" do
    person = OpenStruct.new({
      :dob => census_dob,
      :ssn => census_ssn
    })
    expect(employer_profile.linkable_employee_family_by_person(person)).to eq census_family
  end
end

describe EmployerProfile, "Class methods", dbclean: :after_each do
  def ee0; FactoryGirl.build(:employer_census_employee, ssn: "369851245", dob: 32.years.ago.to_date); end
  def ee1; FactoryGirl.build(:employer_census_employee, ssn: "258741239", dob: 42.years.ago.to_date); end

  def family0; FactoryGirl.build(:employer_census_family, census_employee: ee0, employer_profile: nil); end
  def family1; FactoryGirl.build(:employer_census_family, census_employee: ee1, employer_profile: nil); end

  def er0; EmployerProfile.new(entity_kind: "partnership", employee_families: [family0]); end
  def er1; EmployerProfile.new(entity_kind: "partnership", employee_families: [family0, family1]); end
  def er2; EmployerProfile.new(entity_kind: "partnership", employee_families: [family1]); end

  def home_office; FactoryGirl.build(:office_location); end

  def organization0; er0.create_organization(legal_name: "huey",  fein: "687654321", office_locations: [home_office]); end
  def organization1; er1.create_organization(legal_name: "dewey", fein: "587654321", office_locations: [home_office]); end
  def organization2; er2.create_organization(legal_name: "louie", fein: "487654321", office_locations: [home_office]); end
  before { organization0; organization1; organization2 }

  describe '.find_by_broker_agency_profile' do
    let(:organization6)  {FactoryGirl.create(:organization, fein: "024897585")}
    let(:broker_agency_profile)  {organization6.create_broker_agency_profile(market_kind: "both", primary_broker_role_id: "8754985")}

    let(:organization3)  {FactoryGirl.create(:organization, fein: "034267123")}
    let(:organization4)  {FactoryGirl.create(:organization, fein: "027636010")}
    let(:organization5)  {FactoryGirl.create(:organization, fein: "076747654")}

    def er3; organization3.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile); end
    def er4; organization4.create_employer_profile(entity_kind: "partnership", broker_agency_profile: broker_agency_profile); end
    def er5; organization5.create_employer_profile(entity_kind: "partnership"); end
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

  describe ".find_by_fein" do
    let(:employer_profile) { FactoryGirl.build(:employer_profile) }
    it "should return record for matching fein" do
      employer_profile.save
      expect(EmployerProfile.find_by_fein(employer_profile.organization.fein)).to be_an_instance_of EmployerProfile
    end
  end

  describe ".find_census_families_by_person" do
    context "with person not matching ssn" do
      let(:params) do
        {  ssn:        "019283746",
           first_name: ee0.first_name,
           last_name:  ee0.last_name,
           dob:        ee0.dob
        }
      end
      def p0; Person.new(**params); end

      it "should return an empty array" do
        expect(EmployerProfile.find_census_families_by_person(p0)).to eq []
      end
    end

    context "with person not matching dob" do
      let(:params) do
        {  ssn:        ee0.ssn,
           first_name: ee0.first_name,
           last_name:  ee0.last_name,
           dob:        (ee0.dob - 1.year).to_date
        }
      end
      def p0; Person.new(**params); end

      it "should return an empty array" do
        expect(EmployerProfile.find_census_families_by_person(p0)).to eq []
      end
    end

    context "with person matching ssn and dob" do
      let(:params) do
        {  ssn:        ee0.ssn,
           first_name: ee0.first_name,
           last_name:  ee0.last_name,
           dob:        ee0.dob
        }
      end
      def p0; Person.new(**params); end

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

  describe ".find_all_by_person" do
    let(:black_and_decker) do
      org = FactoryGirl.create(:organization, legal_name: "Black and Decker, Inc.", dba: "Black + Decker")
      er = org.create_employer_profile(entity_kind: "c_corporation")
    end
    let(:atari) do
      org = FactoryGirl.create(:organization, legal_name: "Atari Corporation", dba: "Atari Games")
      er = org.create_employer_profile(entity_kind: "s_corporation")
    end
    let(:google) do
      org = FactoryGirl.create(:organization, legal_name: "Google Inc.", dba: "Google")
      er = org.create_employer_profile(entity_kind: "partnership")
    end
    def bob_params; {first_name: "Uncle", last_name: "Bob", ssn: "999441111", dob: 35.years.ago.to_date}; end
    let!(:black_and_decker_bob) do
      fam = black_and_decker.employee_families.create()
      ee = FactoryGirl.create(:employer_census_employee, employee_family: fam, **bob_params)
    end
    let!(:atari_bob) do
      fam = atari.employee_families.create()
      ee = FactoryGirl.create(:employer_census_employee, employee_family: fam, **bob_params)
    end
    let!(:google_bob) do
      fam = google.employee_families.create()
      # different dob
      ee = FactoryGirl.create(:employer_census_employee, employee_family: fam, **bob_params.merge(dob: 40.years.ago.to_date))
    end

    def valid_ssn; ee0.ssn; end
    def invalid_ssn; "000000000"; end
    let(:params) do
      {
        first_name: ee0.first_name,
        last_name:  ee0.last_name,
        dob:        ee0.dob
      }
    end

    context "finds an EmployerProfile employee" do
      def valid_person; FactoryGirl.build(:person, **bob_params); end

      it "should find the active employee in multiple employer_profiles" do
        # it shouldn't find google bob because dob are different
        expect(EmployerProfile.find_all_by_person(valid_person).size).to eq 2
      end

      it "should return EmployerProfile" do
        expect(EmployerProfile.find_all_by_person(valid_person).first).to be_a EmployerProfile
      end

      it "should include the matching employee" do
        found = EmployerProfile.find_all_by_person(valid_person).last.employee_families.last.census_employee
        [:first_name, :last_name, :ssn, :dob].each do |attr|
          expect(found.send(attr)).to eq valid_person.send(attr)
        end
      end
    end

    context "fails to match an employee" do
      def invalid_person; Person.new(**params.merge(ssn: invalid_ssn)); end

      it "should not return any matches" do
        # expect(invalid_person.ssn).to eq invalid_ssn
        expect(EmployerProfile.find_all_by_person(invalid_person).size).to eq 0
      end
    end
  end
end

describe EmployerProfile, "instance methods" do
  let(:census_employee)  { FactoryGirl.build(:employer_census_employee, ssn: "069851240", dob: 34.years.ago.to_date)}
  let(:census_family)    { FactoryGirl.build(:employer_census_family, census_employee: census_employee, employer_profile: nil)}
  let(:person)           { Person.new(first_name: census_employee.first_name, last_name: census_employee.last_name, ssn: census_employee.ssn, dob: 34.years.ago.to_date)}
  let(:premium_statement_1) { FactoryGirl.build(:premium_statement, effective_on: Date.current - 10)}
  let(:premium_statement_2) { FactoryGirl.build(:premium_statement, effective_on: Date.current - 90)}

  describe "#employee_roles" do
    let(:employer_profile)  { FactoryGirl.create(:employer_profile) }
    let(:people)  { FactoryGirl.create_list(:person, 2) }
    let!(:ee0)  { FactoryGirl.create(:employee_role, person: people[0], employer_profile: employer_profile) }
    let!(:ee1)  { FactoryGirl.create(:employee_role, person: people[1], employer_profile: employer_profile) }
    # let(:employees)         { FactoryGirl.create_list(:employee_role, employee_count, employer_profile: employer_profile) }
    let!(:ee_roles)          { employer_profile.employee_roles }

    context "an employer profile with multiple associated employee roles" do
      it "should find all employees" do
        expect(ee_roles.size).to eq 2
      end

      it "should return array of employee_role instances" do
        expect(ee_roles.first).to be_a EmployeeRole
      end

      it "should be associated with correct employer profile" do
        expect(ee_roles.first.employer_profile).to eq employer_profile
      end
    end
  end

  describe "#latest_premium_statement" do
    let(:employer_profile)  { FactoryGirl.create(:employer_profile) }

    context "employer profile with multiple premium statuses" do
      before do
        employer_profile.premium_statements = [premium_statement_1, premium_statement_2]
      end

      it "should return the premiums status with latest effective on date" do
        expect(employer_profile.latest_premium_statement).to eq premium_statement_1
      end
    end
  end

  describe "#linkable_employee_family_by_person" do
    let(:employer_profile) {FactoryGirl.create(:employer_profile)}

    context "with matching census_family employee" do
      let(:employer_profile) {FactoryGirl.create(:employer_profile, employee_families: [census_family])}

      context "with employee previously terminated" do
        let(:prior_census_employee) {FactoryGirl.build(:employer_census_employee, ssn: "069851240", terminated_on: Date.today )}
        let(:prior_census_family) {FactoryGirl.build(:employer_census_family, census_employee: prior_census_employee, linked_at: Date.today - 1,terminated: true, employer_profile: nil)}
        let(:employer_profile) {FactoryGirl.create(:employer_profile, employee_families: [prior_census_family, census_family])}

        it "should return only the matching census family" do
          expect(employer_profile.linkable_employee_family_by_person(person)).to eq census_family
        end

        context "with employee who was never linked" do
          let(:prior_census_employee) {FactoryGirl.build(:employer_census_employee, ssn: "069851240", terminated_on: Date.today )}
          let(:prior_census_family) {FactoryGirl.build(:employer_census_family, census_employee: prior_census_employee, terminated: true, employer_profile: nil)}
          let(:employer_profile) {FactoryGirl.create(:employer_profile, employee_families: [prior_census_family, census_family])}

          it "should return only the matching census family" do
            expect(employer_profile.linkable_employee_family_by_person(person)).to eq census_family
          end
        end
      end
    end
  end
end

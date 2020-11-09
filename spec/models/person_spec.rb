require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe Person, :dbclean => :after_each do

  describe "model" do
    it { should validate_presence_of :first_name }
    it { should validate_presence_of :last_name }

    let(:first_name) {"Martina"}
    let(:last_name) {"Williams"}
    let(:ssn) {"657637863"}
    let(:gender) {"male"}
    let(:address) {FactoryBot.build(:address)}
    let(:valid_params) do
      { first_name: first_name,
        last_name: last_name,
        ssn: ssn,
        gender: gender,
        addresses: [address]
      }
    end

    describe ".create", dbclean: :around_each do
      context "with valid arguments" do
        let(:params) {valid_params}
        let(:person) {Person.create(**params)}
        before do
          person.valid?
        end

        it 'should generate hbx_id' do
          expect(person.hbx_id).to be_truthy
        end

        context "and a second person is created with the same ssn" do
          let(:person2) {Person.create(**params)}
          before do
            person2.valid?
          end

          context "the second person" do
            it "should not be valid" do
              expect(person2.valid?).to be false
            end

            it "should have an error on ssn" do
              expect(person2.errors[:ssn].any?).to be true
            end

            it "should not have the same id as the first person" do
              expect(person2.id).not_to eq person.id
            end
          end
        end
      end
    end

    describe ".new" do
      context "with no arguments" do
        let(:params) {{}}

        it "should be invalid" do
          expect(Person.new(**params).valid?).to be_falsey
        end
      end

      context "with all valid arguments" do
        let(:params) {valid_params}
        let(:person) {Person.new(**params)}

        it "should save" do
          expect(person.valid?).to be_truthy
        end

        it "should known its relationship is self" do
          expect(person.find_relationship_with(person)).to eq "self"
        end

        it "unread message count is accurate" do
          expect(person.inbox).to be nil
          person.save
          expect(person.inbox.messages.count).to eq 1
          expect(person.inbox.unread_messages.count).to eq 1
        end

        it "has correct welcome message for consumer role" do
          person.save
          expect(person.inbox.messages.first.body).to include("Make sure you pay attention to deadlines.")
        end
      end

      context "with broker role" do
        let(:params) {valid_params}
        let(:person) {Person.new(**params)}
        let(:broker_agency_profile) {FactoryBot.create(:broker_agency_profile)}

        before do
          FactoryBot.create(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
        end

        it "has correct welcome message for broker role" do
          person.save
          expect(person.inbox.messages.first.body).not_to include("Make sure you pay attention to deadlines.")
        end
      end

      context "with no first_name" do
        let(:params) {valid_params.except(:first_name)}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:first_name].any?).to be_truthy
        end
      end

      context "with no last_name" do
        let(:params) {valid_params.except(:last_name)}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:last_name].any?).to be_truthy
        end
      end

      context "with no ssn" do
        let(:params) {valid_params.except(:ssn)}

        it "should not fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:ssn].any?).to be_falsey
        end
      end

      context "with invalid gender" do
        let(:params) {valid_params.deep_merge({gender: "abc"})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:gender]).to eq ["abc is not a valid gender"]
        end
      end

      context 'duplicated key issue' do

        def drop_encrypted_ssn_index_in_db
          Person.collection.indexes.each do |spec|
            if spec["key"].keys.include?("encrypted_ssn")
              if spec["unique"] && spec["sparse"]
                Person.collection.indexes.drop_one(spec["key"])
              end
            end
          end
        end

        def create_encrypted_ssn_uniqueness_index
          Person.index_specifications.each do |spec|
            if spec.options[:unique] && spec.options[:sparse]
              if spec.key.keys.include?(:encrypted_ssn)
                key, options = spec.key, spec.options
                Person.collection.indexes.create_one(key, options)
              end
            end
          end
        end

        before :each do
          drop_encrypted_ssn_index_in_db
          create_encrypted_ssn_uniqueness_index
        end

        context "with blank ssn" do

          let(:params) {valid_params.deep_merge({ssn: ""})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:ssn].any?).to be_falsey
          end

          it "allow duplicated blank ssn" do
            person1 = Person.create(**params)
            person2 = Person.create(**params)
            expect(person2.errors[:ssn].any?).to be_falsey
          end
        end

        context "with nil ssn" do
          let(:params) {valid_params.deep_merge({ssn: nil})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:ssn].any?).to be_falsey
          end

          it "allow duplicated blank ssn" do
            person1 = Person.create(**params)
            person2 = Person.create(**params)
            expect(person2.errors[:ssn].any?).to be_falsey
          end
        end
      end

      context "with nil ssn" do
        let(:params) {valid_params.deep_merge({ssn: ""})}

        it "should not fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:ssn].any?).to be_falsey
        end
      end

      context "with invalid ssn" do
        let(:params) {valid_params.deep_merge({ssn: "123345"})}

        it "should fail validation" do
          person = Person.new(**params)
          person.valid?
          expect(person.errors[:ssn]).to eq ["SSN must be 9 digits"]
        end
      end

      context "with date of birth" do
        let(:dob){ 25.years.ago }
        let(:params) {valid_params.deep_merge({dob: dob})}

        before(:each) do
          @person = Person.new(**params)
        end

        it "should get the date of birth" do
          expect(@person.date_of_birth).to eq dob.strftime("%m/%d/%Y")
        end

        it "should set the date of birth" do
          @person.date_of_birth = "01/01/1985"
          expect(@person.dob.to_s).to eq "01/01/1985"
        end

        it "should return date of birth as string" do
          expect(@person.dob_to_string).to eq dob.strftime("%Y%m%d")
        end

        it "should return if a person is active or not" do
          expect(@person.is_active?).to eq true
          @person.is_active = false
          expect(@person.is_active?).to eq false
        end

=begin
        context "dob more than 110 years ago" do
          let(:dob){ 200.years.ago }

          it "should have a validation error" do
            expect(@person.valid?).to be_falsey
            expect(@person.errors.full_messages).to include("Dob date cannot be more than 110 years ago")
          end

        end
=end
      end

      context "with invalid date values" do
        context "and date of birth is in future" do
          let(:params) {valid_params.deep_merge({dob: TimeKeeper.date_of_record + 1})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:dob].size).to eq 1
          end
        end

        context "and date of death is in future" do
          let(:params) {valid_params.deep_merge({date_of_death: TimeKeeper.date_of_record + 1})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:date_of_death].size).to eq 1
          end
        end

        context "and date of death preceeds date of birth" do
          let(:params) {valid_params.deep_merge({date_of_death: Date.today - 10, dob: Date.today - 1})}

          it "should fail validation" do
            person = Person.new(**params)
            person.valid?
            expect(person.errors[:date_of_death].size).to eq 1
          end
        end
      end

      context "has_employer_benefits?" do
        let(:person) {FactoryBot.build(:person)}
        let(:benefit_group) { FactoryBot.build(:benefit_group)}
        let(:employee_roles) {double(active: true)}
        let(:census_employee) { double }
        let(:employee_role1) { FactoryBot.build(:employee_role) }
        let(:employee_role2) { FactoryBot.build(:employee_role) }

        before do
          allow(employee_roles).to receive(:census_employee).and_return(census_employee)
          allow(census_employee).to receive(:is_active?).and_return(true)
          allow(employee_roles).to receive(:benefit_group).and_return(benefit_group)
        end

        it "should return true" do
          allow(person).to receive(:employee_roles).and_return([employee_roles])
          allow(employee_roles).to receive(:benefit_group).and_return(benefit_group)
          expect(person.has_employer_benefits?).to eq true
        end

        it "should return false" do
          allow(person).to receive(:employee_roles).and_return([])
          expect(person.has_employer_benefits?).to eq false
        end

        it "should return true" do
          allow(person).to receive(:employee_roles).and_return([employee_roles])
          allow(employee_roles).to receive(:benefit_group).and_return(nil)
          expect(person.has_employer_benefits?).to eq true
        end

        it "should return true when person has multiple employee_roles and one employee_role has benefit_group" do
          allow(person).to receive(:active_employee_roles).and_return([employee_role1, employee_role2])
          allow(employee_role1).to receive(:benefit_group).and_return(nil)
          allow(employee_role2).to receive(:benefit_group).and_return(benefit_group)
          expect(person.has_employer_benefits?).to be_truthy
        end
      end

      context "has_multiple_active_employers?" do
        let(:person) { FactoryBot.build(:person) }
        let(:er1) { double("EmployeeRole1") }
        let(:er2) { double("EmployeeRole2") }

        it "should return false without census_employees" do
          allow(person).to receive(:active_employee_roles).and_return([])
          expect(person.has_multiple_active_employers?).to be_falsey
        end

        it "should return false with only one census_employee" do
          allow(person).to receive(:active_employee_roles).and_return([er1])
          expect(person.has_multiple_active_employers?).to be_falsey
        end

        it "should return true with two census_employees" do
          allow(person).to receive(:active_employee_roles).and_return([er1, er2])
          expect(person.has_multiple_active_employers?).to be_truthy
        end
      end

      context "has_active_employee_role?" do
        let(:person) {FactoryBot.build(:person)}
        let(:employee_roles) {double(active: true)}
        let(:census_employee) { double }

        before do
          allow(employee_roles).to receive(:census_employee).and_return(census_employee)
          allow(census_employee).to receive(:is_active?).and_return(true)
        end

        it "should return true" do
          allow(person).to receive(:employee_roles).and_return([employee_roles])
          expect(person.has_active_employee_role?).to eq true
        end

        it "should return false" do
          allow(person).to receive(:employee_roles).and_return([])
          expect(person.has_active_employee_role?).to eq false
        end
      end

      context "consumer fields validation" do
        let(:params) {valid_params}
        let(:person) { Person.new(**params) }
        let!(:consumer_role) { FactoryBot.create(:consumer_role, citizen_status: nil)}
        errors = { citizenship: "Citizenship status is required.",
                         naturalized: "Naturalized citizen is required.",
                         immigration: "Eligible immigration status is required.",
                         native: "American Indian / Alaska Native status is required.",
                         tribal_id_presence: "Tribal id is required when native american / alaska native is selected",
                         tribal_id: "Tribal id must be 9 digits",
                         incarceration: "Incarceration status is required." }

        shared_examples_for "validate consumer_fields_validations private" do |citizenship, naturalized, immigration_status, native, tribal_id, incarceration, is_valid, error_list|
          before do
            allow(person).to receive(:consumer_role).and_return consumer_role
            person.instance_variable_set(:@is_consumer_role, true)
            person.instance_variable_set(:@indian_tribe_member, native)
            person.instance_variable_set(:@us_citizen, citizenship)
            person.instance_variable_set(:@eligible_immigration_status, immigration_status)
            person.instance_variable_set(:@naturalized_citizen, naturalized)
            person.tribal_id = tribal_id
            person.is_incarcerated = incarceration
            person.valid?
          end

          it "#{is_valid ? 'pass' : 'fails'} validation" do
            expect(person.valid?).to eq is_valid
          end

          it "#{is_valid ? 'does not raise' : 'raises'} the errors #{} with #{} errors" do
            expect(person.errors[:base].count).to eq error_list.count
            expect(person.errors[:base]).to eq error_list
          end
        end

        it_behaves_like "validate consumer_fields_validations private", true, true, false, true, "3344", false, false, [errors[:tribal_id]]
        it_behaves_like "validate consumer_fields_validations private", nil, nil, false, nil, nil, nil, false, [errors[:citizenship], errors[:native], errors[:incarceration]]
        it_behaves_like "validate consumer_fields_validations private", nil, "true", false, false, nil, false, false, [errors[:citizenship]]
        it_behaves_like "validate consumer_fields_validations private", nil, nil, false, false, nil, false, false, [errors[:citizenship]]
        it_behaves_like "validate consumer_fields_validations private", true, false, false, false, nil, nil, false, [errors[:incarceration]]
        it_behaves_like "validate consumer_fields_validations private", true, false, false, true, nil, nil, false, [errors[:tribal_id_presence], errors[:incarceration]]
        it_behaves_like "validate consumer_fields_validations private", false, nil, nil, true, nil, nil, false, [errors[:immigration], errors[:incarceration]]
        it_behaves_like "validate consumer_fields_validations private", nil, nil, nil, nil, nil, nil, false, [errors[:citizenship], errors[:native], errors[:incarceration]]
      end

      if ExchangeTestingConfigurationHelper.individual_market_is_enabled?
        context 'consumer fields validation - applying for coverage false' do
          let(:params) {valid_params}
          let(:person) {Person.new(**params)}
          let!(:consumer_role) {FactoryBot.create(:consumer_role, citizen_status: nil, is_applying_coverage: false)}

          shared_examples_for 'validate consumer_fields_validations private' do |citizenship, naturalized, incarceration, is_valid, error_list|
            before do
              allow(person).to receive(:consumer_role).and_return consumer_role
              person.instance_variable_set(:@is_consumer_role, true)
              person.instance_variable_set(:@us_citizen, citizenship)
              person.instance_variable_set(:@naturalized_citizen, naturalized)
              person.is_incarcerated = incarceration
              person.valid?
            end

            it "#{is_valid ? 'pass' : 'fails'} validation" do
              expect(person.valid?).to eq is_valid
            end

            it "#{is_valid ? 'does not raise' : 'raise'} the errors" do
              expect(person.errors[:base].count).to eq error_list.count
              expect(person.errors[:base]).to eq error_list
            end
          end
          it_behaves_like 'validate consumer_fields_validations private', nil, nil, nil, true, []
        end
      end

      context "is_consumer_role_active?" do
        let(:person) {FactoryBot.build(:person)}
        let(:consumer_role) {double(is_active?: true)}

        it "should return true" do
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          allow(person).to receive(:is_consumer_role_active?).and_return(true)

          expect(person.is_consumer_role_active?).to eq true
        end

        it "should return false" do
          allow(person).to receive(:consumer_role).and_return(nil)
          allow(person).to receive(:is_consumer_role_active?).and_return(false)

          expect(person.is_consumer_role_active?).to eq false
        end
      end

      context "has_multiple_roles?" do
        let(:person) {FactoryBot.build(:person)}
        let(:employee_roles) {double(active: true)}
        let(:consumer_role) {double(is_active?: true)}

        it "returns true if person has consumer_role and employee_roles" do
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          allow(person).to receive(:active_employee_roles).and_return(employee_roles)

          expect(person.has_multiple_roles?).to eq true
        end

        it "returns false if person has only consumer_role" do
          allow(person).to receive(:consumer_role).and_return(consumer_role)
          allow(person).to receive(:active_employee_roles).and_return(nil)

          expect(person.has_multiple_roles?).to eq false
        end

        it "returns false if person has only consumer_role" do
          allow(person).to receive(:consumer_role).and_return(nil)
          allow(person).to receive(:employee_roles).and_return(employee_roles)

          expect(person.has_multiple_roles?).to eq false
        end

        it "returns false if person has no roles" do
          allow(person).to receive(:consumer_role).and_return(nil)
          allow(person).to receive(:employee_roles).and_return(nil)

          expect(person.has_multiple_roles?).to eq false
        end
      end
    end
  end

  describe '.match_by_id_info' do
    before(:each) do
      @p0 = Person.create!(first_name: "Jack",   last_name: "Bruce",   dob: "1943-05-14", ssn: "517994321")
      @p1 = Person.create!(first_name: "Ginger", last_name: "Baker",   dob: "1939-08-19", ssn: "888007654")
      @p2 = Person.create!(first_name: "Eric",   last_name: "Clapton", dob: "1945-03-30", ssn: "666332345")
      @p4 = Person.create!(first_name: "Joe",   last_name: "Kramer", dob: "1993-03-30")
      @p5 = Person.create(first_name: "Justin", last_name: "Kenny", dob: "1983-06-20", is_active: false)
    end


    it 'matches by last_name, first name and dob if no previous ssn and no current ssn' do
      expect(Person.match_by_id_info(last_name: @p4.last_name, dob: @p4.dob, first_name: @p4.first_name)).to eq [@p4]
    end

    it 'matches by last_name, first name and dob if no previous ssn and yes current ssn' do
      expect(Person.match_by_id_info(last_name: @p4.last_name, dob: @p4.dob, first_name: @p4.first_name, ssn: '123123123')).to eq [@p4]
    end

    it 'matches by last_name, first_name and dob if yes previous ssn and no current_ssn' do
      expect(Person.match_by_id_info(last_name: @p0.last_name, dob: @p0.dob, first_name: @p0.first_name)).to eq [@p0]
    end

    it 'matches by last_name, first_name and dob if yes previous ssn and no current_ssn and UPPERCASED' do
      expect(Person.match_by_id_info(last_name: @p0.last_name.upcase, dob: @p0.dob, first_name: @p0.first_name.upcase)).to eq [@p0]
    end

    it 'matches by last_name, first_name and dob if yes previous ssn and no current_ssn and LOWERCASED' do
      expect(Person.match_by_id_info(last_name: @p0.last_name.downcase, dob: @p0.dob, first_name: @p0.first_name.downcase)).to eq [@p0]
    end

    it 'matches by ssn' do
      expect(Person.match_by_id_info(ssn: @p1.ssn)).to eq []
    end

    it 'matches by ssn, last_name and dob' do
      expect(Person.match_by_id_info(last_name: @p2.last_name, dob: @p2.dob, ssn: @p2.ssn)).to eq [@p2]
    end

    it 'not match last_name and dob if not on same record' do
      expect(Person.match_by_id_info(last_name: @p0.last_name, dob: @p1.dob, first_name: @p4.first_name).size).to eq 0
    end

    it 'returns empty array for non-matches' do
      expect(Person.match_by_id_info(ssn: "577600345")).to eq []
    end

    it 'not match last_name and dob if ssn provided (match is already done if ssn ok)' do
      expect(Person.match_by_id_info(last_name: @p0.last_name, dob: @p0.dob, ssn: '999884321').size).to eq 0
    end

    it 'ssn, dob present, then should return person object' do
      expect(Person.match_by_id_info(dob: @p0.dob, ssn: '999884321').size).to eq 0
    end

    it 'ssn present, dob not present then should return empty array' do
      expect(Person.match_by_id_info(ssn: '999884321').size).to eq 0
    end

    it 'ssn present, dob present, first_name, last_name present and person inactive' do
      @p4.update_attributes(is_active:false)
      expect(Person.match_by_id_info(last_name: @p4.last_name, dob: @p4.dob, first_name: @p4.first_name, ssn: '123123123').size).to eq 0
    end

    it 'returns person records only where is_active == true' do
      expect(@p2.is_active).to eq true
      expect(Person.match_by_id_info(last_name: @p2.last_name, dob: @p2.dob, first_name: @p2.first_name)).to eq [@p2]
    end

    it 'should not match person record if is_active == false' do
      expect(@p5.is_active).to eq false
      expect(Person.match_by_id_info(last_name: @p5.last_name, dob: @p5.dob, first_name: @p5.first_name)).to be_empty
    end
  end

  describe '.active', :dbclean => :around_each do
    it 'new person defaults to is_active' do
      expect(Person.create!(first_name: "eric", last_name: "Clapton").is_active).to eq true
    end

    it 'returns person records only where is_active == true' do
      p1 = Person.create!(first_name: "Jack", last_name: "Bruce", is_active: false)
      p2 = Person.create!(first_name: "Ginger", last_name: "Baker")
      expect(Person.active.size).to eq 1
      expect(Person.active.first).to eq p2
    end
  end

  ## Instance methods
  describe '#addresses' do
    it "invalid address bubbles up" do
      person = Person.new
      addresses = person.addresses.build({address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})
      expect(person.valid?).to eq false
      expect(person.errors[:addresses].any?).to eq true
    end

    it 'persists associated address', dbclean: :after_each do
      # setup
      person = FactoryBot.build(:person)
      addresses = person.addresses.build({kind: "home", address_1: "441 4th ST, NW", city: "Washington", state: "DC", zip: "20001"})

      result = person.save

      expect(result).to eq true
      expect(person.addresses.first.kind).to eq "home"
      expect(person.addresses.first.city).to eq "Washington"
    end
  end

=begin
  describe '#find_all_staff_roles_by_employer_profile' do
    employer_profile = FactoryBot.build(:employer_profile)
    person = FactoryBot.build(:person)
    FactoryBot.create(:employer_staff_role, person: person, employer_profile_id: employer_profile.id)
    it "should have the same search criteria" do
      allow(Person).to receive(:where).and_return([person])
      expect(Person.find_all_staff_roles_by_employer_profile(employer_profile)).to eq [person]
    end

  end
=end

  describe "large family with multiple employees - The Brady Bunch", :dbclean => :after_all do
    include_context "BradyBunchAfterAll"

    before :all do
      create_brady_families
    end

    context "a person" do
      it "should know its age today" do

        expect(greg.age_on(Date.today)).to eq gregs_age
      end

      it "should know its age on a given date" do
        expect(greg.age_on(18.months.ago.to_date)).to eq (gregs_age - 2)
      end

      it "should know its age yesterday" do
        expect(greg.age_on(Date.today.advance(days: -1))).to eq (gregs_age - 1)
      end

      it "should know its age tomorrow" do
        expect(greg.age_on(1.day.from_now.to_date)).to eq gregs_age
      end
    end

    context "Person#primary_family" do
      context "on Mike" do
        let(:find) {mike.primary_family}
        it "should find Mike's family" do
          expect(find.id.to_s).to eq mikes_family.id.to_s
        end
      end

      context "on Carol" do
        let(:find) {carol.primary_family}
        it "should find Carol's family" do
          expect(find.id.to_s).to eq carols_family.id.to_s
        end
      end
    end

    context "Person#families" do
      context "on Mike" do
        let(:find) {mike.families.collect(&:id)}
        it "should find two families" do
          expect(find.count).to be 2
        end
        it "should find Mike's family" do
          expect(find).to include mikes_family.id
        end
        it "should find Carol's family" do
          expect(find).to include carols_family.id
        end
      end

      context "on Carol" do
        let(:find) {carol.families.collect(&:id)}
        it "should find two families" do
          expect(find.count).to be 2
        end
        it "should find Mike's family" do
          expect(find).to include mikes_family.id
        end
        it "should find Carol's family" do
          expect(find).to include carols_family.id
        end
      end

      context "on Greg" do
        let(:find) {greg.families.collect(&:id)}
        it "should find two families" do
          expect(find.count).to be 2
        end
        it "should find Mike's family" do
          expect(find).to include mikes_family.id
        end
        it "should find Carol's family" do
          expect(find).to include carols_family.id
        end
      end
    end
  end

  describe '#person_relationships' do
    it 'accepts associated addresses' do
      # setup
      person = FactoryBot.build(:person)
      relationship = person.person_relationships.build({kind: "self", relative: person})

      expect(person.save).to eq true
      expect(person.person_relationships.size).to eq 1
      expect(relationship.invert_relationship.kind).to eq "self"
    end
  end

  describe '#full_name' do
    it 'returns the concatenated name attributes' do
      expect(Person.new(first_name: "Ginger", last_name: "Baker").full_name).to eq 'Ginger Baker'
    end
  end

  describe '#phones' do
    it "sets person's home telephone number" do
      person = Person.new
      person.phones.build({kind: 'home', area_code: '202', number: '555-1212'})

      # expect(person.phones.first.number).to eq '5551212'
    end
  end

  describe '#emails' do
    it "sets person's home email" do
      person = Person.new
      person.emails.build({kind: 'home', address: 'sam@example.com'})
      expect(person.emails.first.address).to eq 'sam@example.com'
    end
  end

  describe '#work_email_or_best' do
    it "expects to get a work email address or home address" do
      person = Person.new
      person.emails.build({kind: 'work', address: 'work1@example.com'})
      expect(person.work_email_or_best).to eq 'work1@example.com'
    end
  end

  describe '#families' do
    it 'returns families where the person is present' do
    end
  end

  describe 'ensure_relationship_with' do
    let(:person10) { FactoryBot.create(:person) }

    describe 'with no relationship to a dependent' do
      context 'after ensure_relationship_with' do
        let(:person11) { FactoryBot.create(:person) }

        before do
          person10.ensure_relationship_with(person11, 'child')
          person10.save!
        end

        it 'should have the new relationship' do
          expect(person10.person_relationships.first.relative_id).to eq(person11.id)
        end

        it 'should have fixed number of relationships' do
          expect(person10.person_relationships.count).to eq(1)
        end
      end
    end

    describe 'with an existing relationship to a dependent' do
      context 'after ensure_relationship_with a different type of relationship' do
        let(:person11) do
          human = FactoryBot.create(:person)
          person10.person_relationships << PersonRelationship.new(relative_id: human.id, kind: 'child')
          person10.save!
          human
        end

        before do
          person10.ensure_relationship_with(person11, 'spouse')
          person10.save!
        end

        it "should correct the existing relationship" do
          expect(person10.person_relationships.first.kind).to eq('spouse')
        end

        it 'should not have the old relationship' do
          expect(person10.person_relationships.count).to eq(1)
        end
      end
    end

    context 'should not create a relationship from self to self' do
      before do
        person10.ensure_relationship_with(person10, 'unrelated')
        person10.save!
      end

      it 'should not create any relationships' do
        expect(person10.person_relationships).to be_empty
      end

      it 'should have fixed number of relationships' do
        expect(person10.person_relationships.count).to be_zero
      end
    end
  end

  describe "call notify change event when after save" do
    before do
      extend Notify
    end

    context "notify change event" do
      let(:person){FactoryBot.build(:person)}
      it "when new record" do
        #      expect(person).to receive(:notify_change_event).exactly(1).times
        person.save
      end

      it "when change record" do
        #      expect(person).to receive(:notify_change_event).exactly(1).times
        first_name = person.first_name
        person.first_name = "Test"
        person.save
      end
    end
  end

  describe "does not allow two people with the same user ID to be saved", dbclean: :around_each do
    let(:person1){FactoryBot.build(:person)}
    let(:person2){FactoryBot.build(:person)}

    def drop_user_id_index_in_db
      Person.collection.indexes.each do |spec|
        if spec["key"].keys.include?("user_id")
          if spec["unique"] && spec["sparse"]
            Person.collection.indexes.drop_one(spec["key"])
          end
        end
      end
    end

    def create_user_id_uniqueness_index
      Person.index_specifications.each do |spec|
        if spec.options[:unique] && spec.options[:sparse]
          if spec.key.keys.include?(:user_id)
            key, options = spec.key, spec.options
            Person.collection.indexes.create_one(key, options)
          end
        end
      end
    end

    before :each do
      drop_user_id_index_in_db
      create_user_id_uniqueness_index
    end

    it "should let fail to save" do
      user_id = BSON::ObjectId.new
      person1.user_id = user_id
      person2.user_id = user_id
      person1.save!
      expect { person2.save! }.to raise_error(Mongo::Error::OperationFailure)
    end

  end

  describe "persisted with no user" do
    let(:person1){FactoryBot.create(:person)}
    let(:user1){FactoryBot.create(:user)}

    it "should be fine with having a user assigned" do
      person1.user = user1
      expect(person1.valid?).to eq(true)
    end
  end

  describe "persisted with a user" do
    let(:person1){FactoryBot.create(:person)}
    let(:user1){FactoryBot.create(:user)}
    let(:user2){FactoryBot.create(:user)}

    before :each do
      person1.user = user1
      person1.save!
    end

    it "should not allow a different user to be assigned" do
      expect(person1.valid?).to eq(true)
      person1.user = user2
      expect(person1.valid?).to eq(false)
    end
    it "should allow the same user to be assigned" do
      expect(person1.valid?).to eq(true)
      person1.user = nil
      person1.user = user1
      expect(person1.valid?).to eq(true)
    end
  end

  describe "validation of date_of_birth and date_of_death" do
    let(:person) { FactoryBot.create(:person) }

    context "validate of date_of_birth_is_past" do
      it "should invalid" do
        dob = (Date.today + 10.days)
        allow(person).to receive(:dob).and_return(dob)
        expect(person.save).to be_falsey
        expect(person.errors[:dob].any?).to be_truthy
        expect(person.errors[:dob].to_s).to match /future date: #{dob.to_s} is invalid date of birth/
      end
    end

    context "date_of_death_is_blank_or_past" do
      it "should invalid" do
        date_of_death = (Date.today + 10.days)
        allow(person).to receive(:date_of_death).and_return(date_of_death)
        expect(person.save).to be_falsey
        expect(person.errors[:date_of_death].any?).to be_truthy
        expect(person.errors[:date_of_death].to_s).to match /future date: #{date_of_death.to_s} is invalid date of death/
      end
    end
  end

  describe "us_citizen status" do
    let(:person) { FactoryBot.create(:person) }

    before do
      person.us_citizen="false"
    end

    context "set to false" do
      it "should set @us_citizen to false" do
        expect(person.us_citizen).to be_falsey
      end

      it "should set @naturalized_citizen to false" do
        expect(person.naturalized_citizen).to be_falsey
      end
    end
  end

  describe "residency_eligible?" do
    let(:person) { FactoryBot.create(:person) }

    it "should false" do
      person.no_dc_address = false
      person.is_homeless = false
      person.is_temporarily_out_of_state = false
      expect(person.residency_eligible?).to be_falsey
    end

    it "should false" do
      person.no_dc_address = true
      person.is_homeless = false
      person.is_temporarily_out_of_state = false
      expect(person.residency_eligible?).to be_falsey
    end

    it "should true" do
      person.no_dc_address = true
      person.is_homeless = true
      person.is_temporarily_out_of_state = true
      expect(person.residency_eligible?).to be_truthy
    end
  end

  describe "home_address" do
    let(:person) { FactoryBot.create(:person) }

    it "return home address" do
      address_1 = Address.new(kind: 'home')
      address_2 = Address.new(kind: 'mailing')
      allow(person).to receive(:addresses).and_return [address_1, address_2]

      expect(person.home_address).to eq address_1
    end
  end

  describe "is_dc_resident?" do
    context "when person is homeless or temp outside of DC" do
      let(:person) { Person.new }

      it "return true when person is_homeless" do
        allow(person).to receive(:is_homeless?).and_return true
        expect(person.is_dc_resident?).to eq true
      end

      it "return true when person is_temporarily_out_of_state" do
        allow(person).to receive(:is_temporarily_out_of_state?).and_return true
        expect(person.is_dc_resident?).to eq true
      end
    end

    context "when no_dc_address is false" do
      let(:person) { Person.new(no_dc_address: false) }

      context "when state is not dc" do
        let(:home_addr) {Address.new(kind: 'home', state: 'AC')}
        let(:mailing_addr) {Address.new(kind: 'mailing', state: 'AC')}
        let(:work_addr) { Address.new(kind: 'work', state: 'AC') }
        it "home" do
          allow(person).to receive(:addresses).and_return [home_addr]
          expect(person.is_dc_resident?).to eq false
        end

        it "mailing" do
          allow(person).to receive(:addresses).and_return [mailing_addr]
          expect(person.is_dc_resident?).to eq false
        end

        it "work" do
          allow(person).to receive(:addresses).and_return [work_addr]
          expect(person.is_dc_resident?).to eq false
        end
      end

      context "when state is in settings state" do
        let(:home_addr) {Address.new(kind: 'home', state: Settings.aca.state_abbreviation)}
        let(:mailing_addr) {Address.new(kind: 'mailing', state: Settings.aca.state_abbreviation)}
        let(:work_addr) { Address.new(kind: 'work', state: Settings.aca.state_abbreviation) }
        it "home" do
          allow(person).to receive(:addresses).and_return [home_addr]
          expect(person.is_dc_resident?).to eq true
        end

        it "mailing" do
          allow(person).to receive(:addresses).and_return [mailing_addr]
          expect(person.is_dc_resident?).to eq true
        end

        it "work" do
          allow(person).to receive(:addresses).and_return [work_addr]
          expect(person.is_dc_resident?).to eq false
        end
      end
    end
  end

  describe "assisted and unassisted" do
    context "is_aqhp?" do
      let(:person) {FactoryBot.create(:person, :with_consumer_role)}
      let(:person1) {FactoryBot.create(:person, :with_consumer_role)}
      let(:person2) {FactoryBot.create(:person, :with_consumer_role)}
      let(:family1)  {FactoryBot.create(:family, :with_primary_family_member)}
      let(:household) {FactoryBot.create(:household, family: family1)}
      let(:tax_household) {FactoryBot.create(:tax_household, household: household) }
      let(:eligibility_determination) {FactoryBot.create(:eligibility_determination, tax_household: tax_household, csr_percent_as_integer: 10)}

      before :each do
        family1.households.first.tax_households<<tax_household
        family1.save
        @person_aqhp = family1.primary_applicant.person
      end
      it "creates person with status verification_pending" do
        expect(person.consumer_role.aasm_state).to eq("unverified")
      end

      it "returns people with uverified status" do
        expect(Person.unverified_persons.include? person1).to eq(true)
      end

      it "doesn't return people with verified status" do
        person2.consumer_role.aasm_state = "fully_verified"
        person2.save
        expect(Person.unverified_persons.include? person2).to eq(false)
      end

      it "creates family with households and tax_households" do
        expect(family1.households.first.tax_households).not_to be_empty
      end
    end
  end

  describe ".add_employer_staff_role(first_name, last_name, dob, email, employer_profile)" do
    let(:employer_profile){FactoryBot.create(:employer_profile)}
    let(:person_params) {{first_name: Forgery('name').first_name, last_name: Forgery('name').first_name, dob: '1990/05/01'}}
    let(:person1) {FactoryBot.create(:person, person_params)}

    context 'duplicate person PII' do
      before do
        FactoryBot.create(:person, person_params)
        @status, @result = Person.add_employer_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', employer_profile )
      end
      it 'returns false' do
        expect(@status).to eq false
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end
    end

    context 'zero matching person PII' do
      before {@status, @result = Person.add_employer_staff_role('sam', person1.last_name, person1.dob,'#default@email.com', employer_profile )}

      it 'returns false' do
        expect(@status).to eq false
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end
    end

    context 'matching one person PII' do
      before do
        person1.reload
        @status, @result = Person.add_employer_staff_role(person1.first_name, person1.last_name, person1.dob,'#default@email.com', employer_profile )
      end

      it 'returns true' do
        expect(@status).to eq true
      end

      it 'returns the person' do
        expect(@result).to eq person1
      end
    end
  end

  describe ".deactivate_employer_staff_role" do
    let(:person) {FactoryBot.create(:person)}
    let(:employer_staff_role) {FactoryBot.create(:employer_staff_role, person: person)}
    let(:employer_staff_roles) { FactoryBot.create_list(:employer_staff_role, 3, person: person) }
    context 'does not find the person' do
      before {@status, @result = Person.deactivate_employer_staff_role(1, employer_staff_role.employer_profile_id)}
      it 'returns false' do
        expect(@status).to be false
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end
    end
    context 'finds the person and inactivates the role' do
      before {@status, @result = Person.deactivate_employer_staff_role(person.id, employer_staff_role.employer_profile_id)}
      it 'returns true' do
        expect(@status).to be true
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end

      it 'sets is_active to false' do
        expect(employer_staff_role.reload.is_active?).to eq false
      end
    end

    context 'finds the person and inactivates all roles' do
      before {@status, @result = Person.deactivate_employer_staff_role(person.id, employer_staff_role.employer_profile_id)}
      it 'returns true' do
        expect(@status).to be true
      end

      it 'returns msg' do
        expect(@result).to be_instance_of String
      end

      it 'has more than one employer_staff_role' do
        employer_staff_roles
        expect(person.employer_staff_roles.count).to eq (employer_staff_roles << employer_staff_role).count
      end

      it 'sets is_active to false for each role' do
        expect(person.employer_staff_roles.each { |role|  role.reload.is_active? == false && !role.is_closed?})
      end
    end
  end

  describe "person_has_an_active_enrollment?" do


    let(:person) { FactoryBot.create(:person) }
    let(:employee_role) { FactoryBot.create(:employee_role, person: person) }
    let(:primary_family) { FactoryBot.create(:family, :with_primary_family_member) }


    context 'person_has_an_active_enrollment?' do
      let(:active_enrollment)   { FactoryBot.create( :hbx_enrollment,
                                          family: primary_family,
                                          household: primary_family.latest_household,
                                          employee_role_id: employee_role.id,
                                          is_active: true
                                       )}

      it 'returns true if person has an active enrollment.' do

        allow(person).to receive(:primary_family).and_return(primary_family)
        allow(primary_family).to receive(:enrollments).and_return([active_enrollment])
        expect(Person.person_has_an_active_enrollment?(person)).to be_truthy
      end
    end

    context 'person_has_an_inactive_enrollment?' do
      let(:inactive_enrollment)   { FactoryBot.create( :hbx_enrollment,
                                          family: primary_family,
                                          household: primary_family.latest_household,
                                          employee_role_id: employee_role.id,
                                          is_active: false
                                       )}

      it 'returns false if person does not have any active enrollment.' do

        allow(person).to receive(:primary_family).and_return(primary_family)
        allow(primary_family).to receive(:enrollments).and_return([inactive_enrollment])
        expect(Person.person_has_an_active_enrollment?(person)).to be_falsey
      end
    end

  end

  describe "has_active_employee_role_for_census_employee?" do
    let(:person) { FactoryBot.create(:person) }
    let(:census_employee) { FactoryBot.create(:census_employee) }
    let(:census_employee2) { FactoryBot.create(:census_employee) }

    context "person has no active employee roles" do
      it "should return false" do
        expect(person.active_employee_roles).to be_empty
        expect(person.has_active_employee_role_for_census_employee?(census_employee)).to be_falsey
      end
    end

    context "person has active employee roles" do
      before(:each) do
        person.employee_roles.create!(FactoryBot.create(:employee_role, person: person,
              census_employee_id: census_employee.id).attributes)
        person.active_employee_roles.each { |employee_role| employee_role.census_employee.update_attribute(:aasm_state, 'eligible') }
      end

      it "should return true if person has active employee role for given census_employee" do
        expect(person.active_employee_roles).to be_present
        expect(person.has_active_employee_role_for_census_employee?(census_employee)).to be_truthy
      end

      it "should return false if person does not have active employee role for given census_employee" do
        expect(person.active_employee_roles).to be_present
        expect(person.has_active_employee_role_for_census_employee?(census_employee2)).to be_falsey
      end
    end
   end

  describe "agent?" do
    let(:person) { FactoryBot.create(:person) }

    it "should return true with general_agency_staff_roles" do
      person.general_agency_staff_roles << FactoryBot.build(:general_agency_staff_role)
      expect(person.agent?).to be_truthy
    end
  end

  describe "dob_change_implication_on_active_enrollments" do

    let(:persons_dob) { TimeKeeper.date_of_record - 19.years }
    let(:person) { FactoryBot.create(:person, dob: persons_dob) }
    let(:primary_family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:enrollment)   { FactoryBot.create( :hbx_enrollment,
                                              family: primary_family,
                                              household: primary_family.latest_household,
                                              aasm_state: 'coverage_selected',
                                              effective_on: TimeKeeper.date_of_record - 10.days,
                                              is_active: true
                                            )}
    let(:new_dob_with_premium_implication)    { TimeKeeper.date_of_record - 35.years }
    let(:new_dob_without_premium_implication) { TimeKeeper.date_of_record - 17.years }

    let(:premium_implication_hash) { {enrollment.id => true} }
    let(:empty_hash) { {} }

    before do
      person.reload
      allow(person).to receive(:primary_family).and_return(primary_family)
      allow(primary_family).to receive(:enrollments).and_return([enrollment])
    end

    it "should return a NON-EMPTY hash with at least one enrollment if DOB change RESULTS in premium change" do
      expect(Person.dob_change_implication_on_active_enrollments(person, new_dob_with_premium_implication)).to eq premium_implication_hash
    end

    it "should return an EMPTY hash if DOB change DOES NOT RESULT in premium change" do
      expect(Person.dob_change_implication_on_active_enrollments(person, new_dob_without_premium_implication)).to eq empty_hash
    end

    context 'edge case when DOB change makes person 61' do

      let(:age_older_than_sixty_one) { TimeKeeper.date_of_record - 75.years }
      let(:person_older_than_sixty_one) { FactoryBot.create(:person, dob: age_older_than_sixty_one) }
      let(:primary_family) { FactoryBot.create(:family, :with_primary_family_member) }
      let(:new_dob_with_premium_implication)    { TimeKeeper.date_of_record - 35.years }
      let(:enrollment)   { FactoryBot.create( :hbx_enrollment, family: primary_family, household: primary_family.latest_household, aasm_state: 'coverage_selected', effective_on: Date.new(2016,1,1), is_active: true)}
      let(:new_dob_to_make_person_sixty_one)    { Date.new(1955,1,1) }

      before do
        person_older_than_sixty_one.reload
        allow(person_older_than_sixty_one).to receive(:primary_family).and_return(primary_family)
        allow(primary_family).to receive(:enrollments).and_return([enrollment])
      end

      it "should return an EMPTY hash if a person more than 61 year old changes their DOB so that they are 61 on the day the coverage starts" do
        expect(Person.dob_change_implication_on_active_enrollments(person_older_than_sixty_one, new_dob_to_make_person_sixty_one)).to eq empty_hash
      end

    end
  end

  describe "given a consumer role" do
    let(:consumer_role) { ConsumerRole.new }
    let(:subject) { Person.new(:consumer_role => consumer_role) }

    it "delegates #ivl_coverage_selected to consumer role" do
      expect(consumer_role).to receive(:ivl_coverage_selected)
      subject.ivl_coverage_selected
    end
  end

  describe "without a consumer role" do
    let(:subject) { Person.new }

    it "delegates #ivl_coverage_selected to nowhere" do
      expect { subject.ivl_coverage_selected }.not_to raise_error
    end
  end

  describe "#check_for_paper_application", dbclean: :after_each do
    let(:person) { FactoryBot.create(:person, :with_consumer_role, user: user) }
    let(:user) { FactoryBot.create(:user)}

    before do
      user.unset(:identity_final_decision_code)
    end

    it "should return true if user present & got paper in session variable" do
      expect(person.set_ridp_for_paper_application('paper')).to eq true
    end

    it "should return nil if no user present" do
      allow(person).to receive(:user).and_return nil
      expect(person.set_ridp_for_paper_application('paper')).to eq nil
    end

    it "should return nil if session variable is not paper" do
      expect(person.set_ridp_for_paper_application('something')).to eq nil
    end

    it "should return nil if session variable is nil" do
      expect(person.set_ridp_for_paper_application(nil)).to eq nil
    end

    it "should return nil if no user present & if session var is not paper" do
      person.user.destroy!
      expect(person.set_ridp_for_paper_application('something')).to eq nil
    end

    it "should return nil if user present and no consumer_role" do
      allow(person).to receive(:consumer_role).and_return nil
      expect(person.set_ridp_for_paper_application('paper')).to eq nil
    end

    it "should return update ID nad Application documents for consumer_role" do
      person.set_ridp_for_paper_application('paper')
      expect(person.consumer_role.identity_validation).to eq 'valid'
      expect(person.consumer_role.application_validation).to eq 'valid'
    end
  end

  describe '.brokers_matching_search_criteria' do
    let(:person) { FactoryBot.create(:person, :with_broker_role)}
    let(:broker_agency_profile) {FactoryBot.create(:broker_agency_profile)}
    let(:name) { person.full_name}

    before do
      Person.create_indexes
      FactoryBot.create(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      person.broker_role.update_attributes!(aasm_state: "active")
      person.broker_role.update_attributes!(npn: "11111111")
      person.save!
    end

    context 'when searched with first_name and last_name' do
      it 'should return matching agency' do
        people = Person.brokers_matching_search_criteria(name)
        expect(people.count).to eq(1)
        expect(people.first.full_name).to eq(name)
      end
    end

    context 'when searched with npn' do
      it 'should return matching agency' do
        people = Person.brokers_matching_search_criteria("11111111")
        expect(people.count).to eq(1)
        expect(people.first.broker_role.npn).to eq(person.broker_role.npn)
      end
    end
  end

  describe "staff_for_employer", dbclean: :around_each do
    include_context "setup benefit market with market catalogs and product packages"
    include_context "setup initial benefit application"
    let(:employer_profile) { abc_profile }

    context "employer has no staff roles assigned" do
      it "should return an empty array" do
        expect(Person.staff_for_employer(employer_profile)).to eq []
      end
    end

    context "employer has an active staff role" do
      let(:person) { FactoryBot.build(:person) }
      let(:staff_params)  {{ person: person, benefit_sponsor_employer_profile_id: employer_profile.id, aasm_state: :is_active }}

      before do
        person.employer_staff_roles << EmployerStaffRole.new(**staff_params)
        person.save!
      end

      it "should return the person object in an array" do
        expect(Person.staff_for_employer(employer_profile)).to eq [person]
      end
    end


    context "multiple employers have same person as staff" do
      let!(:organization)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let(:employer_profile2) { organization.employer_profile }
      let(:person) { FactoryBot.build(:person) }

      let(:staff_params1) { {person: person, benefit_sponsor_employer_profile_id: employer_profile.id, aasm_state: :is_active} }

      let(:staff_params2) { {person: person, benefit_sponsor_employer_profile_id: employer_profile2.id, aasm_state: :is_active} }

      before do
        person.employer_staff_roles << EmployerStaffRole.new(**staff_params1)
        person.employer_staff_roles << EmployerStaffRole.new(**staff_params2)
        person.save!
      end

      it "should return the person object in an array for employer 1" do
        expect(Person.staff_for_employer(employer_profile)).to eq [person]
      end

      it "should return the person object in an array for employer 2" do
        expect(Person.staff_for_employer(employer_profile2)).to eq [person]
      end

      context "target employer has staff role in inactive state" do
        let(:staff_params3) { {person: person, benefit_sponsor_employer_profile_id: employer_profile.id, aasm_state: :is_closed} }

        before do
          person.employer_staff_roles = []
          person.employer_staff_roles << EmployerStaffRole.new(**staff_params3)
          person.employer_staff_roles << EmployerStaffRole.new(**staff_params2)
          person.save!
        end

        it "should return empty array for target employer" do
          expect(Person.staff_for_employer(employer_profile)).to eq []
        end

        it "should return the person object in an array for employer 2" do
          expect(Person.staff_for_employer(employer_profile2)).to eq [person]
        end
      end
    end
  end

  describe 'get staff for broker' do
    let(:broker_agency_profile) {FactoryBot.create(:broker_agency_profile)}
    let(:broker_staff_people) { FactoryBot.create_list(:person, 5)}
    let(:terminated_staff_member) { FactoryBot.create(:person)}
    let(:pending_staff_member) { FactoryBot.create(:person)}

    before do
      broker_staff_people.each do |person|
        FactoryBot.create(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, person: person, broker_agency_profile: broker_agency_profile, aasm_state: 'active')
      end
      FactoryBot.create(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, person: terminated_staff_member, broker_agency_profile: broker_agency_profile, aasm_state: 'broker_agency_terminated')
      FactoryBot.create(:broker_agency_staff_role, broker_agency_profile_id: broker_agency_profile.id, person: pending_staff_member, broker_agency_profile: broker_agency_profile, aasm_state: 'broker_agency_pending')
    end

    context 'finds all active staff for broker with same broker agency profile id' do
      before do
        @broker_staff = Person.staff_for_broker(broker_agency_profile)
      end
      it "should return all active staff for broker" do
        expect(@broker_staff.size).to eq(5)
      end

      it "should only return active staff for broker" do
        @broker_staff.each do |staff|
          expect(staff.broker_agency_staff_roles.first.is_active?).to be true
        end
      end
    end

    context "finds all active & pending broker staff" do
      before do
        @broker_staff = Person.staff_for_broker_including_pending(broker_agency_profile)
      end

      it "should return all active staff for broker" do
        expect(@broker_staff.size).to eq(6)
      end

      it "should only return active & pending staff for broker" do
        @broker_staff.each do |staff|
          expect(staff.broker_agency_staff_roles.first.is_open?).to be true
        end
      end

    end
  end

  describe 'get staff for general agency' do
    let(:site) { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
    let!(:general_agency_organization) { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_general_agency_profile, site: site) }
    let(:general_agency_profile) { general_agency_organization.general_agency_profile }

    let(:ga_staff_people) { FactoryBot.create_list(:person, 5)}
    let(:terminated_staff_member) { FactoryBot.create(:person)}
    let(:pending_staff_member) { FactoryBot.create(:person)}

    before do
      ga_staff_people.each do |person|
        FactoryBot.create(:general_agency_staff_role, general_agency_profile_id: general_agency_profile.id, person: person, general_agency_profile: general_agency_profile, aasm_state: 'active')
      end
      FactoryBot.create(:general_agency_staff_role, general_agency_profile_id: general_agency_profile.id, person: terminated_staff_member, general_agency_profile: general_agency_profile, aasm_state: 'general_agency_terminated')
      FactoryBot.create(:general_agency_staff_role, general_agency_profile_id: general_agency_profile.id, person: pending_staff_member, general_agency_profile: general_agency_profile, aasm_state: 'general_agency_pending')
    end

    context 'finds all active staff for general agency with same general agency profile id' do
      before do
        @ga_staff = Person.staff_for_ga(general_agency_profile)
      end
      it "should return all active staff for ga" do
        expect(@ga_staff.size).to eq(5)
      end

      it "should only return active staff for ga" do
        @ga_staff.each do |staff|
          expect(staff.general_agency_staff_roles.first.active?).to be true
        end
      end
    end

    context "finds all active & pending ga staff" do
      before do
        @ga_staff = Person.staff_for_ga_including_pending(general_agency_profile)
      end

      it "should return all active staff for ga" do
        expect(@ga_staff.size).to eq(6)
      end

      it "should only return active & pending staff for ga" do
        @ga_staff.each do |staff|
          expect(staff.general_agency_staff_roles.first.is_open?).to be true
        end
      end

    end
  end
end

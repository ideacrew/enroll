# frozen_string_literal: true

require 'rails_helper'
describe Forms::ConsumerCandidate, "asked to match a person", dbclean: :after_each do

  before :each do
    DatabaseCleaner.clean
  end

  let(:user){ create(:user) }
  let!(:person) { create(:person, :with_ssn, user: user) }

  let!(:params) do
    {
      :dob => "2012-10-12",
      :ssn => person.reload.ssn,
      :first_name => "yo",
      :last_name => "guy",
      :gender => "m",
      :user_id => 20,
      :is_applying_coverage => false
    }
  end

  let(:subject) { Forms::ConsumerCandidate.new(params) }

  after(:each) do
    DatabaseCleaner.clean
  end

  context "uniq ssn" do

    context 'when ssn blank' do
      let(:params) { {:ssn => nil} }

      it "return true " do
        expect(subject.uniq_ssn).to eq true
      end
    end

    context 'when ssn matches with claimed user account' do
      it "should add errors" do
        subject.uniq_ssn
        expect(subject.errors[:ssn_taken]).to eq ["The social security number you entered is affiliated with another account."]
      end
    end

    context 'when ssn matches with unclaimed user account' do
      let(:person) { create(:person, :with_ssn) }

      it "should not add errors" do
        subject.uniq_ssn
        expect(subject.errors[:base]).to eq []
      end
    end
  end

  context "uniq ssn & dob" do

    context 'when ssn blank' do
      let(:params) { {:ssn => nil} }

      it "return true " do
        expect(subject.uniq_ssn_dob).to eq true
      end
    end

    context 'when ssn & dob combination did not match with existing person' do
      let(:params) { {:ssn => person.reload.ssn, :dob => "2012-10-12"} }

      it "should add errors" do
        subject.uniq_ssn_dob
        expect(subject.errors[:base]).to eq ["This Social Security Number and Date-of-Birth is invalid in our records.  Please verify the entry, and if correct, contact the DC Customer help center at #{Settings.contact_center.phone_number}."]
      end
    end

    context "does not add errors when ssn & dob matches with existing person record" do

      let(:params) { {:ssn => person.ssn, :dob => person.dob.strftime("%Y-%m-%d")} }

      it 'should not add errors' do
        subject.uniq_ssn_dob
        expect(subject.errors[:base]).to eq []
      end
    end
  end
end


describe "match a person in db" do
  let(:subject) do
    Forms::ConsumerCandidate.new({
                                   :dob => search_params.dob,
                                   :ssn => search_params.ssn,
                                   :first_name => search_param_name.first_name,
                                   :last_name => search_param_name.last_name,
                                   :gender => "m",
                                   :user_id => 20,
                                   :is_applying_coverage => false
                                 })
  end

  let(:search_params) { double(dob: db_person.dob.strftime("%Y-%m-%d"), ssn: db_person.ssn)}
  let(:search_param_name) { double(first_name: db_person.first_name, last_name: db_person.last_name)}

  after(:each) do
    DatabaseCleaner.clean
  end

  context "with a person with a first name, last name, dob and no SSN" do
    let(:db_person) { Person.create!(first_name: "Joe", last_name: "Kramer", dob: "1993-03-30", ssn: '')}

    it 'matches the person by last_name, first name and dob if there is no ssn' do
      expect(subject.match_person).to eq db_person
    end

    it 'matches the person ignoring case' do
      subject.first_name.upcase!
      subject.last_name.downcase!
      expect(subject.match_person).to eq db_person
    end

    context "with a person who has no ssn but an employer staff role", dbclean: :after_each do
      let!(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile, site: site) }
      let!(:employer_profile)    { benefit_sponsor.employer_profile }
      let!(:employer_staff_role) { EmployerStaffRole.create(person: db_person, benefit_sponsor_employer_profile_id: employer_profile.id) }

      it 'matches person by last name, first name and dob' do
        db_person.employer_staff_roles << employer_staff_role
        db_person.save!
        allow(search_params).to receive(:ssn).and_return("517991234")
        expect(subject.match_person).to eq db_person
      end
    end

    context "validating :match person", dbclean: :after_each do
      let!(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile,:with_broker_agency_profile, site: site) }
      let!(:employer_profile)    { benefit_sponsor.employer_profile }
      let!(:employer_staff_role) { EmployerStaffRole.create(person: db_person, benefit_sponsor_employer_profile_id: employer_profile.id) }
      let(:broker_role) { FactoryBot.build(:broker_role, npn: '234567890', person: db_person) }
      let(:user){ create(:user) }

      before do
        allow(Person).to receive(:where).and_return([db_person])
        allow(db_person).to receive(:user).and_return(user)
        allow(search_params).to receive(:ssn).and_return("517991234")
      end

      context 'with a person who has no ssn but with employer staff role', dbclean: :after_each do
        it 'matches person by last name, first name and dob' do
          db_person.employer_staff_roles << employer_staff_role
          db_person.save!
          expect(subject.match_person).to eq db_person
        end
      end

      context 'with a person who has no ssn but with broker role', dbclean: :after_each do
        before do
          allow(db_person).to receive(:broker_role).and_return(broker_role)
          db_person.save!
        end

        it 'matches person by last name, first name and dob' do
          subject.does_not_match_a_different_users_person
          expect(subject.errors.messages.present?).to eq true
          expect(subject.errors[:base]).to match(["#{db_person.first_name} #{db_person.last_name} is already affiliated with another account."])
        end
      end

      context 'with a person who has ssn but an broker agency staff role', dbclean: :after_each do
        before do
          db_person.broker_agency_staff_roles.create(aasm_state: :active, benefit_sponsors_broker_agency_profile_id: benefit_sponsor.broker_agency_profile.id)
          db_person.save!
        end

        it 'matches person by last name, first name and dob' do
          subject.does_not_match_a_different_users_person
          expect(subject.errors.messages.present?).to eq true
          expect(subject.errors[:base]).to match(["#{db_person.first_name} #{db_person.last_name} is already affiliated with another account."])
        end
      end

      context 'with a person who has ssn but no roles', dbclean: :after_each do
        before do
          allow(db_person).to receive(:employer_staff_roles).and_return(nil)
          db_person.save!
        end

        it 'matches person by last name, first name and dob' do
          subject.does_not_match_a_different_users_person
          expect(subject.errors.messages.present?).to eq true
          expect(subject.errors[:base]).to match(["#{db_person.first_name} #{db_person.last_name} is already affiliated with another account."])
        end
      end

      context 'with a person who no ssn but no roles', dbclean: :after_each do
        before do
          allow(db_person).to receive(:employer_staff_roles).and_return(nil)
          allow(search_params).to receive(:ssn).and_return(nil)
          db_person.save!
        end

        it 'matches person by last name, first name and dob' do
          subject.does_not_match_a_different_users_person
          expect(subject.errors.messages.present?).to eq true
          expect(subject.errors[:base]).to match(["#{db_person.first_name} #{db_person.last_name} is already affiliated with another account."])
        end
      end
    end

    context 'validating :uniq_name_ssn_dob', dbclean: :after_each do
      let!(:site)                { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
      let!(:benefit_sponsor)     { FactoryBot.create(:benefit_sponsors_organizations_general_organization, :with_aca_shop_cca_employer_profile,:with_broker_agency_profile, site: site) }
      let!(:employer_profile)    { benefit_sponsor.employer_profile }
      let!(:employer_staff_role) { EmployerStaffRole.create(person: db_person, benefit_sponsor_employer_profile_id: employer_profile.id) }
      let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile) }
      let(:broker_role) { FactoryBot.build(:broker_role, npn: '234567890', person: db_person) }
      let(:user){ create(:user) }

      before do
        allow(Person).to receive(:where).and_return([db_person])
        allow(db_person).to receive(:user).and_return(user)
        allow(search_params).to receive(:ssn).and_return('517991234')
        db_person.save!
      end

      context 'when matched person has a broker role', dbclean: :after_each do
        before do
          allow(db_person).to receive(:broker_role).and_return(broker_role)
          db_person.save!
        end

        it 'returns true if matched person has broker role' do
          allow(subject).to receive(:match_person).and_return(db_person)
          expect(subject.uniq_name_ssn_dob).to eq true
        end
      end

      context 'when matched person has a broker agency staff role', dbclean: :after_each do
        before do
          allow(db_person).to receive(:broker_role).and_return(nil)
          db_person.broker_agency_staff_roles.create(aasm_state: :active, benefit_sponsors_broker_agency_profile_id: benefit_sponsor.broker_agency_profile.id)
          db_person.save!
        end

        it 'returns true if matched person has broker agency staff role' do
          allow(subject).to receive(:match_person).and_return(db_person)
          expect(subject.uniq_name_ssn_dob).to eq true
        end
      end

      context 'when matched person have broker role or broker agency staff roles', dbclean: :after_each do
        before do
          allow(db_person).to receive(:broker_role).and_return(broker_role)
          db_person.broker_agency_staff_roles.create(aasm_state: :active, benefit_sponsors_broker_agency_profile_id: benefit_sponsor.broker_agency_profile.id)
          db_person.broker_role.update_attributes!(benefit_sponsors_broker_agency_profile_id: benefit_sponsor.broker_agency_profile.id)
          db_person.save!
        end

        it 'returns true if matched person has broker agency staff role' do
          allow(subject).to receive(:match_person).and_return(db_person)
          expect(subject.uniq_name_ssn_dob).to eq true
        end
      end

      context 'when matched person have no broker role or broker agency staff roles' do
        before do
          allow(db_person).to receive(:broker_role).and_return(nil)
          db_person.save!
        end

        it 'returns nil if matched person has broker agency staff role' do
          allow(subject).to receive(:match_person).and_return(db_person)
          expect(subject.uniq_name_ssn_dob).to eq nil
        end
      end

      context 'when person ssn is blank' do
        let(:person1) { Person.create!(first_name: 'Joe', last_name: 'Kramer',   dob: '1993-03-30', ssn: nil)}
        let(:user1){FactoryBot.create(:user)}
        let(:consumer_role) { person1.consumer_role }

        let!(:params) do
          {
            :dob => '2012-10-12',
            :ssn => nil,
            :first_name => 'yo',
            :last_name => 'guy',
            :gender => 'm',
            :user_id => 20,
            :is_applying_coverage => false
          }
        end

        let(:subject) { Forms::ConsumerCandidate.new(params) }


        before do
          allow(db_person).to receive(:broker_role).and_return(nil)
          allow(search_params).to receive(:ssn).and_return('517991234')
          db_person.save!
        end

        it 'returns nil if matched person has broker agency staff role' do
          binding.irb
          allow(subject).to receive(:match_person).and_return(db_person)
          expect(subject.uniq_name_ssn_dob).to eq true
        end
      end

      context 'when there is no person with given ssn' do
        let(:person1) { Person.create!(first_name: 'Joe', last_name: 'Kramer',   dob: '1993-03-30', ssn: '517991234')}
        let(:user1){FactoryBot.create(:user)}
        let(:consumer_role) { person1.consumer_role }

        let!(:params) do
          {
            :dob => '2012-10-12',
            :ssn => '517991234',
            :first_name => 'yo',
            :last_name => 'guy',
            :gender => 'm',
            :user_id => 20,
            :is_applying_coverage => false
          }
        end

        let(:subject) { Forms::ConsumerCandidate.new(params) }


        before do
          allow(db_person).to receive(:broker_role).and_return(nil)
          allow(search_params).to receive(:ssn).and_return('517991234')
          db_person.save!
        end

        it 'returns nil if matched person has broker agency staff role' do
          binding.irb
          allow(subject).to receive(:match_person).and_return(db_person)
          expect(subject.uniq_name_ssn_dob).to eq nil
        end
      end

      context 'when person match && input params have different ssn' do
        let(:person1) { Person.create!(first_name: 'Joe', last_name: 'Kramer',   dob: '1993-03-30', ssn: '517991234')}
        let(:user1){FactoryBot.create(:user)}
        let(:consumer_role) { person1.consumer_role }

        let!(:params) do
          {
            :dob => '2012-10-12',
            :ssn => '517998787',
            :first_name => 'yo',
            :last_name => 'guy',
            :gender => 'm',
            :user_id => 20,
            :is_applying_coverage => false
          }
        end

        let(:subject) { Forms::ConsumerCandidate.new(params) }

        before do
          allow(db_person).to receive(:broker_role).and_return(nil)
          db_person.save!
        end

        it 'returns nil if matched person has broker agency staff role' do
          binding.irb
          allow(subject).to receive(:match_person).and_return(db_person)
          expect(subject.uniq_name_ssn_dob).to eq nil
        end
      end
    end
  end

  context "with a person with a first name, last name, dob and ssn" do
    let(:db_person) { Person.create!(first_name: "Jack",   last_name: "Weiner",   dob: "1943-05-14", ssn: "517994321")}

    it 'matches the person by ssn and dob' do
      expect(subject.match_person).to eq db_person
    end

    it 'matches the person ingoring case' do
      subject.first_name.upcase!
      subject.last_name.downcase!
      expect(subject.match_person).to eq db_person
    end

    it 'should pass validation when names passed with case mismatch' do
      allow(subject).to receive(:state_based_policy_satisfied?).and_return(true)

      subject.first_name.upcase!
      subject.last_name.downcase!

      expect(subject.state_based_policy_satisfied?).to be_truthy
      expect(subject.valid?).to be_truthy
    end

    it 'does not find the person if payload has a different ssn from the person' do
      subject.ssn = "888891234"
      expect(subject.match_person).to eq nil
    end
  end

  context "with a person with a first name, different last name, dob and ssn" do
    let(:described_class) do
      Forms::ConsumerCandidate.new({
                                     :dob => "1943-05-14",
                                     :ssn => "517994321",
                                     :first_name => "test",
                                     :last_name => "one",
                                     :gender => "m",
                                     :user_id => 20,
                                     :is_applying_coverage => false
                                   })
    end
    let!(:db_person) { Person.create!(first_name: "test",   last_name: "o",   dob: "1943-05-14", ssn: "517994321")}

    let(:person_match_policy) do
      double(
        settings: [
          {
            key: :ssn_present,
            item: %w[first_name last_name dob encrypted_ssn]
          },
          { key: :dob_present, item: %w[first_name last_name dob] }
        ],
        enabled?: true
      )
    end

    let(:enroll_app) { double }

    it 'should be invalid' do
      allow(described_class).to receive(:state_based_policy_satisfied?).and_return(true)
      described_class.instance_variable_set(:@configuration, {ssn_present: ["first_name", "last_name", "dob", "encrypted_ssn"]})
      allow(enroll_app).to receive(:settings).and_return(double(item: 'test'))
      allow(EnrollRegistry).to receive(:[])
        .with(:person_match_policy)
        .and_return(person_match_policy)
      allow(EnrollRegistry).to receive(:[])
        .with(:enroll_app)
        .and_return(enroll_app)
      expect(described_class.valid?).to eq false
    end
  end
end



describe Forms::ConsumerCandidate, "ssn validations" do
  let(:person) {FactoryBot.create(:person)}

  before do
    allow(Person).to receive(:where).and_return([person])
    allow(person).to receive(:user).and_return(true)
  end

  context "is applying coverage is TRUE" do
    subject do
      Forms::ConsumerCandidate.new({:dob => "2012-10-12", :ssn => "453213333", :first_name => "yo", :last_name => "guy",
                                    :gender => "m", :user_id => 20, :is_applying_coverage => "true" })
    end

    it "add errors when SSN is blank" do
      allow(subject).to receive(:ssn).and_return("")
      allow(subject).to receive(:no_ssn).and_return("0")
      subject.ssn_or_checkbox
      expect(subject.errors.messages.present?).to eq true
      expect(subject.errors[:base]).to eq ["Enter a valid social security number or select 'I don't have an SSN'"]
    end

    it "doesnt add errors when SSN is present" do
      allow(subject).to receive(:ssn).and_return("453213333")
      allow(subject).to receive(:no_ssn).and_return("0")
      expect(subject.errors.messages.present?).to eq false
    end
  end

  context "is applying coverage is FALSE" do
    subject do
      Forms::ConsumerCandidate.new({:dob => "2012-10-12", :ssn => "453213333", :first_name => "yo", :last_name => "guy",
                                    :gender => "m", :user_id => 20, :is_applying_coverage => "false" })
    end

    it "doesnt add errors when SSN is blank" do
      allow(subject).to receive(:ssn).and_return("")
      allow(subject).to receive(:no_ssn).and_return("0")
      subject.ssn_or_checkbox
      expect(subject.errors.messages.present?).to eq false
    end

    it "doesnt add errors when SSN is present" do
      allow(subject).to receive(:ssn).and_return("453213333")
      allow(subject).to receive(:no_ssn).and_return("0")
      subject.ssn_or_checkbox
      expect(subject.errors.messages.present?).to eq false
    end
  end

  context 'invalid ssn when enabled' do
    before do
      stub_const('Forms::ConsumerCandidate::SSN_REGEX', /^(?!666|000|9\d{2})\d{3}[- ]{0,1}(?!00)\d{2}[- ]{0,1}(?!0{4})\d{4}$/)
    end

    subject do
      Forms::ConsumerCandidate.new({:dob => "2012-10-12", :ssn => "999001234", :first_name => "yo", :last_name => "guy",
                                    :gender => "m", :user_id => 20, :is_applying_coverage => "true" })
    end

    it "doesnt add errors when SSN is blank" do
      subject.ssn_or_checkbox
      expect(subject.errors.messages.present?).to eq true
    end
  end

  context 'invalid ssn when disabled' do
    before do
      stub_const('Forms::ConsumerCandidate::SSN_REGEX', /\A\d{9}\z/)
    end

    subject do
      Forms::ConsumerCandidate.new({:dob => "2012-10-12", :ssn => "999001234", :first_name => "yo", :last_name => "guy",
                                    :gender => "m", :user_id => 20, :is_applying_coverage => "true" })
    end

    it "doesnt add errors when SSN is blank" do
      subject.ssn_or_checkbox
      expect(subject.errors.messages.present?).to eq false
    end
  end

  context 'when ssn is blank' do
    context "no_ssn is '1'" do
      subject do
        Forms::ConsumerCandidate.new({:dob => "2012-10-12", :ssn => nil, :no_ssn => "1", :first_name => "yo", :last_name => "guy",
                                      :gender => "m", :user_id => 20, :is_applying_coverage => "true" })
      end

      it "does not add any errors" do
        subject.ssn_or_checkbox
        expect(subject.errors).to be_empty
      end
    end

    context "no_ssn is '0'" do
      subject do
        Forms::ConsumerCandidate.new({:dob => "2012-10-12", :ssn => nil, :no_ssn => "0", :first_name => "yo", :last_name => "guy",
                                      :gender => "m", :user_id => 20, :is_applying_coverage => "true" })
      end

      it "adds an error" do
        subject.ssn_or_checkbox
        expect(subject.errors[:base]).to include("Enter a valid social security number or select 'I don't have an SSN'")
      end
    end
  end
end

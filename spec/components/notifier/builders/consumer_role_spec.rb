# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Components::Notifier::Builders::ConsumerRole', :dbclean => :after_each do

  describe "A new model instance" do
    let(:active_enrollment) { HbxEnrollment.new(id: "1") }
    let(:payload) do
      file = Rails.root.join("spec", "test_data", "notices", "proj_elig_report_aqhp_test_data.csv")
      csv = CSV.open(file, "r", :headers => true)
      data = csv.to_a

      {"consumer_role_id" => "5c61bf485f326d4e4f00000c",
       "event_object_kind" => "ConsumerRole",
       "event_object_id" => "5bcdec94eab5e76691000cec",
       "notice_params" => {"dependents" => data.select{ |m| m["dependent"].casecmp('YES').zero? }.map(&:to_hash), "uqhp_event" => "AQHP",
                           "primary_member" => data.detect{ |m| m["dependent"].casecmp('NO').zero? }.to_hash}}
    end

    let!(:person) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "a16f4029916445fcab3dbc44bb7aadd0", first_name: "Test", last_name: "Data", middle_name: "M", name_sfx: "Jr") }
    let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person, min_verification_due_date: TimeKeeper.date_of_record) }

    subject do
      consumer = Notifier::Builders::ConsumerRole.new
      consumer.payload = payload
      consumer.consumer_role = person.consumer_role
      consumer.append_data
      consumer
    end

    context "members" do
      context "magi_medicaid_members" do
        it "should return array of hashes of members information" do
          expect(subject.magi_medicaid_members.class).to eq(Array)
          expect(subject.magi_medicaid_members.first["actual_income"].length).to be > 1
        end
      end
      context "aqhp_or_non_magi_medicaid_members" do
        it "should return array of hashes of members information" do
          expect(subject.aqhp_or_non_magi_medicaid_members.class).to eq(Array)
          expect(subject.aqhp_or_non_magi_medicaid_members.first["actual_income"].length).to be > 1
        end
      end

      context "uqhp_or_non_magi_medicaid_members" do
        it "should return an array of members information" do
          expect(subject.uqhp_or_non_magi_medicaid_members.class).to eq(Array)
          expect(subject.uqhp_or_non_magi_medicaid_members.first["actual_income"].length).to be > 1
        end
      end
    end

    context "Model attributes" do
      it "should return a due date" do
        expect(subject.due_date.class).to eq(String)
      end

      it "should return dc_resident status" do
        expect(subject.dc_resident).to eq("Yes")
      end

      it "should return expected_income_for_coverage_year" do
        expect(subject.expected_income_for_coverage_year.length).to be > 1
      end

      it "should return federal_tax_filing_status" do
        expect(subject.federal_tax_filing_status).to eq("Tax Filer")
      end

      it "should return notice date" do
        expect(subject.notice_date).to include(Date.today.year.to_s)
      end

      it "should return citizenship" do
        expect(subject.citizenship).to eq("US Citizen")
      end

      it "should return tax_household_size" do
        expect(subject.tax_household_size).to be > 1
      end

      context 'primary_member' do
        it "should return primary member" do
          expect(subject.primary_member.class).to eq(Notifier::MergeDataModels::Dependent)
        end
      end

      context 'first name' do
        it 'should get first name from person object for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.first_name).to eq(person.first_name)
        end

        it 'should get first name from payload for projected aqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.first_name).to eq(payload["notice_params"]["primary_member"]["first_name"])
        end
      end

      context 'last name' do
        it 'should get last name from person object for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.last_name).to eq(person.last_name)
        end

        it 'should get last name from payload for projected aqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.last_name).to eq(payload["notice_params"]["primary_member"]["last_name"])
        end
      end

      it "should have full name from person object" do
        expect(subject.primary_fullname).to eq(person.full_name)
      end

      it "should have aptc from payload" do
        expect(subject.aptc).to eq(ActionController::Base.helpers.number_to_currency(payload["notice_params"]["primary_member"]["aptc"]))
      end

      it "should have incarcerated from payload" do
        expect(subject.incarcerated).to eq("No")
      end

      context 'age' do
        it 'should get age from person object for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.age).to eq(person.age_on(TimeKeeper.date_of_record))
        end

        it 'should get age from payload for projected aqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.age).to eq(subject.age_of_aqhp_person(TimeKeeper.date_of_record, Date.strptime(payload['notice_params']['primary_member']['dob'],"%m/%d/%Y")))
        end
      end

      context 'irs_consent' do
        it 'should return false for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.irs_consent).to eq(false)
        end

        it 'should get age from payload for projected aqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.irs_consent).to eq(payload['notice_params']['primary_member']['irs_consent'].casecmp('YES').zero?)
        end
      end

      context 'magi_medicaid' do
        it "should receive return false if uqhp_notice?" do
          expect(subject.magi_medicaid).to eq(false)
        end

        it "should return true if payload says Yes" do
          allow(subject).to receive(:uqhp_notice?).and_return(nil)
          allow(subject).to receive(:payload).and_return({'notice_params' => {'primary_member' => {'magi_medicaid' => "YES"}}})
          expect(subject.magi_medicaid).to eq(true)
        end
      end

      context "non_magi_medicaid" do
        it "should receive return false if uqhp_notice?" do
          expect(subject.non_magi_medicaid).to eq(false)
        end

        it "should return true if payload says Yes" do
          allow(subject).to receive(:uqhp_notice?).and_return(nil)
          allow(subject).to receive(:payload).and_return({'notice_params' => {'primary_member' => {'non_magi_medicaid' => "YES"}}})
          expect(subject.non_magi_medicaid).to eq(true)
        end
      end
    end

    context "Model dependent attributes" do
      it "should have dependent filer type attributes" do
        expect(subject.dependents.first['federal_tax_filing_status']).to eq('Tax Filer')
        expect(subject.dependents.last['federal_tax_filing_status']).to eq('Married Filing Separately')
        expect(subject.dependents.count).to eq(3)
      end

      it "should have dependent citizen_status attributes" do
        expect(subject.citizen_status("US")).to eq('US Citizen')
        expect(subject.dependents.count).to eq(3)
      end

      it "should have magi_medicaid_members_present" do
        expect(subject.magi_medicaid_members_present).to eq(false)
      end

      it "should have aqhp_or_non_magi_medicaid_members_present" do
        expect(subject.aqhp_or_non_magi_medicaid_members_present).to eq(true)
      end

      it "should have uqhp_or_non_magi_medicaid_members_present" do
        expect(subject.uqhp_or_non_magi_medicaid_members_present).to eq(false)
      end
    end

    context "Conditional attributes" do
      it "should be aqhp_eligible?" do
        expect(subject.aqhp_eligible?).to eq(true)
      end

      it "should return falsey if not totally_ineligible?" do
        expect(subject.totally_ineligible?).to be_falsey
      end

      it "should be uqhp_eligible?" do
        expect(subject.uqhp_eligible?).to eq(false)
      end

      it "should have irs_consent?" do
        expect(subject.irs_consent?).to eq(false)
      end

      it "should have magi_medicaid?" do
        expect(subject.magi_medicaid?).to eq(false)
      end

      it "should have non_magi_medicaid?" do
        expect(subject.non_magi_medicaid?).to eq(false)
      end

      it "should have csr?" do
        expect(subject.csr?).to eq(true)
      end

      it "should have aptc_amount_available?" do
        expect(subject.aptc_amount_available?).to eq(true)
      end

      it "should have csr_is_73?" do
        expect(subject.csr_is_73?).to eq(true)
      end

      it "should have csr_is_100?" do
        expect(subject.csr_is_100?).to eq(false)
      end

      it "should return false if APTC amount is greater than 0" do
        expect(subject.aptc_is_zero?).to eq(false)
      end

      it "should return true if APTC amount is $0" do
        allow(subject).to receive(:aptc).and_return "$0"
        expect(subject.aptc_is_zero?).to eq(true)
      end

      context 'aqhp_event_and_irs_consent_no?' do
        it 'should always return false for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(true)
          expect(subject.aqhp_event_and_irs_consent_no?).to eq(false)
        end

        it 'should return  for projected uqhp notice' do
          allow(subject).to receive(:uqhp_notice?).and_return(false)
          expect(subject.aqhp_event_and_irs_consent_no?).to eq(true)
        end
      end
    end

    context "Model Open enrollment start and end date attributes" do
      it "should have open enrollment start date" do
        expect(subject.ivl_oe_start_date). to eq(Settings.aca
                                                .individual_market
                                                .upcoming_open_enrollment
                                                .start_on.strftime('%B %d, %Y'))
      end

      it "should have open enrollment end date" do
        expect(subject.ivl_oe_end_date). to eq(Settings.aca
                                              .individual_market
                                              .upcoming_open_enrollment
                                              .end_on.strftime('%B %d, %Y'))
      end
    end

    describe 'consumer_role and address' do
      let(:consumer) {subject.consumer_role.person}
      let(:address) {consumer.mailing_address}

      context "Model address attributes" do
        it "should have address " do
          expect(address.address_1.present?)
        end
      end
    end

    context "loops" do
      it "should return blank array if no households present" do
        expect(subject.tax_households).to_not be(nil)
      end

      it "should return nil if no renewing health enrollments present" do
        expect(subject.renewing_health_enrollments).to eq([])
      end

      it "should return a nil if no renewing health enrollments present" do
        # TODO: Notice is undefined in components/notifier/app/models/notifier/builders/consumer_role.rb
        expect(subject.renewing_health_enrollments).to eq([])
      end

      it "should return nil if no renewing dental enrollments present" do
        expect(subject.renewing_dental_enrollments).to eq([])
      end

      it "should return a nil if no renewing dental enrollment present" do
        expect(subject.renewing_dental_enrollments).to eq([])
      end

      it "should return nil if no current health enrollments present" do
        expect(subject.current_health_enrollments).to eq([])
      end

      it "should return nil if no current dental enrollments present" do
        expect(subject.current_dental_enrollments).to eq([])
      end

      it "should return nil if renewing health products present" do
        expect(subject.renewing_health_products).to eq([])
      end

      it "should return nil if no renewing dental products present" do
        expect(subject.renewing_dental_products).to eq([])
      end

      it "should return nil if no current health products present" do
        expect(subject.current_health_products).to eq([])
      end

      it "should return nil if no current dental products present" do
        expect(subject.current_dental_products).to eq([])
      end

      context "#same_health_product" do
        context "current and renewing health products present" do
          let(:current_product1) { double(id: 1, hios_base_id: 2, renewal_product: renewing_product1) }
          let(:renewing_product1) { double(id: 1, hios_base_id: 2) }

          it "should return true if individual is enrolled into same health product" do
            allow(subject).to receive(:current_health_products).and_return([current_product1])
            allow(subject).to receive(:renewing_health_products).and_return([renewing_product1])
            expect(subject.same_health_product).to eq(true)
          end
        end

        it "should return false if no renewal_dental_product_ids && passive_renewal_dental_product_ids" do
          allow(subject).to receive(:current_health_products).and_return([])
          allow(subject).to receive(:renewing_health_products).and_return([])
          expect(subject.same_health_product).to eq(false)
        end
      end

      context "#same_dental_product" do
        context "current and renewing dental products present" do
          let(:current_product1) { double(id: 1, hios_base_id: 2, renewal_product: renewing_product1) }
          let(:renewing_product1) { double(id: 1, hios_base_id: 2) }

          it "should return true if individual is enrolled into same dental product" do
            allow(subject).to receive(:current_dental_products).and_return([current_product1])
            allow(subject).to receive(:renewing_dental_products).and_return([renewing_product1])
            expect(subject.same_dental_product).to eq(true)
          end
        end

        it "should return false if no renewal_dental_product_ids && passive_renewal_dental_product_ids" do
          allow(subject).to receive(:current_dental_products).and_return([])
          allow(subject).to receive(:renewing_dental_products).and_return([])
          expect(subject.same_dental_product).to eq(false)
        end
      end

      it "should return a hash of family member info ineligible family members present" do
        expect(subject.ineligible_applicants.length).to be > 0
      end
    end
  end

  describe "A uqhp_eligible in aqhp event" do
    let(:payload2) {
      file = Rails.root.join("spec", "test_data", "notices", "proj_elig_report_aqhp_test_data.csv")
      csv = CSV.open(file, "r", :headers => true)
      data = csv.to_a

      {
        "consumer_role_id" => "5c61bf485f326d4e4f0000c",
        "event_object_kind" =>  "ConsumerRole",
        "event_object_id" => "5bcdec94eab5e76691000cec",
        "notice_params" => {
          "uqhp_event" => "AQHP",
          "primary_member" => data.select{ |m| m["dependent"].casecmp('NO').zero? && m["uqhp_eligible"].casecmp('YES').zero?}.first.to_hash
        }
      }
    }

    let!(:person2) { FactoryBot.create(:person, :with_consumer_role, hbx_id: "a16f4029916445fcab3dbc44bb7aadd1", first_name: "Test2", last_name: "Data2") }
    let!(:family2) { FactoryBot.create(:family, :with_primary_family_member, person: person2) }

    let(:subject2) {
      consumer = Notifier::Builders::ConsumerRole.new
      consumer.payload = payload2
      consumer.consumer_role = person2.consumer_role
      consumer
    }

    context "uqhp_eligible in aqhp_event" do
      it "should be uqhp_eligible in aqhp event" do
        allow(subject2).to receive(:uqhp_notice?).and_return(false)
        expect(subject2.uqhp_eligible).to eq(true)
      end
    end
  end
end

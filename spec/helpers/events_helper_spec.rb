require "rails_helper"

class EventsHelperSlug
  include EventsHelper
end

describe EventsHelper, "given an address_kind" do

  subject { EventsHelperSlug.new }

  describe "when the address kind is 'primary'" do
    it "should return address kind as 'work'" do
      expect(subject.office_location_address_kind("primary")).to eq "work"
    end
  end

  describe "when the address kind is 'branch'" do
    it "should return address kind as 'work'" do
      expect(subject.office_location_address_kind("branch")).to eq "work"
    end
  end

  describe "when the address kind is anything else" do
    it "should return address kind as the same" do
      expect(subject.office_location_address_kind("slkdjfkld")).to eq "slkdjfkld"
    end
  end

  describe "is_initial_employer?" do

    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile1){ FactoryGirl.create(:employer_profile, plan_years: [active_plan_year]) }
    let(:employer_profile2){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year]) }

    it "should return true if employer is initial" do
      expect(subject.is_initial_employer?(employer_profile1)).to eq true
    end

    it "should return false if employer is not initial" do
      expect(subject.is_initial_employer?(employer_profile2)).to eq false
    end
    it "should return false if employer is not initial" do
      employer_profile1.profile_source='conversion'
      employer_profile1.save
      expect(subject.is_initial_employer?(employer_profile1)).to eq false
    end
  end


  describe "is_renewal_employer?" do
    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year,active_plan_year]) }

    it "should return true if employer is renewal_employer" do
      expect(subject.is_renewal_employer?(employer_profile)).to eq true
    end

    it "should return false if employer is not renewal_employer" do
      employer_profile.profile_source='conversion'
      employer_profile.save
      expect(subject.is_renewal_employer?(employer_profile)).to eq false
    end
  end

  describe "is_conversion_employer??" do
    let(:active_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year, aasm_state: "renewing_enrolling") }
    let(:employer_profile){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year,active_plan_year]) }

    it "should return false if employer is not conversion_employer" do
      expect(subject.is_conversion_employer?(employer_profile)).to eq false
    end

    it "should return true if employer is conversion_employer" do
      employer_profile.profile_source='conversion'
      employer_profile.save
      expect(subject.is_conversion_employer?(employer_profile)).to eq true
    end
  end

  describe "is_renewal_or_conversion_employer?" do

    let(:employer_profile){ FactoryGirl.create(:employer_profile) }

    it "should return true if employer is renewal employer" do
      allow(subject).to receive(:is_renewal_employer?).with(employer_profile).and_return true
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq true
    end

    it "should return fasle if employer is not renewal employer" do
      allow(subject).to receive(:is_renewal_employer?).with(employer_profile).and_return false
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq false
    end
    it "should return true if employer is conversion employer" do
      allow(subject).to receive(:is_conversion_employer?).with(employer_profile).and_return true
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq true
    end

    it "should return false if employer is not conversion employer" do
      allow(subject).to receive(:is_conversion_employer?).with(employer_profile).and_return false
      expect(subject.is_renewal_or_conversion_employer?(employer_profile)).to eq false
    end
  end

  describe "employer_plan_years" do

    let(:active_plan_year){ FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.at_beginning_of_month, aasm_state: "active") }
    let(:renewing_plan_year){ FactoryGirl.build(:plan_year,start_on: TimeKeeper.date_of_record.at_beginning_of_month.next_month,aasm_state: "renewing_enrolling") }
    let(:employer_profile2){ FactoryGirl.create(:employer_profile, plan_years: [renewing_plan_year,active_plan_year]) }

    let(:active_plan_year){ FactoryGirl.build(:plan_year, start_on: TimeKeeper.date_of_record.at_beginning_of_month, aasm_state: "active") }
    let(:employer_profile1){ FactoryGirl.create(:employer_profile, plan_years: [active_plan_year]) }

    context "initial employer" do

      it "should return active plan year" do
        expect(subject.employer_plan_years(employer_profile1)).to eq [active_plan_year]
      end

    end

    context "renewal employer" do

      context "day is after 15th of this month" do

        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(TimeKeeper.date_of_record.at_beginning_of_month+ 20.days)
        end

        it "should returna active and renewal plan year" do
          expect(subject.employer_plan_years(employer_profile2)).to eq [renewing_plan_year,active_plan_year]
        end
      end

      context "day is on or before 15th of this month" do

        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(TimeKeeper.date_of_record.at_beginning_of_month)
        end

        it "should return active plan year" do
          expect(subject.employer_plan_years(employer_profile2)).to eq [active_plan_year]
        end
      end
    end
  end
end

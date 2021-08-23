require 'rails_helper'

RSpec.describe HbxProfile, :type => :model do
  let(:organization) { FactoryBot.create(:organization) }

  let(:cms_id)  { "DC0" }
  let(:us_state_abbreviation)  { "DC" }
  let(:markets) { %w(shop unassisted_individual assisted_individual non_aca) }
  let(:valid_params) {
    {
      organization: organization,
      cms_id: cms_id,
      us_state_abbreviation: us_state_abbreviation
    }
  }

  context ".new" do
    context "with no organization" do
      let(:params) {valid_params.except(:organization)}

      it "should raise" do
        expect{HbxProfile.create(**params)}.to raise_error(Mongoid::Errors::NoParent)
      end
    end

    context "with all required data" do
      let(:params)        { valid_params }
      let(:hbx_profile)   { HbxProfile.new(**params) }
      before :all do
        @hp_count = HbxProfile.all.size
      end

      it "should save" do
        expect(hbx_profile.save).to be_truthy
      end

      context "and it is saved" do
        let!(:hbx_profile) { FactoryBot.create :hbx_profile }

        it "should return all HBX instances" do
          expect(HbxProfile.all.size).to eq @hp_count + 2
        end

        it "should be findable by ID" do
          expect(HbxProfile.find(hbx_profile._id)).to eq hbx_profile
        end
      end

      context ".search_random", dbclean: :after_each do
        let(:broker_agency_profile1) { FactoryBot.create(:broker_agency_profile)}
        let(:broker_agency_profile2) { FactoryBot.create(:broker_agency_profile)}

        before do
          DatabaseCleaner.clean
          broker_agency_profile1.organization.update_attributes(legal_name: "legal yo1")
          broker_agency_profile2.organization.update_attributes(legal_name: "legal yo2")
        end

        it "should return all the broker agencies profiles" do
          expect(HbxProfile.search_random(nil).size).to eq 2
          expect(HbxProfile.search_random(nil).first.class).to eq BrokerAgencyProfile
        end

        it "should return the  searched broker agency instances" do
          expect(HbxProfile.search_random(broker_agency_profile1.organization.legal_name).size).to eq 1
          expect(HbxProfile.search_random(broker_agency_profile1.organization.legal_name).first.class).to eq BrokerAgencyProfile
        end
      end
    end
  end

  describe 'bcp_by_oe_dates' do
    let(:current_year) { TimeKeeper.date_of_record.year }
    let!(:hbx_profile) do
      FactoryBot.create(:hbx_profile,
                        :normal_ivl_open_enrollment,
                        us_state_abbreviation: EnrollRegistry[:enroll_app].setting(:state_abbreviation).item,
                        cms_id: "#{EnrollRegistry[:enroll_app].setting(:state_abbreviation).item.upcase}0")
    end

    context 'system date within OE' do
      context 'after start of OE and end of current year i.e usually b/w 11/1, 12/31' do
        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 11, 5))
        end

        it 'should return benefit_coverage_period with start_on year as current_year + 1' do
          expect(HbxProfile.bcp_by_oe_dates.start_on.year).to eq(current_year.next)
        end
      end

      context 'after start of prospective year and end of OE end on i.e usually b/w 1/1, 1/31' do
        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year.next, 1, 5))
        end

        it 'should return benefit_coverage_period with start_on year as current_year + 1' do
          expect(HbxProfile.bcp_by_oe_dates.start_on.year).to eq(current_year.next)
        end
      end
    end

    context 'system date outside OE' do
      context 'before start of OE start i.e usually before 11/1' do
        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year, 9, 5))
        end

        it 'should return benefit_coverage_period with start_on year same as current_year' do
          expect(Family.application_applicable_year).to eq(current_year)
        end
      end

      context 'after end of OE i.e usually after 1/31' do
        before do
          allow(TimeKeeper).to receive(:date_of_record).and_return(Date.new(current_year.next, 4, 5))
        end

        it 'should return benefit_coverage_period with start_on year as current_year + 1' do
          expect(Family.application_applicable_year).to eq(current_year.next)
        end
      end
    end
  end
end

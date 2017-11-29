require 'rails_helper'
Rake.application.rake_require "tasks/migrations/load_rating_factors"

RSpec.shared_examples "a rate factor" do |attributes|
  attributes.each do |attribute, value|
    it "should return #{value} from ##{attribute}" do
      expect(subject.send(attribute)).to eq(value)
    end
  end
end

RSpec.describe 'Load Rate Factors Task', :type => :task, :dbclean => :after_each  do
  before do
    SicCodeRatingFactorSet.destroy_all
    EmployerGroupSizeRatingFactorSet.destroy_all
    EmployerParticipationRateRatingFactorSet.destroy_all
    CompositeRatingTierFactorSet.destroy_all
  end
  context "rate_reference:load_rating_factors" do
    before :each do
      ['82569','88806','34484','73331'].each do |hios_id|
        carrier_profile = FactoryGirl.create(:carrier_profile, issuer_hios_ids: [hios_id])
      end

      invoke_task
    end

    context "it creates SicCodeRatingFactorSet correctly" do
      subject { SicCodeRatingFactorSet.first }
      it_should_behave_like "a rate factor", {    active_year: 2017,
                                                  default_factor_value: 1.0
                                              }

      it 'creates sic code factor sets' do
        expect(SicCodeRatingFactorSet.count).to be(4)
      end

      it "creates sic factor entries" do
        expect(subject.rating_factor_entries.count).to be(1005)
      end

      it "assigns the correct factor key and value" do
        expect(subject.rating_factor_entries.first.factor_key).to eq('0111')
        expect(subject.rating_factor_entries.first.factor_value).to be(1.0)
      end
    end

    context "it creates EmployerGroupSizeRatingFactorSet correctly" do
      subject do
        carrier_profile = Organization.where(
          "carrier_profile.issuer_hios_ids" => '34484'
        ).first.carrier_profile
        EmployerGroupSizeRatingFactorSet.where(carrier_profile_id: carrier_profile.id).first
      end

      it_should_behave_like "a rate factor", {    active_year: 2017,
                                                  default_factor_value: 1.0
                                              }
      it 'creates employer group size codes' do
        expect(EmployerGroupSizeRatingFactorSet.count).to be(4)
      end

      it 'creates employer group size factor entries' do
        expect(subject.rating_factor_entries.count).to be(50)
      end

      it "assigns the correct factor key and value" do
        first_entry = subject.rating_factor_entries.detect { |rfe| rfe.factor_key == '1' }
        last_entry = subject.rating_factor_entries.detect { |rfe| rfe.factor_key == '50' }
        expect(first_entry.factor_value).to be(1.101)
        expect(last_entry.factor_value).to be(1.070)
      end
    end

    context "it creates EmployerParticipationRateRatingFactorSet correctly" do
      subject { EmployerParticipationRateRatingFactorSet.first }
      it_should_behave_like "a rate factor", {    active_year: 2017,
                                                  default_factor_value: 1.0
                                              }
      it 'creates employer participation rate codes' do
        expect(EmployerParticipationRateRatingFactorSet.count).to be(4)
      end

      it 'creates employer participation rate factor entries' do
        expect(subject.rating_factor_entries.count).to be(100)
      end

      it "assigns the correct factor key and value" do
        expect(subject.rating_factor_entries.first.factor_key).to eq('1')
        expect(subject.rating_factor_entries.first.factor_value).to be(1.0)
        expect(subject.rating_factor_entries.last.factor_key).to eq('100')

      end
    end

    context "it creates CompositeRatingTierFactorSet correctly" do
      subject { CompositeRatingTierFactorSet.first }
      it_should_behave_like "a rate factor", {    active_year: 2017,
                                                  default_factor_value: 1.0
                                              }
      it 'creates composite rating codes' do
        expect(CompositeRatingTierFactorSet.count).to be(4)
      end

      it 'creates composite tier factor entries' do
        expect(subject.rating_factor_entries.count).to be(4)
      end

      it "assigns the correct factor key and value" do
        expect(subject.rating_factor_entries.first.factor_key).to eq('employee_only')
        expect(subject.rating_factor_entries.first.factor_value).to be(1.0)
        expect(subject.rating_factor_entries.second.factor_key).to eq('employee_and_spouse')
        expect(subject.rating_factor_entries.second.factor_value).to be(2.0)
      end
    end
    private

    def invoke_task
      Rake::Task["load_rating_factors:update_factor_sets"].execute({:file_name => "#{Rails.root}/spec/test_data/plan_data/rate_factors/2017/SHOP_RateFactors_CY2017_SOFT_DRAFT.xlsx"})
    end
  end
end

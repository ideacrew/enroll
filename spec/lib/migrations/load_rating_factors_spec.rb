require 'rails_helper'

RSpec.shared_examples "a rate factor" do |attributes|
  attributes.each do |attribute, value|
    it "should return #{value} from ##{attribute}" do
      expect(subject.send(attribute)).to eq(value)
    end
  end
end

RSpec.describe 'Load Rate Factors Task', :type => :task do

  context "rate_reference:load_rating_factors" do
    before :all do
      ['82569','88806','34484','73331'].each do |hios_id|
        carrier_profile = FactoryGirl.create(:carrier_profile, issuer_hios_ids: [hios_id])
      end
      Rake.application.rake_require "tasks/migrations/load_rating_factors"
      Rake::Task.define_task(:environment)

      invoke_task
    end

    pending "it creates SicCodeRatingFactorSet correctly" do
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

    pending "it creates EmployerGroupSizeRatingFactorSet correctly" do
      subject { EmployerGroupSizeRatingFactorSet.first }
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
        expect(subject.rating_factor_entries.first.factor_key).to eq('1.0')
        expect(subject.rating_factor_entries.first.factor_value).to be(1.0)
      end
    end

    pending "it creates EmployerParticipationRateRatingFactorSet correctly" do
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
        expect(subject.rating_factor_entries.first.factor_key).to eq('0.01')
        expect(subject.rating_factor_entries.first.factor_value).to be(1.0)
      end
    end

    pending "it creates CompositeRatingTierFactorSet correctly" do
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
        expect(subject.rating_factor_entries.first.factor_key).to eq('Employee')
        expect(subject.rating_factor_entries.first.factor_value).to be(1.0)
      end
    end
    private

    def invoke_task
      Rake.application.invoke_task("load_rating_factors:update_factor_sets[SHOP_RateFactors_CY2017_SOFT_DRAFT.xlsx]")

      Rake::Task["load_rating_factors:update_factor_sets"].invoke
    end
  end
end

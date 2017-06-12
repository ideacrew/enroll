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
      Rake.application.rake_require "tasks/migrations/load_rating_factors"
      Rake::Task.define_task(:environment)
    end

    before :context do
      invoke_task
    end

    context "it creates SicCodeRatingFactorSet correctly" do
      it 'ran' do
        pp 'hey'
      end
    end

    private

    def invoke_task
      Rake.application.invoke_task("load_rating_factors:update_factor_sets[SHOP_RateFactors_CY2017_SOFT_DRAFT.xlsx]")

      Rake::Task["load_rating_factors:update_factor_sets"].invoke
    end
  end
end

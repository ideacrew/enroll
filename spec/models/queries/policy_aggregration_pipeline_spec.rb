require "rails_helper"

require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

describe Queries::PolicyAggregationPipeline, "Policy Queries", dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application"
  include_context "setup renewal application"
  include_context "setup employees with benefits"

  let(:instance) { Queries::PolicyAggregationPipeline.new }
  let(:aggregation) { [
                    { "$unwind" => "$households"},
                    { "$unwind" => "$households.hbx_enrollments"},
                    { "$match" => {"households.hbx_enrollments" => {"$ne" => nil}}},
                    { "$match" => {"households.hbx_enrollments.hbx_enrollment_members" => {"$ne" => nil}, "households.hbx_enrollments.external_enrollment" => {"$ne" => true}}}
                    ] }
   let(:step) { {'rspec' => "test"}}
   let(:open_enrollment_query) {{
                                "$match" => {
                                      "households.hbx_enrollments.enrollment_kind" => "open_enrollment" }
                                }}
  let(:hbx_id_list) {[abc_organization.hbx_id]}

  context 'aggregation methods' do

    it 'base_pipeline' do
      expect(instance.pipeline).to eq (aggregation)
      expect(instance.base_pipeline).to eq (aggregation)
    end

    it 'add' do
      value = instance.add(step)
      expect(value.length).to eq aggregation.length + 1
    end

    it 'open_enrollment' do
      value = instance.open_enrollment
      expect(value.pipeline[4]).to eq (open_enrollment_query)
    end

    it 'filter_to_employers_hbx_ids' do
      expect(instance.pipeline.count).to be 4
      instance.filter_to_employers_hbx_ids(hbx_id_list)
      expect(instance.pipeline.count).to be 5
    end

    it 'exclude_employers_by_hbx_ids' do
      expect(instance.pipeline.count).to be 4
      instance.exclude_employers_by_hbx_ids(hbx_id_list)
      expect(instance.pipeline.count).to be 5
    end
  end
end




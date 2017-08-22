require 'rails_helper'

class FakesController < ApplicationController
  include DataTablesSearch
end

describe FakesController, dbclean: :after_each do

  describe "#sorted_families" do
    before do
      @dt_query = Struct.new(:draw, :skip, :take, :search_string).new(1, 0, 10, nil)
      @query = ::Queries::VerificationsDatatableQuery.new(@dt_query, nil)
    end

    it "should return a mongoid criteria" do
      expect(subject.sorted_families(nil, @dt_query, @query).class).to eq Mongoid::Criteria
    end

    it "should return families queried collection" do
      unverified_families = Family.by_enrollment_individual_market.where(:'households.hbx_enrollments.aasm_state' => "enrolled_contingent").skip(0).limit(10)
      expect(subject.sorted_families(nil, @dt_query, @query)).to eq unverified_families
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

describe Queries::FamilyDatatableQuery, "Filter Scopes for families Index", dbclean: :after_each do
  it "filters: by_enrollment_individual_market" do
    fdq = Queries::FamilyDatatableQuery.new({"families" => "by_enrollment_individual_market"})
    expect(fdq.build_scope.selector).to eq({"$and" => [{"_id" => {"$in" => []}}], "is_active" => true,
                                            "_id" => {"$in" => HbxEnrollment.where(:aasm_state => {"$in" => ["coverage_selected", "transmitted_to_carrier", "coverage_enrolled", "coverage_termination_pending", "unverified"]}).pluck(:family_id)}})
  end

  it "filters: by_enrollment_shop_market" do
    fdq = Queries::FamilyDatatableQuery.new({"families" => "by_enrollment_shop_market"})
    expect(fdq.build_scope.selector).to eq({"$and" => [{"_id" => {"$in" => []}}], "is_active" => true,
                                            "_id" => {"$in" => HbxEnrollment.where(:aasm_state => {"$in" => ["coverage_selected", "transmitted_to_carrier", "coverage_enrolled", "coverage_termination_pending", "unverified"]}).pluck(:family_id)}})
  end

  it "filters: non_enrolled" do
    fdq = Queries::FamilyDatatableQuery.new({"families" => "non_enrolled"})
    expect(fdq.build_scope.selector).to eq({"is_active" => true,
                                            "_id" => {"$in" => HbxEnrollment.where(:aasm_state => {"$nin" => ["coverage_selected", "transmitted_to_carrier", "coverage_enrolled", "coverage_termination_pending", "unverified"]}).pluck(:family_id)}})
  end

  it "filters: by_enrollment_renewing" do
    fdq = Queries::FamilyDatatableQuery.new({"employer_options" => "by_enrollment_renewing"})
    expect(fdq.build_scope.selector).to eq({"is_active" => true, "_id" => {"$in" => HbxEnrollment.where(:aasm_state => {"$in" => HbxEnrollment::RENEWAL_STATUSES}).pluck(:family_id)}})
  end

  it "filters: sep_eligible" do
    fdq = Queries::FamilyDatatableQuery.new({"employer_options" => "sep_eligible"})
    expect(fdq.build_scope.selector).to eq({"is_active" => true, "active_seps.count" => {"$gt" => 0}})
  end

  it "filters: coverage_waived" do
    fdq = Queries::FamilyDatatableQuery.new({"employer_options" => "coverage_waived"})
    expect(fdq.build_scope.selector).to eq({"is_active" => true, "_id" => {"$in" => HbxEnrollment.where(:aasm_state => {"$in" => HbxEnrollment::WAIVED_STATUSES}).pluck(:family_id)}})
  end

  it "filters: all_assistance_receiving" do
    fdq = Queries::FamilyDatatableQuery.new({"individual_options" => "all_assistance_receiving"})
    expect(fdq.build_scope.selector).to eq({"is_active" => true, "households.tax_households.eligibility_determinations.max_aptc.cents" => {"$gt" => 0}})
  end

  it "filters: all_unassisted" do
    fdq = Queries::FamilyDatatableQuery.new({"individual_options" => "all_unassisted"})
    expect(fdq.build_scope.selector).to eq({"is_active" => true, "households.tax_households.eligibility_determinations" => {"$exists" => false}})
  end
end

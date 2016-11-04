require 'rails_helper'

describe Queries::FamilyDatatableQuery, "Filter Scopes for families Index" do
  let(:family) {Family.new}
  let(:attributes) { {"individual_options" => "all_assistance_receiving"} }
  let(:fdq) {Queries::FamilyDatatableQuery.new(attributes)}
  
  it "filters: all_assistance_receiving" do
    expect(fdq.build_scope.class).to eq Mongoid::Criteria
    expect(fdq.build_scope.selector).to eq ({"households.tax_households.eligibility_determinations.max_aptc.cents"=>{"$gt"=>0}})
  end

end
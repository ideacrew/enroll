require 'rails_helper'

describe "shared/_comparison.html.erb" do

  random_value = rand(999_999_999)
  let(:mock_person){ instance_double("Person",full_name: "John Doe:#{random_value}", age_on: 21, dob: double("dob"))}
  let(:mock_member){ instance_double("HbxEnrollmentMember",primary_relationship: "self:#{random_value}", person: mock_person)}
  let(:mock_organization){ instance_double("Oganization", hbx_id: "3241251524", legal_name: "ACME Agency", dba: "Acme", fein: "034267010")}
  let(:mock_carrier_profile) { instance_double("CarrierProfile", :dba => "a carrier name", :legal_name => "name", :organization => mock_organization) }
  let(:mock_hbx_enrollment) { instance_double("HbxEnrollment", :hbx_enrollment_members => [mock_member, mock_member], :id => "3241251524") }
  let(:mock_plan) { double("Plan",
      :name => "A Plan Name",
      :carrier_profile_id => "a carrier profile id",
      :carrier_profile => mock_carrier_profile,
      :metal_level => "Silver",
      :plan_type => "A plan type",
      :nationwide => true,
      :deductible => 0,
      :total_premium => 100,
      :total_employer_contribution => 20,
      :total_employee_cost => 30,
      :id => "1234234234",
      :sbc_file => "THE SBC FILE.PDF"
      ) }
  let(:mock_qhp){instance_double("Products::Qhp", :qhp_benefits => [], :plan => mock_plan, :plan_marketing_name=> "plan name")}
  let(:mock_qhps) {[mock_qhp]}
  let(:sbc_document) { double("SbcDocument", identifier: "download#abc") }

  before :each do
    Caches::MongoidCache.release(CarrierProfile)
    allow(mock_plan).to receive(:sbc_document).and_return(sbc_document)
    allow(mock_qhp).to receive("[]").with(:total_employee_cost).and_return(30)
    assign(:visit_types, [])
    assign :plan, mock_plan
    assign :hbx_enrollment, mock_hbx_enrollment
    render "shared/comparison", :qhps => mock_qhps
  end

  it "should have a link to download the sbc pdf" do
    expect(rendered).to have_selector("a", text: /Summary of Benefits and Coverage/)
  end

  it "should contain some readable text" do
    ["$30.00", "Plan Name", "Nationwide", "ACME Agency"].each do |t|
      expect(rendered).to have_content(t)
    end
  end

  it "should have print area" do
    expect(rendered).to have_selector('div#printArea')
  end

  it "should have download link" do
    expect(rendered).to have_selector('a', text: 'Download')
  end

  it "should not have Out of Network text" do
    expect(rendered).to_not have_selector('th', text: 'Out of Network')
  end


  it "should have print link" do
    expect(rendered).to have_selector('button', text: 'Print')
  end
end

require 'rails_helper'

RSpec.describe "insured/families/_enrollment.html.erb" do
  context "without consumer_role" do
    let(:mock_organization){ instance_double("Oganization", hbx_id: "3241251524", legal_name: "ACME Agency", dba: "Acme", fein: "034267010")}
    let(:mock_carrier_profile) { instance_double("CarrierProfile", :dba => "a carrier name", :legal_name => "name", :organization => mock_organization) }
    let(:plan) { double("Plan",
      :name => "A Plan Name",
      :carrier_profile_id => "a carrier profile id",
      :carrier_profile => mock_carrier_profile,
      :metal_level => "Silver",
      :active_year => 2015,
      :coverage_kind => "health",
      :hios_id => "19393939399",
      :plan_type => "A plan type",
      :nationwide => true,
      :deductible => 0,
      :total_premium => 100,
      :total_employer_contribution => 20,
      :total_employee_cost => 30,
      :id => "1234234234",
      :sbc_document => Document.new({title: 'sbc_file_name', subject: "SBC",
                      :identifier=>'urn:openhbx:terms:v1:file_storage:s3:bucket:dchbx-enroll-sbc-local#7816ce0f-a138-42d5-89c5-25c5a3408b82'})
    ) }
    let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10), consumer_role: nil, employee_role: nil, status_step: 2, applied_aptc_amount: 23.00)}

    before :each do
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment
    end

    it "should open the sbc pdf" do
      expect(rendered).to have_selector("a[href='#{root_path + "document/download/dchbx-enroll-sbc-local/7816ce0f-a138-42d5-89c5-25c5a3408b82?content_type=application/pdf&filename=APlanName.pdf&disposition=inline"}']")
    end

    it "should display the title" do
      expect(rendered).to match /#{plan.active_year} #{plan.coverage_kind} Coverage/
      expect(rendered).to match /DC Healthlink/
    end

    it "should display the link of view detail" do
      expect(rendered).to have_selector("a[href='/products/plans/summary?active_year=#{plan.active_year}&hbx_enrollment_id=#{hbx_enrollment.id}&source=account&standard_component_id=#{plan.hios_id}']", text: "View Details")
    end

    it "should display the effective date" do
      expect(rendered).to have_selector('label', text: 'Effective date:')
      expect(rendered).to have_selector('strong', text: '08/10/2015')
    end
  end

  context "with consumer_role" do
    let(:plan) {FactoryGirl.build(:plan)}
    let(:hbx_enrollment) {double(plan: plan, id: "12345", total_premium: 200, kind: 'individual',
                                 covered_members_first_names: ["name"], can_complete_shopping?: false,
                                 may_terminate_coverage?: true, effective_on: Date.new(2015,8,10), consumer_role: double, applied_aptc_amount: 100, employee_role: nil, status_step: 2)}

    before :each do
      render partial: "insured/families/enrollment", collection: [hbx_enrollment], as: :hbx_enrollment
    end

    it "should display the title" do
      expect(rendered).to match /#{plan.active_year} health Coverage/
      expect(rendered).to match /DC Healthlink/
    end

    it "should display the aptc amount" do
      expect(rendered).to have_selector('label', text: 'APTC amount:')
      expect(rendered).to have_selector('strong', text: '$100')
    end
  end
end

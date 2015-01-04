require 'rails_helper'

describe ApplicationGroup do

  let(:p0) {Person.create!(name_first: "Dan", name_last: "Aurbach")}
  let(:p1) {Person.create!(name_first: "Patrick", name_last: "Carney")}
  let(:a0) {Applicant.new(person: p0, primary_applicant: true, consent_applicant: true)}
  let(:a1) {Applicant.new(person: p1)}
  let(:plan) {Plan.new(coverage_type: 'health', market_type: 'individual')}



  describe "instantiates object." do
    it "sets and gets all basic model fields" do
      ag = ApplicationGroup.new(
          e_case_id: "6754632abc",
          renewal_consent_through_year: 2017,
          applicants: [a0, a1],
          submitted_date: Date.today,
          is_active: true,
          updated_by: "rspec"
        )

      expect(ag.e_case_id).to eql("6754632abc")
      expect(ag.is_active).to eql(true)
      expect(ag.renewal_consent_through_year).to eql(2017)
      expect(ag.submitted_date).to eql(Date.today)
      expect(ag.updated_by).to eql("rspec")

      expect(ag.applicants.size).to eql(2)
      expect(ag.primary_applicant.id).to eql(a0.id)
      expect(ag.primary_applicant.person.name_first).to eql("Dan")
      expect(ag.consent_applicant.person.name_last).to eql("Aurbach")
    end
  end

  describe "manages embedded associations." do

    let(:ag) {
      ApplicationGroup.create!(
          e_case_id: "6754632abc", 
          renewal_consent_through_year: 2017, 
          submitted_date: Date.today,
          applicants: [p0, p1],
          primary_applicant: p0,
          consent_applicant: p0,
          irs_groups: [IrsGroup.new()]
        )  
    }

    let(:th) {
      TaxHousehold.new(
        primary_applicant: p0,
        irs_group: ag.irs_groups.first,
        applicants: [a0, a1]
      )
    }

    let(:ed) {
      EligibilityDetermination.new(
        csr_percent: 0.73,
        max_aptc_in_dollars: 165.00,
        applicants: [Applicant.new(
                            e_pdc_id: "qwerty",
                            person: p0,
                            is_ia_eligible: true,
                            is_medicaid_chip_eligible: true
                          )],
        determination_date: Date.today
      )
    }

    let(:he) {
      HbxEnrollment.new(
        primary_applicant: p0,
        irs_group: ag.irs_groups.first,
        eligibility_determination: ed,
        kind: "unassisted_qhp",
        allocated_aptc_in_dollars: 125.00,
        elected_aptc_in_dollars: 115.00,
        csr_percent: 0.71,
        applicants: [a0]
      )
    }

    let(:hx) {
      HbxEnrollmentExemption.new(
        irs_group: ag.irs_groups.first,
        kind: "hardship",
        certificate_number: "123zxy987",
        start_date: Date.today - 60,
        end_date: Date.today + 60,
        applicants: [Applicant.new(
                            person: p1,
                            is_ia_eligible: true,
                            is_medicaid_chip_eligible: true
                          )]
      )
    }


    it "sets and gets embedded IrsGroup, TaxHousehold and HbxEnrollment associations and attributes" do

      ag.eligibility_determinations = [ed]
      ag.tax_households  = [th]
      ag.hbx_enrollments = [he]
      ag.hbx_enrollment_exemptions = [hx]

      expect(ag.eligibility_determinations.first.csr_percent_as_integer).to eq(73)
      expect(ag.eligibility_determinations.first.applicants.first.is_ia_eligible).to eq(true)

      expect(ag.tax_households.first.primary_applicant_id).to eql(p0.id)
      expect(ag.tax_households.first.applicants.first.person._id).to eql(a0.person_id)

      expect(ag.hbx_enrollments.first.primary_applicant_id).to eql(p0.id)
      expect(ag.hbx_enrollments.first.eligibility_determination.id).to eq(ed.id)
      expect(ag.hbx_enrollments.first.allocated_aptc_in_cents).to eql(12500)
      expect(ag.hbx_enrollments.first.applicants.first.person_id).to eql(a0.person_id)

      expect(ag.hbx_enrollment_exemptions.first.certificate_number).to eql("123zxy987")

      # Access embedded model properties via the IrsGroup association
      expect(ag.irs_groups.first.tax_households.first.primary_applicant_id).to eql(p0.id)

      expect(ag.irs_groups.first.hbx_enrollments.first.kind).to eql("unassisted_qhp")
      expect(ag.irs_groups.first.hbx_enrollments.first.primary_applicant_id).to eql(p0.id)

      expect(ag.irs_groups.first.hbx_enrollment_exemptions.first.kind).to eql(hx.kind)
    end

    it "sets and gets HbxEnrollment Policy associations" do


      broker = Broker.create!(
        b_type: "broker",
        name_first: "Tom",
        name_last: "Schultz",
        npn: "345987012",
        addresses: [Address.new(
          address_type: "work", 
          address_1: "1 Copley Plaza", 
          city: "Boston", 
          state: "MA",
          zip: "03814")]
        )

      policy = Policy.create!(
        eg_id: "abc123xyz",
        plan: plan,
        pre_amt_tot: 750,
        tot_res_amt: 650,
        applied_aptc: 100,
        carrier_to_bill: true
        ) 

      expect(ag.policies.size).to eql(0)
      expect(ag.brokers.size).to eql(0)

      ag.hbx_enrollments = [he]
      he.policy = policy
      he.broker = broker
      ag.save!

      # Verify the ApplicationGroup::HbxEnrollment side of association
      expect(ag.policies.size).to eql(1)
      expect(ag.hbx_enrollments.first.policy_id).to eql(policy._id)
      expect(ag.policies.first.pre_amt_tot).to eql(750)

      # Verify the ApplicationGroup::Brokers side of association
      expect(ag.brokers.size).to eql(1)
      expect(ag.brokers.first._id).to eql(broker._id)

      # Verify the Policy side of association
      expect(policy.hbx_enrollment._id).to eql(ag.hbx_enrollments.first._id)

      # Verify the Broker side of association
      expect(broker.application_groups.first._id).to eql(ag._id)
    end
  end
end

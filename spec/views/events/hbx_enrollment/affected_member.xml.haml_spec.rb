require 'rails_helper'

RSpec.describe "app/views/events/shared/affected_member.xml.haml", dbclean: :after_each do
  let!(:issuer_profile)  { FactoryBot.create(:benefit_sponsors_organizations_issuer_profile) }
  let!(:product) { FactoryBot.create(:benefit_markets_products_health_products_health_product,issuer_profile: issuer_profile) }
  let(:person) { FactoryBot.create(:person)}
  let!(:dep_person) { FactoryBot.create(:person)}
  let!(:family) { FactoryBot.create(:family, :with_primary_family_member, person: person)}
  let(:hbx_enrollment_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.primary_family_member.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record)}
  let(:responsible_member) { FactoryBot.build(:hbx_enrollment_member, applicant_id: family.family_members.where(is_primary_applicant:'false').first.id, is_subscriber: true, eligibility_date: TimeKeeper.date_of_record)}
  let!(:family_member) do
    fm = FactoryBot.build(:family_member, person: dep_person, family: family, is_primary_applicant: false, is_consent_applicant: true)
    family.family_members << [fm]
    fm
  end
  let!(:hbx_enrollment) { FactoryBot.create(:hbx_enrollment,
                                            household: family.active_household,
                                            family: family,
                                            kind: "individual",
                                            created_at: Time.now,hbx_enrollment_members:[hbx_enrollment_member],
                                            product_id: product.id
  )}

  before :each do
    allow(hbx_enrollment).to receive(:premium_for).and_return(0.0)
  end

  context "ivl enrollment with responsible party" do
    before do
      hbx_enrollment.hbx_enrollment_members = [responsible_member]
      hbx_enrollment.save
      render :template=>"events/shared/_affected_member", :locals=>{hbx_enrollment:hbx_enrollment, hbx_enrollment_member: responsible_member, subscriber: responsible_member}
      @doc = Nokogiri::XML(rendered)
    end

    it "should not include primary_family_id" do
      expect(@doc.xpath("//affected_member//primary_family_id").text).to be_empty
    end
  end

  context "ivl enrollment with primary family" do
    before do
      render :template=>"events/shared/_affected_member", :locals=>{hbx_enrollment:hbx_enrollment, hbx_enrollment_member: hbx_enrollment_member, subscriber: hbx_enrollment_member}
      @doc = Nokogiri::XML(rendered)
    end

    it "should include primary_family_id" do
      expect(@doc.xpath("//affected_member//primary_family_id").text.to_i).to eq family.hbx_assigned_id
    end
  end
end

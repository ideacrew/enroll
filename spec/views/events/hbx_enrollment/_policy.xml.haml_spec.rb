# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'events/hbx_enrollment/_policy.xml.haml', dbclean: :after_each do
  let!(:issuer_profile) {FactoryBot.create(:benefit_sponsors_organizations_issuer_profile)}
  let!(:product) {FactoryBot.create(:benefit_markets_products_health_products_health_product, issuer_profile: issuer_profile)}
  let!(:primary_person) {FactoryBot.create(:person)}
  let!(:dep_person) {FactoryBot.create(:person, first_name: 'mem1', last_name: 'one')}
  let!(:family) {FactoryBot.create(:family, :with_primary_family_member, person: primary_person)}
  let!(:family_member) do
    fm = FactoryBot.build(:family_member, person: dep_person, family: family, is_primary_applicant: false, is_consent_applicant: true)
    family.family_members << [fm]
  end

  let(:responsible_member) do
    FactoryBot.build(:hbx_enrollment_member,
                     applicant_id: family.family_members.where(is_primary_applicant: 'false').first.id,
                     is_subscriber: true,
                     eligibility_date: TimeKeeper.date_of_record)
  end

  let!(:hbx_enrollment) do
    FactoryBot.create(:hbx_enrollment,
                      household: family.active_household,
                      family: family,
                      kind: 'individual',
                      created_at: Time.now.utc, hbx_enrollment_members: [responsible_member],
                      product_id: product.id)
  end

  before :each do
    allow(hbx_enrollment).to receive(:premium_for).and_return(0.0)
  end

  context 'for dependent enrollment only' do

    before do
      EnrollRegistry[:enroll_app].setting(:send_rating_area_for_ivl_policy_to_edi).stub(:item).and_return(false)
    end

    it 'should generate a policy cv with responsible_party' do
      render :template => 'events/hbx_enrollment/_policy', :locals => {hbx_enrollment: hbx_enrollment}
      expect(rendered).to include('<responsible_party>')
    end

    it 'responsible party name is primary person' do
      render :template => 'events/hbx_enrollment/_policy', :locals => {hbx_enrollment: hbx_enrollment}
      expect(rendered).to have_selector('responsible_party person_surname', :text => primary_person.last_name)
    end
  end

  context 'enrollment with rating area' do
    let!(:benefit_markets_location_rating_area) { FactoryBot.create_default(:benefit_markets_locations_rating_area) }

    before do
      EnrollRegistry[:enroll_app].setting(:send_rating_area_for_ivl_policy_to_edi).stub(:item).and_return(true)
      hbx_enrollment.update_attributes(rating_area_id: benefit_markets_location_rating_area.id)
      render :partial => "events/hbx_enrollment/policy", :locals => {hbx_enrollment: hbx_enrollment}
      @doc = Nokogiri::XML(rendered)
    end
    it 'should generate a rating area id in policy cv' do
      expect(rendered).to include('<rating_area>')
      expect(@doc.xpath("//rating_area").text).to eq benefit_markets_location_rating_area.exchange_provided_code
    end
  end
end

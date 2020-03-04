require 'rails_helper'
require "#{SponsoredBenefits::Engine.root}/spec/shared_contexts/sponsored_benefits"

RSpec.describe "app/views/events/v2/employers/_broker_agency_account.xml.haml", dbclean: :after_each do

  describe "broker_agency_account xml" do
    include_context 'set up broker agency profile for BQT, by using configuration settings'
    let(:broker_role) { FactoryBot.create(:broker_role, :aasm_state => 'active', broker_agency_profile: broker_agency_profile) }
    let(:broker_agency_account) { build :benefit_sponsors_accounts_broker_agency_account, benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, writing_agent_id: broker_role.id}
    let(:employer_profile) {broker_agency_account.benefit_sponsorship.profile}
    let(:owner_profile) {broker_agency_account.broker_agency_profile}

    context "ga_assignment" do
      context "no ga_assignment" do

        before :each do
          render :template => "events/v2/employers/_broker_agency_account.xml.haml", :locals => {:broker_agency_account => broker_agency_account}
          @doc = Nokogiri::XML(rendered)
        end

        it "should not have the general_agency_assignment" do
          expect(@doc.xpath("//broker_account/general_agency_assignment").count).to eq(0)
        end
      end

      context "with ga_assignment" do
        let!(:update_plan_design) {plan_design_organization_with_assigned_ga.update_attributes!(has_active_broker_relationship: true, owner_profile_id: owner_profile.id, sponsor_profile_id: employer_profile.id)}
        let!(:general_agency_account) {plan_design_organization.general_agency_accounts.unscoped.first}
        let!(:update_general_agency_account) {general_agency_account.update_attributes(broker_role_id: broker_role.id)}

        before :each do
          allow(employer_profile).to receive(:general_agency_enabled?).and_return(true)
          render :template => "events/v2/employers/_broker_agency_account.xml.haml",
                 locals: {broker_agency_account: broker_agency_account, employer_profile: employer_profile}
          @doc = Nokogiri::XML(rendered)
        end

        it "should have the general_agency_assignment" do
          expect(@doc.xpath("//broker_account/ga_assignments/ga_assignment").count).to eq(1)
        end
      end

      context 'with multiple general_agency_accounts' do
        let!(:update_plan_design) {plan_design_organization_with_assigned_ga.update_attributes!(has_active_broker_relationship: true, owner_profile_id: owner_profile.id, sponsor_profile_id: employer_profile.id)}
        let!(:general_agency_account) {plan_design_organization.general_agency_accounts.unscoped.first}
        let!(:update_general_agency_account) {general_agency_account.update_attributes(broker_role_id: broker_role.id)}
        let(:pdo) { SponsoredBenefits::Organizations::PlanDesignOrganization.find_by_owner_and_sponsor(broker_agency_account.broker_agency_profile.id, employer_profile.id) }
        let(:valid_gac) { pdo.general_agency_accounts.detect { |gac| gac.general_agency_profile } }
        let!(:old_general_agency_account) do
          FactoryBot.create(:sponsored_benefits_accounts_general_agency_account,
                            aasm_state: :inactive,
                            benefit_sponsrship_general_agency_profile_id: valid_gac.general_agency_profile.id,
                            plan_design_organization: plan_design_organization_with_assigned_ga)
        end

        before :each do
          allow(employer_profile).to receive(:general_agency_enabled?).and_return(true)
          old_general_agency_account.update_attributes!(broker_role_id: broker_agency_account.writing_agent_id)
          broker_agency_account.update_attributes!(start_on: TimeKeeper.date_of_record.beginning_of_year)
          render :template => 'events/v2/employers/_broker_agency_account.xml.haml',
                 locals: {broker_agency_account: broker_agency_account, employer_profile: employer_profile}
          @doc = Nokogiri::XML(rendered)
          @ga_assignment_element = @doc.xpath('//broker_account/ga_assignments/ga_assignment')
        end

        it 'should have the general_agency_assignments' do
          expect(@ga_assignment_element.count).to eq(2)
        end

        it 'should have a specific order for general_agencys' do
          expect(@ga_assignment_element.children.select{|child| child.name == 'start_on'}.first.children.text).to eq(old_general_agency_account.start_on.strftime('%Y%m%d'))
        end

        it 'should have a specific order for general_agencys' do
          expect(@ga_assignment_element.children.select{|child| child.name == 'start_on'}.second.children.text).to eq(general_agency_account.start_on.strftime('%Y%m%d'))
        end
      end
    end

    context "broker agency element" do
      subject do
        allow(employer_profile).to receive(:general_agency_enabled?).and_return(true)
        render :template => "events/v2/employers/_broker_agency_account.xml.haml",
               locals: {broker_agency_account: broker_agency_account, employer_profile: employer_profile}
        @doc = Nokogiri::XML(rendered)
      end

      it "should display a tag for FEIN" do
        expect(subject.text).to include(broker_agency_account.broker_agency_profile.fein)
      end

      context "for an employer without an fein" do
        before do
          allow(broker_agency_account.broker_agency_profile).to receive(:fein).and_return(nil)
        end

        it "should not display a tag for FEIN" do
          expect(subject.xpath("//x:fein", "x"=>"http://openhbx.org/api/terms/1.0")).to be_empty
        end
      end
    end
  end
end

require 'rails_helper'

module Notifier
  module NoticeBuilder
    
  RSpec.describe "delivery", dbclean: :around_each do
      let!(:site)            { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, Settings.site.key) }
      let!(:model_instance)     { FactoryBot.build(:benefit_sponsors_organizations_general_organization, "with_aca_shop_#{Settings.site.key}_employer_profile".to_sym, site: site) }
      let(:employer_profile)    { model_instance.employer_profile }
      let(:event_name) {"acapi.info.events.employer.welcome_notice_to_employer"}
      let(:subject) { Notifier::NoticeKind.new(event_name: event_name) }
      before :each do 
        allow(subject).to receive(:resource).and_return(employer_profile)
      end
      
    describe ".store_paper_notice" do
      
      it "should have contact method preferences" do
        expect(subject.has_contact_method?).to be true
      end
      
      it 'should have a paper related contact method' do
        expect(subject.resource.can_receive_paper_communication?).to be true
      end
      
      it 'should save to AWS' do
        subject.store_paper_notice
        #failing because needs @resource is nil
        # expect.....
      end
    end 
    
    describe ".send_generic_notice_alert" do

      it 'should send generic notice alert if electornic preference' do
        expect(subject.resource.can_receive_electronic_communication?).to be true
      end
      
      it "should have contact method preferences" do
        expect(subject.has_contact_method?).to be true
      end
      
      it 'should mail notice' do
        subject.send_generic_notice_alert 
        #failing because needs @resource is nil
        
      end 
    end 
  end
  end
end
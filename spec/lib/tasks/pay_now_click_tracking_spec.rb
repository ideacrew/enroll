# frozen_string_literal: true

require 'rails_helper'
require 'rake'
require 'csv'

describe 'Pay Now Click Tracking Report', :dbclean => :after_each do
  context 'paynow:click_tracking start_date="Month/Day/Year" end_date="Month/Day/Year" carrier="kk"' do

    let(:start_date) { "01/01/2021" }
    let(:end_date) { "03/01/2021" }
    let(:carrier) {'KFMASI'}

    let(:family) { FactoryBot.create(:family, :with_primary_family_member) }
    let(:payment_transaction1) { FactoryBot.create(:payment_transaction, family: family, carrier_id: '5d63154793c4e727f1ff888b') }
    let(:payment_transaction2) { FactoryBot.create(:payment_transaction, family: family, source: 'enrollment_tile',  carrier_id: '5d63154793c4e727f1ff888b') }

    let!(:issuer_profile) {FactoryBot.create(:benefit_sponsors_organizations_issuer_profile, abbrev: "KFMASI", id: '5d63154793c4e727f1ff888b')}

    let!(:enrollment) do
      FactoryBot.create(
        :hbx_enrollment,
        id: '123456789',
        family: family,
        enrollment_kind: 'special_enrollment',
        kind: 'individual',
        hbx_id: '123456789'
      )
    end

    context 'Configuration test for providing carriers' do
      before do
        EnrollRegistry[:carrier_abbrev_list].feature.stub(:item).and_return(["AHI", "BLHI", "GHMSI", "DDPA", "DTGA", "DMND", "KFMASI", "META", "UHIC"])
        payment_transaction1.reload
        payment_transaction2.reload

        load File.expand_path("#{Rails.root}/lib/tasks/pay_now_click_tracking.rake", __FILE__)
        Rake::Task.define_task(:environment)
        Rake::Task["paynow:click_tracking"].invoke(start_date,end_date,carrier)
      end

      it "should generate the proper report" do
        file_name = "#{Rails.root}/public/pay_now_click_tracking.csv"
        expect(File.exist?(file_name)).to eq(true)
      end

      it "should generate the click tracking data" do
        result = [["source", "enrollment_id", "datetime_of_click", "hbx_id"], ["plan_shopping","123456789","02/01/2021 00:00", "123456789"], ["enrollment_tile","123456789","02/01/2021 00:00", "123456789"]]
        data = CSV.read "#{Rails.root}/public/pay_now_click_tracking.csv"
        expect(data).to eq result
      end
    end

    context 'Configuration test new carrier addition' do
      before do
        EnrollRegistry[:carrier_abbrev_list].feature.stub(:item).and_return(["CHO", "HPHC", "ANTHM", "NEDD"])
        issuer_profile.update_attributes(abbrev: "NEDD")
        payment_transaction1.reload
        payment_transaction2.reload

        load File.expand_path("#{Rails.root}/lib/tasks/pay_now_click_tracking.rake", __FILE__)
        Rake::Task.define_task(:environment)
        Rake::Task["paynow:click_tracking"].invoke(start_date,end_date,'NEDD')
      end

      it "should generate the proper report" do
        file_name = "#{Rails.root}/public/pay_now_click_tracking.csv"
        expect(File.exist?(file_name)).to eq(true)
      end

      it "should generate the click tracking data" do
        result = [["source", "enrollment_id", "datetime_of_click", "hbx_id"], ["plan_shopping","123456789","02/01/2021 00:00", "123456789"], ["enrollment_tile","123456789","02/01/2021 00:00", "123456789"]]
        data = CSV.read "#{Rails.root}/public/pay_now_click_tracking.csv"
        expect(data).to eq result
      end
    end
  end
end
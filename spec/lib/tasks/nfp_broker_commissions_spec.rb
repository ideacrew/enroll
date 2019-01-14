require 'rails_helper'
Rake.application.rake_require "tasks/nfp_broker_commissions"
Rake::Task.define_task(:environment)

RSpec.describe 'upload commission-statements to s3 and create respective documents for broker_agency_profile', :type => :task, dbclean: :after_each do
  let(:site)                      { create(:benefit_sponsors_site, :with_benefit_market, :as_hbx_profile, :cca) }
  let!(:broker_organization)      { FactoryBot.build(:benefit_sponsors_organizations_general_organization, site: site)}
  let!(:broker_agency_profile)   { FactoryBot.create(:benefit_sponsors_organizations_broker_agency_profile, organization: broker_organization, market_kind: 'shop', legal_name: 'Legal Name1') }
  let!(:person)                  { FactoryBot.create(:person) }
  let!(:broker_role)             { FactoryBot.create(:broker_role, aasm_state: 'active', benefit_sponsors_broker_agency_profile_id: broker_agency_profile.id, person: person, npn: "48115294") }
  let(:sub_folder)                { "#{I18n.t("date.abbr_month_names")[TimeKeeper.date_of_record.month]}-#{TimeKeeper.date_of_record.year}" }
  let(:commission_statement)      { ::BenefitSponsors::Documents::Document.new({ title: "48115294_1024_07102018_COMMISSION_1024-001_R.pdf", subject: "commission-statement", date: Date.strptime("07102018", "%m%d%Y") })}
  let(:commission_statement2)      { ::BenefitSponsors::Documents::Document.new({ title: "48115294_1024_08102018_COMMISSION_1024-001_R.pdf", subject: "commission-statement", date: Date.strptime("07102018", "%m%d%Y") })}

  context "upload commission-statements to S3 and create respective documents for broker_agency_profile" do
    before :each do
      broker_agency_profile.update_attributes!(primary_broker_role_id: broker_role.id)
      broker_agency_profile.approve!
      FileUtils.mkdir "commission_statements"
      FileUtils.mkdir "commission_statements/#{sub_folder}"
      File.new("commission_statements/#{sub_folder}/48115294_1024_07102018_COMMISSION_1024-001_R.pdf", "w")
    end

    after :each do
      FileUtils.rm_rf(Dir["#{Rails.root}/commission_statements"])
    end

    it "should create douments/commission-statements for broker_agency_profile" do
      broker_agency_profile.documents << commission_statement2
      Rake::Task['nfp:commission_statements_upload'].invoke
      expect(broker_agency_profile.commission_statements.count).to eq 2
    end

    it "cannot create commission-statements as cannot find broker_role with given npn" do
      broker_role.update_attributes!(npn: "40115264")
      Rake::Task['nfp:commission_statements_upload'].invoke
      expect(broker_agency_profile.commission_statements.count).to eq 0
    end

    it "should do nothing as cannot find the commission_statements directory" do
      FileUtils.rm_rf(Dir["#{Rails.root}/commission_statements"])
      Rake::Task['nfp:commission_statements_upload'].invoke
      expect(broker_agency_profile.commission_statements.count).to eq 0
    end

    it "should not create new commission_statements if already exists" do
      broker_agency_profile.documents << commission_statement
      expect(broker_agency_profile.commission_statements.count).to eq 1
      Rake::Task['nfp:commission_statements_upload'].invoke
      expect(broker_agency_profile.commission_statements.count).to eq 1
    end
  end
end

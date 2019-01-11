require 'rails_helper'
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_market.rb"
require "#{BenefitSponsors::Engine.root}/spec/shared_contexts/benefit_application.rb"

RSpec.describe ShopEmployerNotices::GroupAdvanceTerminationConfirmation, dbclean: :after_each do
  include_context "setup benefit market with market catalogs and product packages"
  include_context "setup initial benefit application" do
    let(:aasm_state) {:terminated}
  end

  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 1.month - 1.year}
  let(:person){ FactoryGirl.create :person}
  let(:application_event) do
    double("ApplicationEventKind",
      {
        name: 'Confirmation notice to employer after group termination',
        notice_template: 'notices/shop_employer_notices/group_advance_termination_confirmation',
        notice_builder: 'ShopEmployerNotices::GroupAdvanceTerminationConfirmation',
        mpi_indicator: 'MPI_D043',
        event_name: 'group_advance_termination_confirmation',
        title: 'Notice Confirmation for Group termination due to ER advance request'
      }
    )
  end
  let(:valid_parmas) {{
      :subject => application_event.title,
      :mpi_indicator => application_event.mpi_indicator,
      :event_name => application_event.event_name,
      :template => application_event.notice_template
  }}

  describe "New" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
    end
    context "valid params" do
      it "should initialze" do
        expect{ShopEmployerNotices::GroupAdvanceTerminationConfirmation.new(abc_profile, valid_parmas)}.not_to raise_error
      end
    end
  end

  describe "Build" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::GroupAdvanceTerminationConfirmation.new(abc_profile, valid_parmas)
    end
    it "should build notice with all necessary info" do
      @employer_notice.build
      expect(@employer_notice.notice.employer_name).to eq abc_profile.organization.legal_name.titleize
    end
  end

  describe "append_data" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::GroupAdvanceTerminationConfirmation.new(abc_profile, valid_parmas)
    end
    it "should append necessary information" do
      @employer_notice.append_data
      expect(@employer_notice.notice.plan_year.end_on).to eq initial_application.end_on
    end
  end

  describe "generate_pdf_notice" do
    before do
      allow(abc_profile).to receive_message_chain("staff_roles.first").and_return(person)
      @employer_notice = ShopEmployerNotices::GroupAdvanceTerminationConfirmation.new(abc_profile, valid_parmas)
    end

    it "should render group advance termination confirmation partial" do
      expect(@employer_notice.template).to eq "notices/shop_employer_notices/group_advance_termination_confirmation"
    end

    it "should generate pdf" do
      @employer_notice.build
      @employer_notice.append_data
      file = @employer_notice.generate_pdf_notice
      expect(File.exist?(file.path)).to be true
    end
  end

end

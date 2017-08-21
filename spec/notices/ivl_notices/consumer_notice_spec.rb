require 'rails_helper'

RSpec.describe IvlNotices::ConsumerNotice, :dbclean => :after_each do
  let!(:person){ create :person, :with_family}
  let(:consumer_role) {FactoryGirl.create(:consumer_role, person: person)}
  let(:start_on) { TimeKeeper.date_of_record.beginning_of_month + 2.month - 1.year}
  let(:application_event){ double("ApplicationEventKind",{
                            :name =>'First Outstanding Verification Notification',
                            :notice_template => 'notices/ivl/documents_verification_reminder1',
                            :notice_builder => 'IvlNotices::ConsumerNotice',
                            :mpi_indicator => 'MPI_IVLV20A',
                            :event_name => 'first_verifications_reminder',
                            :title => "First Outstanding Verification Notification"})
                          }
    let(:valid_parmas) {{
        :subject => application_event.title,
        :mpi_indicator => application_event.mpi_indicator,
        :event_name => application_event.event_name,
        :template => application_event.notice_template
    }}

    let(:hbx_enrollment){ build_stubbed :hbx_enrollment , :terminated_on => TimeKeeper.date_of_record,:aasm_state => "enrolled_contingent"}

  describe "New" do
    before do
      @consumer_role = IvlNotices::ConsumerNotice.new(consumer_role, valid_parmas)
    end
    context "valid params" do
      it "should initialze" do
        @consumer_role = IvlNotices::ConsumerNotice.new(consumer_role, valid_parmas)
        expect{IvlNotices::ConsumerNotice.new(consumer_role, valid_parmas)}.not_to raise_error
      end
    end

    context "invalid params" do
      [:mpi_indicator,:subject,:template].each do  |key|
        it "should NOT initialze with out #{key}" do
          valid_parmas.delete(key)
          expect{IvlNotices::ConsumerNotice.new(consumer_role, valid_parmas)}.to raise_error(RuntimeError,"Required params #{key} not present")
        end
      end
    end
  end

  describe "Build" do
    before do
      @consumer_notice = IvlNotices::ConsumerNotice.new(consumer_role, valid_parmas)
      allow(@consumer_notice).to receive("append_unverified_family_members").and_return(true)
    end
    it "should build notice with all necessory info" do

      @consumer_notice.build
      expect(@consumer_notice.notice.primary_fullname).to eq person.full_name.titleize
    end
  end

end
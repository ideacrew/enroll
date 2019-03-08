require 'rails_helper'

 RSpec.describe 'ModelEvents::InitialEmployerInvoiceAvailable', dbclean: :after_each do

  let(:model_event) { 'initial_employer_invoice_available' }
  let(:start_on) { TimeKeeper.date_of_record.next_month.beginning_of_month}
  let(:organization) { FactoryGirl.create(:organization, :with_active_plan_year) }
  let(:employer_profile) { organization.employer_profile }
  let(:plan_year) { employer_profile.plan_years.first }

  let(:model_instance) {Document.new({ title: 'file_name_1', 
    date: TimeKeeper.date_of_record, 
    creator: 'hbx_staff', 
    subject: 'initial_invoice', 
    identifier: 'urn:openhbx:terms:v1:file_storage:s3:bucket:#bucket_name#key',
    format: 'file_content_type'
  })}

  let(:second_month_invoice) { Document.new(subject: 'invoice') }

  describe 'ModelEvent' do
    context 'when initial employers first month invoice is generated' do
      it 'should trigger model event' do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).to receive(:document_update) do | model_event|
            expect(model_event).to be_an_instance_of(ModelEvents::ModelEvent)
            expect(model_event).to have_attributes(:event_key => :initial_employer_invoice_available, :klass_instance => model_instance, :options => {})
          end
        end
        employer_profile.documents << model_instance
        model_instance.save
      end
    end

    context 'when employer invoice is uploaded - other than first month' do
      it 'should not trigger model event' do
        model_instance.observer_peers.keys.each do |observer|
          expect(observer).not_to receive(:document_update)
        end
        employer_profile.documents << second_month_invoice
        second_month_invoice.save
      end
    end
  end

  describe 'NoticeTrigger' do
    context 'when initial invoice is generated' do
      subject { Observers::NoticeObserver.new}
      let(:model_event) { ModelEvents::ModelEvent.new(:initial_employer_invoice_available, model_instance, {}) }

      before do
        allow(model_instance).to receive(:documentable).and_return(employer_profile)
      end

      it 'should trigger notice event' do
        expect(subject.notifier).to receive(:notify) do |event_name, payload|
          expect(event_name).to eq 'acapi.info.events.employer.initial_employer_invoice_available'
          expect(payload[:employer_id]).to eq employer_profile.hbx_id.to_s
          expect(payload[:event_object_kind]).to eq 'PlanYear'
          expect(payload[:event_object_id]).to eq plan_year.id.to_s
        end
        subject.document_update(model_event)
      end
    end
  end

  describe 'NoticeBuilder' do

    let(:data_elements) {
      [
        'employer_profile.notice_date',
        'employer_profile.employer_name',
        'employer_profile.broker.primary_fullname',
        'employer_profile.broker.organization',
        'employer_profile.broker.phone',
        'employer_profile.broker.email',
        'employer_profile.broker_present?'
      ]
    }
    let(:merge_model) { subject.construct_notice_object }
    let(:recipient) { 'Notifier::MergeDataModels::EmployerProfile' }
    let(:template)  { Notifier::Template.new(data_elements: data_elements) }

    let(:payload)   { {
        'event_object_kind' => 'PlanYear',
        'event_object_id' => plan_year.id
    } }

    context 'when notice event received' do

      subject { Notifier::NoticeKind.new(template: template, recipient: recipient) }

      before do
        allow(subject).to receive(:resource).and_return(employer_profile)
        allow(subject).to receive(:payload).and_return(payload)
        employer_profile.documents << model_instance
      end

      it 'should retrun merge model' do
        expect(merge_model).to be_a(recipient.constantize)
      end

      it 'should return the date of the notice' do
        expect(merge_model.notice_date).to eq TimeKeeper.date_of_record.strftime('%m/%d/%Y')
      end

      it 'should return employer name' do
        expect(merge_model.employer_name).to eq employer_profile.legal_name
      end

      it 'should return false when there is no broker linked to employer' do
        expect(merge_model.broker_present?).to be_falsey
      end
    end
  end
end 
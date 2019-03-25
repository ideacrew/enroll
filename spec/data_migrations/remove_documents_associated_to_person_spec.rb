require 'rails_helper'
require File.join(Rails.root, 'app', 'data_migrations', 'remove_documents_associated_to_person')

describe RemoveDocumentsAssociatedToPerson, dbclean: :after_each do
  let(:given_task_name) { 'remove_documents_associated_to_person' }
  subject { RemoveDocumentsAssociatedToPerson.new(given_task_name, double(:current_scope => nil)) }

  describe 'given a task name' do
    it 'has the given task name' do
      expect(subject.name).to eql given_task_name
    end
  end
  describe 'remove_documents_associated_to_person', dbclean: :after_each do
    let(:person) { FactoryGirl.create(:person)}
    let(:inbox) { FactoryGirl.create(:inbox, person: person) }

    before(:each) do
      allow(ENV).to receive(:[]).with('hbx_id').and_return(person.hbx_id)
      allow(ENV).to receive(:[]).with('message_id').and_return(person.inbox.messages.first.id)
    end

    it 'should remove the documents based on id' do
      secure_messages = person.inbox.messages
      subject.migrate
      person.reload
      expect(person.inbox.messages.size).not_to eq secure_messages.size
    end  
  end
end


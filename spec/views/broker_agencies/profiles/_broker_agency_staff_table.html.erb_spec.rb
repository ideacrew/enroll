require 'rails_helper'

RSpec.describe 'broker_agencies/profiles/_broker_agency_staff_table.html.erb', dbclean: :after_each do
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }

  context 'has active broker staff' do

    let(:current_user) { FactoryGirl.create(:user, person: person) }
    let(:person) { FactoryGirl.create(:person)}
    let(:people) { Person.all }

    before :each do
      assign(:broker_agency_profile, broker_agency_profile)
      allow(view).to receive(:current_user).and_return current_user
      allow(person). to receive(:broker_role).and_return true
      render template: 'broker_agencies/profiles/_broker_agency_staff_table.html.erb', locals: {broker_staff: people}
    end

    it 'should have content' do
      ['First Name', 'Last Name', 'Email', 'Phone', 'Status', 'Remove Role'].each do |element|
        expect(rendered).to have_content(element)
      end
    end

    it 'should render person details' do
      expect(rendered).to have_content(person.first_name)
      expect(rendered).to have_content(person.last_name)
      expect(rendered).to have_content(person.work_email_or_best)
      expect(rendered).to have_content(person.work_phone)
      expect(rendered).to have_content('Active Linked')
    end

    it 'should have Add broker staff link' do
      expect(rendered).to have_content('Add Broker Staff Role')
    end
  end

  context 'has pending broker staff' do
    let(:current_user) { FactoryGirl.create(:user, person: person2) }
    let(:person2) { FactoryGirl.create(:person)}
    let(:broker_agency_staff_role) { FactoryGirl.create(:broker_agency_staff_role, aasm_state: 'broker_agency_pending', broker_agency_profile_id: broker_agency_profile.id )}
    let(:people) { Person.all }

    before :each do
      assign(:broker_agency_profile, broker_agency_profile)
      allow(view).to receive(:current_user).and_return current_user
      allow(person2). to receive(:broker_role).and_return false
      person2.broker_agency_staff_roles << broker_agency_staff_role
      allow(person2). to receive(:has_pending_broker_staff_role?).with(broker_agency_profile.id).and_return true
      render template: 'broker_agencies/profiles/_broker_agency_staff_table.html.erb', locals: {broker_staff: people}
    end

    it 'should have content pending unlinked if staff is in pending state' do
      expect(rendered).to have_content('Pending Linked')
    end

  end


end
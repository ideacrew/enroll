require 'rails_helper'

RSpec.describe 'broker_agencies/profiles/_show.html.erb', dbclean: :after_each do
  let(:broker_agency_profile) { FactoryGirl.create(:broker_agency_profile) }
  let(:current_user) { FactoryGirl.create(:user, person: person)}
  let(:person) { FactoryGirl.create(:person)}

  before :each do
    assign(:broker_agency_profile, broker_agency_profile)
    allow(view).to receive(:current_user).and_return current_user
    allow(current_user). to receive(:has_hbx_staff_role?).and_return true
    allow(person).to receive(:broker_role).and_return true
    render template: 'broker_agencies/profiles/_show.html.erb'
  end

  it 'should have content' do
    ['Legal Name', 'dba', 'Market Kind'].each do |element|
      expect(rendered).to have_content(element)
    end
  end

  it 'should have rendered broker agency contacts template' do
    expect(rendered).to have_content('No Broker Agency Contacts found.')
  end

  it 'should have rendered office locations template' do
    expect(rendered).to have_content('Office Locations')
  end

  it 'should have rendered Broker Agency Staff template' do
    ['First Name', 'Last Name', 'Email', 'Phone', 'Status'].each do |element|
      expect(rendered).to have_content(element)
    end
  end
end
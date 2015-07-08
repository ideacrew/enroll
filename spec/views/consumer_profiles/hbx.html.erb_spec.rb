require 'rails_helper'

RSpec.describe "layouts/_header.html.erb" do

  let(:person_user){Person.new(first_name: 'fred', last_name: 'flintstone', hbx_id: 'HBX_SLUG')}
  let(:current_user){FactoryGirl.create(:user, :person=>person_user)}
  #let(:person){current_user.instantiate_person}
  let(:signed_in?){ true } 
  before(:each) do
  	sign_in current_user  
  end
  it 'should show current_user.id if no hbx_id' do
  	current_user.person = nil
  	render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/#{current_user.id}/)
    expect(rendered).not_to match(/HBX_SLUG/) 
  end
  it 'should show hbx_id if the person has one' do
  	render :template => 'layouts/_header.html.erb'
  	expect(rendered).to match(/HBX_SLUG/) 
  	expect(rendered).not_to match(/#{current_user.id}/)
  end
end
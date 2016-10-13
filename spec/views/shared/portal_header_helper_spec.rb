require 'rails_helper'

RSpec.describe "layouts/_portal_header_helper.erb" do
  
  let(:person_user){Person.new(first_name: 'fred', last_name: 'flintstone')}
  let(:current_user){FactoryGirl.create(:user, :person=>person_user)}
  let(:employer_profile){ FactoryGirl.build(:employer_profile) }
  let(:employer_staff_role){ FactoryGirl.build(:employer_staff_role, :person=>person_user, :employer_profile_id=>employer_profile.id)}
  let(:signed_in?){ true }
  
  before(:each) do
  	sign_in current_user
  end
  
  it 'directs Im a Employer to Employer Profile' do
    allow(person_user).to receive(:employer_staff_roles).and_return(employer_staff_role)
    current_user.roles=['employer_staff']
    current_user.save
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match('/employers/employer_profiles/')
  end
  
end
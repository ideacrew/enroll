require 'rails_helper'

RSpec.describe "layouts/_header.html.erb" do

  let(:person_user){Person.new(first_name: 'fred', last_name: 'flintstone')}
  let(:current_user){FactoryGirl.create(:user, :person=>person_user)}
  let(:signed_in?){ true }
  before(:each) do
  	sign_in current_user
  end
  it 'identifies HBX Staff' do
    current_user.roles=['hbx_staff']
    current_user.save
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/I'm HBX Staff/)
  end
  it 'identifies Brokers' do
    current_user.roles=['broker_agency_staff']
    current_user.save
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/I'm a Broker/)
  end
  it 'identifies Employers' do
    current_user.roles=['employer_staff']
    current_user.save
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/I'm an Employer/)
  end

  it 'identifies Customer Service Staff' do
    person_user.csr_role = FactoryGirl.build(:csr_role, cac: false)
    current_user.roles=['csr']
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/I'm a Customer Service Representative/)
  end

  it 'identifies Certified Applicant Counselor' do
    person_user.csr_role = FactoryGirl.build(:csr_role, cac: true)
    current_user.roles=['csr']
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/I'm a Certified Applicant Counselor/)
  end

  it 'identifies Assisters' do
    current_user.roles=['assister']
    current_user.person.assister_role = FactoryGirl.build(:assister_role)
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/I'm an In Person Assister/)
  end

  it 'identifies default controller' do
    render :template => 'layouts/_header.html.erb'
    expect(rendered).to match(/Welcome to the District/)
  end

end

require "rails_helper"

RSpec.describe "employers/broker_agency/_active_broker_modal.html.erb" do
  let(:organization) { FactoryBot.create(:organization) }
  let(:broker_agency_profile) { FactoryBot.create(:broker_agency_profile, organization: organization) }
  let(:broker_role1) { FactoryBot.create(:broker_role, broker_agency_profile_id: broker_agency_profile.id) }
  let(:person1) {FactoryBot.create(:person)}
  let(:email) {FactoryBot.build(:email)}

  before :each do
    allow(person1).to receive(:broker_role).and_return(broker_role1)
    allow(broker_role1).to receive(:email).and_return(email)
    allow(broker_role1).to receive(:phone).and_return('7035551212')
    @broker_roles = [broker_role1]
    @staff = person1
    render template: "employers/broker_agency/_active_broker_modal.html.erb"
  end

  it "should show Broker Agency name" do
    expect(rendered).to have_selector('.tt-u', text: broker_agency_profile.legal_name)
  end
  it "show should the Broker email" do
    expect(rendered).to match(email.address)
  end
  it "show should the Broker phone" do
    expect(rendered).to match(broker_role1.phone)
  end

end

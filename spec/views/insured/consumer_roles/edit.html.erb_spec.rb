require "rails_helper"

RSpec.describe "insured/consumer_roles/edit.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:consumer_role) { double("ConsumerRole", id: "test", person: person)}
  let(:current_user) {FactoryGirl.create(:user)}
  before :each do
    assign(:person, person)
    assign(:consumer_role, consumer_role)
    allow(person).to receive(:consumer_role).and_return(consumer_role)
    allow(consumer_role).to receive(:citizen_status)
    allow(consumer_role ).to receive(:persisted?)
    allow(consumer_role ).to receive(:vlp_document_id)
    allow_any_instance_of(ApplicationHelper).to receive(:find_document).with(anything, anything)
    sign_in current_user
    render template: "insured/consumer_roles/edit.html.erb"
  end

  it "should display the page info" do
    expect(rendered).to match(/#{person.first_name}/)
    expect(rendered).to match(/#{person.last_name}/)
    expect(rendered).to match(/#{person.dob}/)
    expect(rendered).to match(/#{person.ssn}/)
    expect(rendered).to match(/#{person.gender}/)
    expect(rendered).to match(/#{person.emails.last.address}/mi)
    expect(rendered).to match(/Let’s begin by entering your personal information. This will take approximately 10 minutes. When you finish, select CONTINUE./)
    expect(rendered).to have_selector('h3', text: 'Enroll - let\'s get you signed up for healthcare')
  end

end

require "rails_helper"

RSpec.describe "consumer/consumer_roles/edit.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:consumer_role) { double("ConsumerRole", id: "test")}

  before :each do
    assign(:person, person)
    allow(person).to receive(:consumer_role).and_return(consumer_role)
    allow(consumer_role).to receive(:citizen_status)
    allow(consumer_role ).to receive(:persisted?)
    allow(consumer_role ).to receive(:vlp_document_id)
    allow_any_instance_of(ApplicationHelper).to receive(:find_document).with(anything, anything)

    render template: "consumer/consumer_roles/edit.html.erb"
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

  it "should contain immigration documents fields" do
    expect(rendered).to match(/immigration_naturalization_cert_container/)
    expect(rendered).to match(/immigration_citizenship_cert_container/)
    expect(rendered).to match(/immigration_i_327_fields_container/)
    expect(rendered).to match(/immigration_i_551_fields_container/)
    expect(rendered).to match(/immigration_i_571_fields_container/)
    expect(rendered).to match(/immigration_i_94_fields_container/)
    expect(rendered).to match(/immigration_i_94_2_fields_container/)
    expect(rendered).to match(/immigration_temporary_i_551_stamp_fields_container/)
    expect(rendered).to match(/immigration_i_766_fields_container/)
    expect(rendered).to match(/immigration_temporary_i_551_fields_container/)
    expect(rendered).to match(/immigration_i_94_2_fields_container/)
    expect(rendered).to match(/immigration_other_doc_fields_container/)
    expect(rendered).to match(/immigration_i_766_fields_container/)
    expect(rendered).to match(/immigration_unexpired_foreign_passport_fields_container/)
  end
end

require 'rails_helper'

describe "insured/family_relationships/index.html.erb" do
  let(:person) { FactoryGirl.create(:person) }
  let(:user) { FactoryGirl.create(:user, person: person) }
  let(:family) { Family.new }
  let(:test_family){FactoryGirl.create(:family, :with_primary)}
  let(:family_member2) {FactoryGirl.create()}

  before :each do
    sign_in user
    assign :person, person
    assign :family, family
    allow(view).to receive(:policy_helper).and_return(double("Policy", updateable?: true))
  end

  it "should have title" do
    render template: "insured/family_relationships/index.html.erb"
    expect(rendered).to have_selector("h1", text: 'Household Relationships')
  end

  it "should have memo to indicate required fields" do
    render template: "insured/family_relationships/index.html.erb"
    expect(rendered).to have_selector('li', text: 'Household Relationships')
  end

  it "should render the form partial" do
    expect(render).to render_template(partial: '_form')
  end

  it "should render the individual progress" do
    expect(render).to render_template(partial: '_individual_progress')
  end
end

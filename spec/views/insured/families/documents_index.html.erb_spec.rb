require 'rails_helper'

RSpec.describe "insured/families/documents_index.html.erb" do
  let(:person) { double(id: '123') }

  before :each do
    stub_template "insured/families/_navigation.html.erb" => ''
    stub_template "insured/families/_documents_index.html.erb" => ''
    assign :person, person
  end

  it "should display the title" do
    render file: "insured/families/documents_index.html.erb"
    expect(rendered).to have_selector('h1', text: 'Documents')
  end

  it "should not display the link of upload document" do
    allow(person).to receive(:consumer_role).and_return(nil)
    render file: "insured/families/documents_index.html.erb"
    expect(rendered).not_to have_selector('a', text: 'Upload Document')
  end

  it "should display the link to download tax documents" do
    allow(person).to receive(:consumer_role).and_return(double)
    render file: "insured/families/documents_index.html.erb"
    expect(rendered).to have_selector('a', text: 'Download Tax Documents')
  end

  it "should not display the link to download tax documents for non ivl users" do
    allow(person).to receive(:consumer_role).and_return(nil)
    render file: "insured/families/documents_index.html.erb"
    expect(rendered).not_to have_selector('a', text: 'Download Tax Documents')
  end
  
end

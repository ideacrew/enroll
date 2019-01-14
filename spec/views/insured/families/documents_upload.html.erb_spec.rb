require 'rails_helper'

RSpec.describe "insured/families/documents_upload.html.erb" do
  let(:consumer_role) { FactoryBot.build(:consumer_role) }
  let(:person) { FactoryBot.build(:person, consumer_role: consumer_role) }

  before :each do
    stub_template "insured/families/_navigation.html.erb" => ''
    assign :person, person
  end

  xit "should display the title" do
    render file: "insured/families/document_upload.html.erb"
    expect(rendered).to have_selector('h3', text: 'Additional Documentation Required')
  end

  xit "should display the area of upload document" do
    allow(person).to receive(:consumer_role).and_return(consumer_role)
    render file: "insured/families/document_upload.html.erb"
    expect(rendered).to have_selector('div#vlp_documents_container')
    expect(rendered).to have_selector('select#immigration_doc_type')
    expect(rendered).to have_selector('select#naturalization_doc_type')
    expect(rendered).to have_selector('div.hidden_field', count: 1)
  end
end

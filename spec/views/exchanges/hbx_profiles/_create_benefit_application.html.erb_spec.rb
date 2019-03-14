require 'rails_helper'

RSpec.describe "_create_benefit_application.html.erb", :type => :view, dbclean: :around_each do

  context "it should successfully create draft application" do
    before do
      render template: 'exchanges/hbx_profiles/_create_benefit_application.html.erb'
    end

    it { expect(rendered).to have_text(/Successfully created a draft plan year/) }
    it { expect(rendered).to have_css('.title') }
    it { expect(rendered).not_to have_css('.close') }
    it { expect(rendered).not_to have_css('.alert-error') }
  end
end

require 'rails_helper'

RSpec.describe "_create_benefit_application.html.erb", :type => :view, dbclean: :after_each  do

  context 'when save_errors exists' do
    before do
      assign(:save_errors, ['Rating Area cannot be blank'])
      render template: 'exchanges/hbx_profiles/_create_benefit_application.html.erb'
    end

    it { expect(rendered).to have_text(/Could not create a draft plan year/) }
    it { expect(rendered).to have_css('.title') }
    it { expect(rendered).to have_css('.close') }
    it { expect(rendered).to have_css('.alert-error') }
  end

  context "when save_errors doesn't exists" do
    before do
      render template: 'exchanges/hbx_profiles/_create_benefit_application.html.erb'
    end

    it { expect(rendered).to have_text(/Successfully created a draft plan year/) }
    it { expect(rendered).to have_css('.title') }
    it { expect(rendered).not_to have_css('.close') }
    it { expect(rendered).not_to have_css('.alert-error') }
  end
end

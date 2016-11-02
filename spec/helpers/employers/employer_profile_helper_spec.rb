require "rails_helper"

RSpec.describe Employers::EmployerProfileHelper, :type => :helper do
  describe "#show_oop_pdf_link" do
    context 'valid aasm_state' do
      it "should return true" do
        ["enrolling" ,"published", "enrolled"," active","renewing_published", "renewing_enrolling", "renewing_enrolled"].each do |state|
          expect(helper.show_oop_pdf_link(state)).to be true
        end
      end
    end
  end
end

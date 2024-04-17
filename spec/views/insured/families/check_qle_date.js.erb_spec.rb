require 'rails_helper'

describe "insured/families/check_qle_date.js.erb" do
  let(:qle) {FactoryBot.create(:qualifying_life_event_kind)}

  context "with qualified_date" do
    context "without effective_on_options" do
      before :each do
        assign :qualified_date, true
        assign :qle, qle
        render template: "insured/families/check_qle_date.js.erb"
      end

      it "should match effective_on_kinds" do
        expect(rendered).to match(/effective_on_kinds/)
      end
    end

    context "with effective_on_options" do
      context "when I Losing Employer-Subsidized Insurance because employee is going on Medicare" do
        before :each do
          assign :qualified_date, true
          assign :qle_date, TimeKeeper.date_of_record + 1.month
          assign :effective_on_options, [1, 2]
          render template: "insured/families/check_qle_date.js.erb"
        end

        it "should have qle message" do
          qle_date = TimeKeeper.date_of_record + 1.month
          expect(rendered).to match /Because your other health insurance is ending/
          expect(rendered).to match /#{qle_date.beginning_of_month}/
          expect(rendered).to match /#{(qle_date + 1.month).beginning_of_month}/
          expect(rendered).to match /#{qle_date.beginning_of_month - 1.day}/
        end
      end

      context "effective_on_options not an array" do
        before :each do
          assign :qualified_date, true
          assign :qle_date, TimeKeeper.date_of_record + 1.month
          assign :qle, qle
          assign :effective_on_options, TimeKeeper.date_of_record
          render template: "insured/families/check_qle_date.js.erb"
        end

        it "should match effective_on_kinds" do
          expect(rendered).to match(/effective_on_kinds/)
        end
      end
    end
  end

  context "without qualified_date" do
    before :each do
      assign :qualified_date, false
      assign :qle, qle
      render template: "insured/families/check_qle_date.js.erb"
    end

    it "should match error notice" do
      expect(render).to include("The date you submitted does not qualify for special enrollment")
      expect(render).to include("Please double check the date or contact #{EnrollRegistry[:enroll_app].setting(:contact_center_name).item}: #{EnrollRegistry[:enroll_app].setting(:health_benefit_exchange_authority_phone_number)&.item}")
    end
  end

  context "For event which happens in future" do
    before :each do
     assign :qualified_date, false
     assign :future_qualified_date, true
     assign :qle, qle
     render template: "insured/families/check_qle_date.js.erb"
    end

    it "should match error notice " do
      expect(render).to include(
        "The date you submitted does not qualify for a special enrollment period."\
        " Qualifying life events may be reported up to 30 days after the date of the event."\
        " If you are trying to report a future event, please come back on or after the actual date of the event."\
        " For further assistance, please contact #{EnrollRegistry[:enroll_app].setting(:contact_center_name).item}: #{EnrollRegistry[:enroll_app].setting(:health_benefit_exchange_authority_phone_number)&.item}"
      )
    end
  end
end

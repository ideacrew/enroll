require "rails_helper"

describe Subscribers::NfpStatementHistory do
  it "should subscribe to the correct event" do
    expect(Subscribers::NfpStatementHistory.subscription_details).to eq ["acapi.info.events.employer.nfp_statement_summary_success"]
  end

  describe "given a statement summary from NFP" do
    let(:effective_on) { TimeKeeper.date_of_record.beginning_of_month - 2.months }
    let(:employer) { FactoryGirl.create(:employer_with_planyear, start_on: effective_on, plan_year_state: 'active') }
    let(:payload) {
      {:content_type=>"application/octet-stream", :delivery_mode=>2, :priority=>0, :timestamp=>"2019-01-31",
        "submitted_timestamp"=>"2019-01-31",
        "employer_id"=>employer.hbx_id.to_s,
        "event_name"=>"nfp_statement_summary_request",
        "workflow_id"=>"133985e6597a42379c9f0ccd09ee0174",
        "return_status"=>"200",
        :body=>
        '{
          :past_due=>"0",
          :previous_balance=>"1051.92",
          :new_charges=>"350.64",
          :adjustments=>"0",
          :payments=>"-1051.92",
          :total_due=>"350.64",
          :statement_date=>"01/03/2019",
          :adjustment_items=>[
            {
              :amount=>"100",
              :name=>"Some name",
              :description=>"BlueDental Preferred High",
              :posting_date=>"01/03/2019",
              :is_passive_renewal=>"true"
            }
          ],
          :payment_history=>[
            {
              :amount=>"1051.92",
              :reference_id=>"3025768644",
              :paid_on=>"2018-12-31:00:00",
              :method_kind=>"ACH"
            },
            {
              :amount=>"701.28",
              :reference_id=>"3022648327",
              :paid_on=>"2018-09-26:00:00",
              :method_kind=>"ACH"
            }
          ]
        }'
      }
    }

    context "Update employer profile account with latest information" do

      before do
        subject.call("acapi.info.events.employer.nfp_statement_summary_success", nil, nil, nil, payload)
        employer.reload
      end

      it "should create/update employer profile account" do
        expect(employer.employer_profile_account.present?).to be_truthy
      end

      it "should update total due" do
        expect(employer.employer_profile_account.total_due).to eq "350.64"
      end

      it "should update current statement date" do
        expect(employer.employer_profile_account.current_statement_date.strftime('%m/%d/%Y')).to eq "01/03/2019"
      end

      it 'should update current_statement_activity' do
        expect(employer.employer_profile_account.current_statement_activity.first.description).to eq 'BlueDental Preferred High'
      end
    end
  end
end

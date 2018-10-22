require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationSchedular, type: :model, :dbclean => :after_each do

    describe "#map_binder_payment_due_date_by_start_on" do
      let(:benefit_application_schedular) { BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new }
      let(:date_hash) do
        {
          "2018-01-01" => '2017,12,12',
          "2018-02-01" => '2018,1,12',
          "2018-03-01" => '2018,2,13',
          "2018-04-01" => '2018,3,13',
          "2018-05-01" => '2018,4,12',
          "2018-06-01" => '2018,5,14',
          "2018-07-01" => '2018,6,12',
          "2018-08-01" => '2018,7,24',
          "2018-09-01" => '2018,8,23',
          "2018-10-01" => '2018,9,24',
          "2018-11-01" => '2018,10,23',
          "2018-12-01" => '2018,11,23',
          "2019-01-01" => '2018,12,24'
        }
      end

      context 'when start on in hash key' do
        it 'should return the corresponding value' do
          date_hash.each do |k, v|
            expect(benefit_application_schedular.map_binder_payment_due_date_by_start_on(Date.parse(k))).to eq(Date.strptime(v, '%Y,%m,%d'))
          end
        end
        it { expect(benefit_application_schedular.map_binder_payment_due_date_by_start_on(Date.parse('2018-11-01'))).to eq(Date.parse('2018-10-23')) }
      end
    end
  end
end

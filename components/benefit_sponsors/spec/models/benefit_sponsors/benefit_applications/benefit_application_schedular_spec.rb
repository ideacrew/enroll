require 'rails_helper'

module BenefitSponsors
  RSpec.describe BenefitApplications::BenefitApplicationSchedular, type: :model, :dbclean => :after_each do

    describe "#map_binder_payment_due_date_by_start_on" do
      let(:benefit_application_schedular) { BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new }
      let(:date_hash) do
        {

          "2018-08-01" => '2018,7,24',
          "2018-09-01" => '2018,8,23',
          "2018-10-01" => '2018,9,24',
          "2018-11-01" => '2018,10,23',
          "2018-12-01" => '2018,11,26',
          "2019-01-01" => '2018,12,26',
          "2019-02-01" => '2019,1,24',
          "2019-03-01" => '2019,2,25',
          "2019-04-01" => '2019,3,25',
          "2019-05-01" => '2019,4,23',
          "2019-06-01" => '2019,5,23',
          "2019-07-01" => '2019,6,24',
          "2019-08-01" => '2019,7,23',
          "2019-09-01" => '2019,8,23',
          "2019-10-01" => '2019,9,23',
          "2019-11-01" => '2019,10,23',
          "2019-12-01" => '2019,11,25',
          "2020-01-01" => '2019,12,24',
          "2020-02-01" => '2020,1,23',
          "2020-03-01" => '2020,2,24',
          "2020-04-01" => '2020,3,23',
          "2020-05-01" => '2020,4,23',
          "2020-06-01" => '2020,5,22',
          "2020-07-01" => '2020,6,23',
          "2020-08-01" => '2020,7,23',
          "2020-09-01" => '2020,8,24',
          "2020-10-01" => '2020,9,23',
          "2020-11-01" => '2020,10,23',
          "2020-12-01" => '2020,11,24',
          "2021-01-01" => '2020,12,23'
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

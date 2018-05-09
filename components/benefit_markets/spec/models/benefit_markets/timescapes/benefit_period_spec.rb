require 'rails_helper'

module BenefitMarkets
  RSpec.describe Timescapes::BenefitPeriod, type: :model do
    let(:this_year)     { TimeKeeper.date_of_record.year }
    let(:begin_on)      { Date.new(this_year, 1, 1) }
    let(:end_on)        { Date.new(this_year, 12, 31) }


    let(:params) do 
      {
        begin_on:   begin_on,
        end_on:     end_on,
      }
    end

    context "A new BenefitPeriod instance" do

      context "with no arguments" do
        subject { described_class.new }

        it "should not be valid" do
          subject.validate
          expect(subject).to_not be_valid
        end
      end

      context "without required params" do

        context "that's missing begin_on" do
          subject { described_class.new(params.except(:begin_on)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:begin_on]).to include("can't be blank")
          end
        end

        context "that's missing end_on" do
          subject { described_class.new(params.except(:end_on)) }

          it "should be invalid" do
            subject.validate
            expect(subject).to_not be_valid
            expect(subject.errors[:end_on]).to include("can't be blank")
          end
        end
      end

      context "with invalid params" do
        context "and end_on preceeds begin_on" do
          let(:invalid_end_on)  { begin_on - 1.day }

          subject { described_class.new(params.except(:end_on).merge({end_on: invalid_end_on})) }

          # it "should not be valid" do
          #   binding.pry
          #   expect(subject.validate).to raise_error("begin date must start on or before end date")
          # end
        end
      end

      context "with all valid params" do
        subject { described_class.new(params) }

        it "should be valid" do
          subject.validate
          expect(subject).to be_valid
        end
      end

    end

  end
end

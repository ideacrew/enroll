# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::Products::FetchSlcsp, dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  describe 'invalid params' do

    let(:params) do
      {}
    end

    it 'should return failure' do
      result = subject.call(params)
      expect(result.failure?).to eq true
    end
  end

  describe 'valid params' do

    let(:person) { FactoryBot.create(:person, :with_consumer_role) }

    let(:params) do
      {
        member_silver_product_premiums: member_silver_product_premiums
      }
    end

    let(:member_silver_product_premiums) do
      {
        [person.hbx_id] => {
          :health_only => {
            person.hbx_id => [
              {
                :monthly_premium => 200.0,
                :member_identifier => person.hbx_id,
                :product_id => BSON::ObjectId.new
              },
              {
                :monthly_premium => 300.0,
                :member_identifier => person.hbx_id,
                :product_id => BSON::ObjectId.new
              },
              {
                :monthly_premium => 400.0,
                :member_identifier => person.hbx_id,
                :product_id => BSON::ObjectId.new
              }
            ]
          }
        }
      }
    end

    it 'should return success' do
      result = subject.call(params)
      expect(result.success?).to eq true
    end

    it 'should return an array of health_only_slcsp_premiums for the given family' do
      value = subject.call(params).value!
      expect(value.is_a?(Hash)).to eq true
      expect(value[person.hbx_id].keys.include?(:health_only_slcsp_premiums)).to eq true
    end

    it 'should return details of second lowest plan' do
      values = subject.call(params).value![person.hbx_id][:health_only_slcsp_premiums]
      expect(values[:monthly_premium]).to eq 300.0
      expect(values[:member_identifier]).not_to eq nil
      expect(values[:product_id]).not_to eq nil
    end
  end
end

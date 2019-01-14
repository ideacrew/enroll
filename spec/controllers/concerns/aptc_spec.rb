require 'rails_helper'

class FakesController < ApplicationController
  include Aptc
end

describe FakesController do
  let(:person) {FactoryBot.build(:person)}

  context "#get_shopping_tax_household_from_person" do
    it "should get nil without person" do
      expect(subject.get_shopping_tax_household_from_person(nil, 2015)).to eq nil
    end

    it "should get nil when person without consumer_role" do
      allow(person).to receive(:has_active_consumer_role?).and_return true
      expect(subject.get_shopping_tax_household_from_person(person, 2015)).to eq nil
    end
  end
end

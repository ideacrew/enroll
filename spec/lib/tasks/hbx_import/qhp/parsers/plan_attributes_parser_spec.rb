# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib', 'tasks', 'hbx_import', 'qhp', 'parsers', 'plan_attributes_parser')

describe Parser::PlanAttributesParser do
  describe '#ehb_apportionment_for_pediatric_dental' do
    let(:ehb_apportionment) { '0.987' }

    it 'should return value that is set' do
      subject.ehb_apportionment_for_pediatric_dental = ehb_apportionment
      expect(subject.ehb_apportionment_for_pediatric_dental).to eq(ehb_apportionment)
    end
  end
end

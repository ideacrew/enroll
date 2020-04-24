# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FloatHelper, :type => :helper do
  describe 'float_fix' do

    shared_examples_for 'float_fix' do |input, output|
      it "should round the floating value #{input}" do
        expect(helper.float_fix(input)).to eq(output)
      end
    end

    it_behaves_like 'float_fix', (0.55 * 100), 55.0
    it_behaves_like 'float_fix', (2.76 + 2.43), 5.19
  end
end

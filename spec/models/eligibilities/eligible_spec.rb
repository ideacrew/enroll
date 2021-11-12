require 'rails_helper'

RSpec.describe Eligibilities::Eligible do
  context 'When included in a class' do
    let(:test_klass) do
      Class.new(EligibleKlass) do
        include Eligibilities::Eligible

        def initialize; end
      end
    end

    subject { test_klass.new }

    it 'should provide access to module methods' do
      expect(subject.respond_to?(:accept)).to be_truthy
    end
  end
end

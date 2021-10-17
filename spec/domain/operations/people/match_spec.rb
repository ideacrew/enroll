# frozen_string_literal: true

require 'rails_helper'
require 'pry'
RSpec.describe Operations::People::Match, type: :model, dbclean: :after_each do

  before :all do
    DatabaseCleaner.clean
  end

  context 'create person' do
    let(:params) {{:first_name=>"ivl206",
        :last_name=>"206",
        :dob=>"1986-09-04",
        :ssn=>"763-81-2636"}}

    it 'should be a container-ready operation' do
      expect(subject.call(params)).to be_truthy
    end
  end
end

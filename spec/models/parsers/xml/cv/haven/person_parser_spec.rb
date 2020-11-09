# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/spec/shared_examples/haven_parser_shared_examples.rb"

describe 'PersonParser' do
  class_name = self.name.demodulize
  include_examples :haven_parser_examples, class_name

  context 'verified members' do
    it 'should get hbx_id' do
      subject.each_with_index do |sub, index|
        expect(sub.hbx_id).to eq hbx_id[index].text.strip
      end
    end

    it 'should get name_last' do
      subject.each_with_index do |sub, index|
        expect(sub.name_last).to eq name_last[index].text.strip
      end
    end

    it 'should get name_first' do
      subject.each_with_index do |sub, index|
        expect(sub.name_first).to eq name_first[index].text.strip
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ::Operations::AuditLogEvents::Create,
               type: :model,
               dbclean: :after_each do

  it 'should be a container-ready operation' do
    expect(subject.respond_to?(:call)).to be_truthy
  end

  context 'when required attributes passed' do
    it 'should persist audit event' do
      # todo
    end
  end

  context 'when required attributes not passed' do
    it 'should fail to persist audit event' do
      # todo
    end
  end
end

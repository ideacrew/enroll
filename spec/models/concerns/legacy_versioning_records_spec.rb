require 'rails_helper'

class DummyClass
  include Mongoid::Document
  include Mongoid::Timestamps
  include LegacyVersioningRecords
end

describe LegacyVersioningRecords do
  subject { DummyClass.new }

  it 'creates a version field with a default value of 1' do
    expect(subject.version).to eql(1)
  end

  it 'has an array of versions' do
    expect(subject.versions).to be_kind_of(Array)
  end
end

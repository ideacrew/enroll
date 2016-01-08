require 'rails_helper'

class DubiousDocumentClass
  include Mongoid::Document
  include FullStrippedNames

  field :first_name
  field :last_name
  field :middle_name
  field :name_sfx
  field :name_pfx
end

describe FullStrippedNames do
  let(:dummy) { DubiousDocumentClass.new }
  let(:prespace) {"  space"}
  let(:postspace) {"space   "}
  let(:bothspace) {"   space   "}
  let(:nospace) {"space"}
  let(:space) {"space"}

  context "with included module on a mongoid document" do

    before do
      dummy.first_name = prespace
      dummy.last_name = postspace
      dummy.middle_name = bothspace
      dummy.name_sfx = nospace
      dummy.name_pfx = bothspace
      dummy.save
    end

    it "strips the spaces when saving" do
      expect(dummy.first_name).to eq space
      expect(dummy.last_name).to eq space
      expect(dummy.middle_name).to eq space
      expect(dummy.name_sfx).to eq space
      expect(dummy.name_pfx).to eq space
    end
  end
end

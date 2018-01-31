require 'rails_helper'

class DubiousClass
  include Forms::PeopleNames
end

describe Forms::PeopleNames do
  let(:dummy) { DubiousClass.new }
  let(:prespace) {"  space"}
  let(:postspace) {"space   "}
  let(:bothspace) {"   space   "}
  let(:nospace) {"space"}
  let(:space) {"space"}

  context "with included module on any class" do

    before do
      dummy.first_name = prespace
      dummy.last_name = postspace
      dummy.middle_name = bothspace
      dummy.name_sfx = nospace
      dummy.name_pfx = bothspace
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

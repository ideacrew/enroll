require "rails_helper"

RSpec.describe ApplicationHelper, :type => :helper do

  describe "decode_msg" do
    let(:encoded_msg) {"101"}
    let(:wrong_encoded_msg) {"111"}

    it "should return decoded msg" do
      expect(helper.decode_msg(encoded_msg)).to eq "faa.acdes_lookup"
    end

    it "should return decoded msg" do
      expect(helper.decode_msg(wrong_encoded_msg)).to eq nil
    end
  end
end

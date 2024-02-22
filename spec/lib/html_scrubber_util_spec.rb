# frozen_string_literal: true

class TestingScrubber
  extend HtmlScrubberUtil
end

RSpec.describe HtmlScrubberUtil do
  context "given an image with an 'onerror' attribute" do
    let(:source_html) { "<img onerror=\"blech\">" }
    let(:result) { TestingScrubber.sanitize_html(source_html) }

    it "scrubs that attribute" do
      expect(result.include?("onerror")).to be_falsey
    end
  end

  context "given a name with a script tag" do
    let(:source_html) { "First Name<script>alert('HI');</script> Last Name" }
    let(:result) { TestingScrubber.sanitize_html(source_html) }

    it "scrubs that tag" do
      expect(result.include?("script")).to be_falsey
    end
  end

  context "given a vanilla div" do
    let(:source_html) { "<div></div>" }
    let(:result) { TestingScrubber.sanitize_html(source_html) }

    it "does not scrub the div" do
      expect(result).to include("div")
    end
  end

  context "given a style attribute" do
    let(:source_html) { "<div style=\"somewhere\"></div>" }
    let(:result) { TestingScrubber.sanitize_html(source_html) }

    it "does not scrub the style attribute" do
      expect(result).to include("style")
    end
  end
end
require "rails_helper"
require "tasks/hbx_import/employer_monkeypatch"

describe String do
  context "with a date representation" do
    let(:test_date) {Date.new(2015, 3, 1)}
    context "of mm/dd/yyyy" do
      let(:date_string) {"03/01/2015"}
      it() {expect(date_string.to_date_safe).to eq test_date}
    end
    context "of m/d/yyyy" do
      let(:date_string) {"3/1/2015"}
      it() {expect(date_string.to_date_safe).to eq test_date}
    end
    context "of mm/dd/yy" do
      let(:date_string) {"03/01/15"}
      it() {expect(date_string.to_date_safe).to eq test_date}
    end
    context "of m/d/yy" do
      let(:date_string) {"3/1/15"}
      it() {expect(date_string.to_date_safe).to eq test_date}
    end
  end

  context "with no date representation" do
    context "of word" do
      let(:string) {"bananas"}
      it() {expect(string.to_date_safe).to eq nil}
    end
    context "of blank" do
      let(:string) {""}
      it() {expect(string.to_date_safe).to eq nil}
    end
    context "of number" do
      let(:string) {"03012015"}
      it() {expect(string.to_date_safe).to eq nil}
    end
  end
end

Foo = Struct.new(:year, :month, :day) do
  def to_s
    "#{month}/#{day}/#{year}"
  end
end

describe Object do
  context "that has a to_s that returns a date representation" do
    let(:test_date) {Date.new(2015, 3, 1)}
    let(:date_object) {Foo.new(2015, 3, 1)}
    it() {expect(date_object.to_date_safe).to eq test_date}
  end

  context "that does not have a to_s that returns a date representation" do
    let(:object) {Struct.new(:foo).new("not important")}
    it() {expect(object.to_date_safe).to eq nil}
  end
end

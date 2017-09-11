require 'rails_helper'

describe "HavenPersonParser" do
  let(:class_name) {self.name.demodulize}
  include_examples "haven parser examples", class_name

  context "verified members" do
    it 'should get hbx_id' do
      subject.each_with_index do |sub, index|
        expect(sub.hbx_id).to eq hbx_id[index].text.strip
      end
    end

    # it 'should get ssn' do
    #   subject.each_with_index do |sub, index|
    #     expect(sub.person_surname).to eq person_surname[index].text.strip == "nil"
    #   end
    # end
    #
    #
    # it 'should get ssn' do
    #   subject.each_with_index do |sub, index|
    #     expect(sub.person_given_name).to eq person_given_name[index].text.strip == "nil"
    #   end
    # end

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

    # it 'should get birth date' do
    #   subject.each_with_index do |sub, index|
    #     binding.pry
    #     expect(sub.name_full).to eq name_full[index].text.strip
    #   end
    # end
  end


  context "verified member family to hash" do
    # let(:xml) {File.read(Rails.root.join("spec", "test_data", "haven_eligibility_response_payloads", "verified_1_member_family.xml"))}
    #
    # it 'should return the elements as a hash' do
    # end
  end
end


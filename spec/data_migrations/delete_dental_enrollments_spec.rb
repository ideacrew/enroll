require "rails_helper"
require File.join(Rails.root, "app", "data_migrations", "delete_dental_enrollments")

describe DeleteDentalEnrollment do



  describe "Delete dental enrollments" do
    subject { DeleteDentalEnrollment.new }



    context "some context" do


      let(:person) { FactoryGirl.create(:family, :with_primary_family_member)}

      pp = p.primary_family_member.person

      #   let(:params) { {kind: "home", person: person} }
      #   let(:phone) { Phone.create(**params) }
      #   before :each do
      #     phone.number ="1234567"
      #     phone.area_code = "987"
      #     phone.extension = "456"
      #     phone.save!
      #     subject.migrate
      #     phone.reload
      #   end
      it "should delete all the created dental enrollments" do
         puts "Hello World"
      end
    end
    # subject { UpdateFullPhoneNumber.new("fix me task", double(:current_scope => nil)) }
    #
    # context "get person phones " do
    #   let(:person) { FactoryGirl.create(:person) }
    #   let(:params) { {kind: "home", person: person} }
    #   let(:phone) { Phone.create(**params) }
    #   before :each do
    #     phone.number ="1234567"
    #     phone.area_code = "987"
    #     phone.extension = "456"
    #     phone.save!
    #     subject.migrate
    #     phone.reload
    #   end
    #   it "full phone number is set with combination of number,extension,area code " do
    #     expect(phone.full_phone_number).to eq "9871234567456"
    #   end
    # end
  end


end

module BenefitSponsors
  module Serializers
    class PersonSerializer < ActiveModel::Serializer
    	attributes :first_name, :last_name, :email, :dob, :npn
    end
  end
end

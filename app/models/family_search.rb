class FamilySearch
  class FamilySearchMember < ::FamilyMember
    include Mongoid::Document
    embeds_one :person
  end

  class FamilySearchFamily < ::Family
    include Mongoid::Document
    embeds_many :family_members, class_name: "::FamilySearch::FamilySearchMember"
  end

  include Mongoid::Document

  store_in collection: :families_search

  embeds_one :value, class_name: "::FamilySearch::FamilySearchFamily"

  index({
    "value.primary_member.encrypted_ssn" => 1,
    "value.primary_member.hbx_id" => 1,
    "value.primary_member.first_name" => 1,
    "value.primary_member.last_name" => 1,
    "value.family_members.person.encrypted_ssn" => 1,
    "value.family_members.person.hbx_id" => 1,
    "value.family_members.person.first_name" => 1,
    "value.family_members.person.last_name" => 1
  }, :name => "family_search_all_attributes_index")

  def family
    value
  end
end

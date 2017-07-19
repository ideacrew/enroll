module Parsers::Xml::Cv
  class HavenVerifiedFamilyParser
    include HappyMapper
    register_namespace 'n1', 'http://openhbx.org/api/terms/1.0'
    namespace 'n1'

    tag 'external_verified_family'

    element :integrated_case_id, String, tag: 'id/n1:id'
    has_many :family_members, Parsers::Xml::Cv::HavenFamilyMembersParser, tag: 'family_member'
    element :primary_family_member_id, String, tag: 'primary_family_member_id/n1:id'
    has_many :households, Parsers::Xml::Cv::HavenHouseholdsParser, tag: 'household', namespace: 'n1'
    has_many :broker_accounts, Parsers::Xml::Cv::FamilyBrokerAccountsParser, tag: 'broker_account', namespace: 'n1'
    # element :submitted_at, DateTime
    # element :is_active, Boolean
    # element :created_at, DateTime
    element :e_case_id, String
    element :fin_app_id, String, tag: 'fin_app_id', namespace: 'n1'
    element :haven_app_id, String, tag: 'haven_app_id', namespace: 'n1'
    element :haven_ic_id, String, tag: 'haven_ic_id', namespace: 'n1'
    # element :haven_family_id, String, tag: 'id/n1:id'

    # def to_hash
    #   {
    #    integrated_case_id: integrated_case_id,
    #    family_members: family_members.map(&:to_hash),
    #    primary_family_member_id: primary_family_member_id,
    #    households: households.map(&:to_hash),
    #    submitted_at: submitted_at,
    #    is_active: is_active,
    #    created_at: created_at
    #   }
    # end
  end
end

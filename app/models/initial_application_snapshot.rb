class InitialApplicationSnapshot
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :family

  embeds_many :family_member_snapshots

  def take_family_member_snapshot(family_member)
    person = JSON.dump(family_member.person.inspect)
    consumer_role = JSON.dump(family_member.person.consumer_role.inspect)
    lawful_presence_determination = JSON.dump(family_member.person.consumer_role.lawful_presence_determination.inspect)
    addresses = JSON.dump(family_member.person.addresses.inspect)
    phones = JSON.dump(family_member.person.phones.inspect)
    emails = JSON.dump(family_member.person.emails.inspect)
    self.family_member_snapshots.build(:member_snapshot => family_member,
                                       :person_snapshot => person,
                                       :consumer_role_snapshot => consumer_role,
                                       :lawful_presence_determination_snapshot => lawful_presence_determination,
                                       :addresses_snapshot => addresses,
                                       :phones_snapshot => phones,
                                       :emails_snapshot => emails)
  end
end

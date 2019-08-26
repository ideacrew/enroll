# frozen_string_literal: true

class SbcRole
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :person

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true
  delegate :first, to: :all
  delegate :last, to: :all

  accepts_nested_attributes_for :person

  def parent
    person
  end

  class << self

    def find(id)
      return nil if id.blank?

      people = Person.where("sbc_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].sbc_role : nil
    end

    def list_sbc_users(list)
      list.reduce([]) { |users, person| users << person.sbc_role }
    end

    def all
      list_sbc_users(Person.where(sbc_role: {:$exists => true}))
    end
  end
end

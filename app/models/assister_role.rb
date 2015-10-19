class AssisterRole
  include Mongoid::Document
  include SetCurrentUser
  include Mongoid::Timestamps

  embedded_in :person

  delegate :hbx_id, :hbx_id=, to: :person, allow_nil: true

  accepts_nested_attributes_for :person
  field :organization, type: String
  
  def parent
    person
  end

  class << self
    
    def find(id)
      return nil if id.blank?
      people = Person.where("assister_role._id" => BSON::ObjectId.from_string(id))
      people.any? ? people[0].assister_role : nil
    end

    def list_assisters(person_list)
      person_list.reduce([]) { |assisters, person| assisters << person.assister_role }
    end

    # TODO; return as chainable Mongoid::Criteria
    def all
      # criteria = Mongoid::Criteria.new(Person)
      list_assisters(Person.where(assister_role: {:$exists => true}))
    end

    def first
      all.first
    end

    def last
      all.last
    end

  end  

end

class PersonRelationship
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :person


  MALE_RELATIONSHIPS_LIST   = %W(father grandfather grandson uncle nephew adopted\ child stepparent
                              foster\ child son-in-law brother-in-law father-in-law brother ward
                              stepson child sponsored\ dependent dependent\ of\ a\ minor\ dependent
                              guardian court\ appointed\ guardian collateral\ dependent life\ partner)

  FEMALE_RELATIONSHIPS_LIST = %W(mother grandmother granddaughter aunt niece adopted\ child stepparent
                              foster\ child daughter-in-law sister-in-law mother-in-law sister ward
                              stepdaughter child sponsored\ dependent dependent\ of\ a\ minor\ dependent
                              guardian court\ appointed\ guardian collateral\ dependent life\ partner)
  RELATIONSHIPS_LIST = [
    "parent",
    "grandparent",
    "aunt_or_uncle",
    "nephew_or_niece",
    "father_or_mother_in_law",
    "daughter_or_son_in_law",
    "brother_or_sister_in_law",
    "adopted_child",
    "stepparent",
    "foster_child",
    "sibling",
    "ward",
    "stepchild",
    "sponsored_dependent",
    "dependent_of_a_minor_dependent",
    "guardian",
    "court_appointed_guardian",
    "collateral_dependent",
    "life_partner",
    "spouse",
    "child",
    "grandchild",
    "trustee", # no inverse
    "annuitant", # no inverse,
    "other_relationship",
    "unrelated",
    "great_grandparent",
    "great_grandchild"
  ]

  INVERSE_MAP = {
    "child" => "parent",
    "parent" => "child",
    "grandparent" => "grandchild",
    "grandchild" => "grandparent",
    "great_grandparent" => "great_grandchild",
    "great_grandchild" => "great_grandparent",
    "stepparent" => "stepchild",
    "stepchild" => "stepparent",
    "aunt_or_uncle" => "nephew_or_niece",
    "nephew_or_niece" => "aunt_or_uncle",
    "father_or_mother_in_law" => "daughter_or_son_in_law",
    "daughter_or_son_in_law" => "father_or_mother_in_law",
    "guardian" => "ward",
    "ward" => "guardian",

    # bi directional
    "brother_or_sister_in_law" => "brother_or_sister_in_law",
    "sibling" => "sibling",
    "life_partner" => "life_partner",
    "spouse" => "spouse",
    "other_relationship" => "other_relationship",
    "cousin" => "cousin",
    "unrelated" => "unrelated",

    #one directional
    "foster_child" => "guardian",
    "court_appointed_guardian" => "ward",
    "adopted_child" => "parent"
  }

  SYMMETRICAL_RELATIONSHIPS_LIST = %W[head\ of\ household spouse ex-spouse cousin ward trustee annuitant other\ relationship other\ relative self]

  KINDS = SYMMETRICAL_RELATIONSHIPS_LIST | RELATIONSHIPS_LIST

  field :relative_id, type: BSON::ObjectId
  field :kind, type: String

	validates_presence_of :relative_id, message: "Choose a relative"
  validates :kind, 
            presence: true,
            allow_blank: false,
            allow_nil:   false,
            inclusion: {in: KINDS, message: "%{value} is not a valid person relationship"}


  def parent
    raise "undefined parent class: Person" unless person? 
    self.person
  end

  def relative=(person_instance)
    return unless person_instance.is_a? Person
    self.relative_id = person_instance._id
  end

  def relative
    Person.find(self.relative_id) unless self.relative_id.blank?
  end

  def invert_relationship
    self.kind = INVERSE_MAP[self.kind]
    self
  end

end

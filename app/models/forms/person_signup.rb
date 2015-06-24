module Forms
  class PersonSignup
    include ActiveModel::Validations
    attr_accessor :id
    attr_accessor :person_id
    attr_accessor :person
    attr_accessor :first_name, :last_name, :email
    attr_reader :dob

    validates_presence_of :dob, :if => Proc.new { |m| m.person_id.blank? }
    validates_presence_of :first_name, :if => Proc.new { |m| m.person_id.blank? }
    validates_presence_of :last_name, :if => Proc.new { |m| m.person_id.blank? }

    class PersonAlreadyMatched < StandardError; end
    class TooManyMatchingPeople < StandardError; end

    def initialize(attrs = {})
      assign_wrapper_attributes(attrs)
    end

    def assign_wrapper_attributes(attrs = {})
      attrs.each_pair do |k,v|
        self.send("#{k}=", v)
      end
    end

    def match_or_create_person
      new_person = Person.new({
        :first_name => first_name,
        :last_name => last_name,
        :dob => dob
        })

      matched_people = Person.where(
        first_name: regex_for(first_name),
        last_name: regex_for(last_name),
        dob: new_person.dob
        )

      if matched_people.count > 1
        raise TooManyMatchingPeople.new
      end

      if matched_people.count == 1
        mp = matched_people.first
        raise PersonAlreadyMatched.new
      end
      self.person = new_person
      self.person.emails << Email.new({kind: 'work', address: email})
    end

    def to_key
      @id
    end

    def dob=(val)
      @dob = Date.strptime(val,"%Y-%m-%d") rescue nil
    end

    def regex_for(str)
      Regexp.compile(Regexp.escape(str.to_s))
    end
  end
end

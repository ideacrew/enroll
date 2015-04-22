module Forms
  module PeopleNames
    def self.included(base)
      base.class_eval do
        attr_accessor :first_name, :middle_name, :last_name
        attr_accessor :name_pfx, :name_sfx
      end
    end
  end
end

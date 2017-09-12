module Parsers::Xml::Cv
  class HavenPersonParser
    include HappyMapper
    register_namespace 'ridp', 'http://openhbx.org/api/terms/1.0'
    namespace 'ridp'

    tag 'person'

    element :hbx_id, String, tag: "id/ridp:id"

    element :person_surname, String,  tag: "person_surname/ridp:person_surname"

    element :person_given_name, String,  tag: "person_given_name/ridp:person_given_name"

    element :name_last, String, tag: "person_name/ridp:person_surname"

    element :name_first, String, tag: "person_name/ridp:person_given_name"

    element :name_full, String, tag: "person_name/ridp:person_full_name"

    # element :name_middle, String, tag: "person_name/ridp:person_middle_name"

    # element :name_pfx, String, tag: "person_name/ridp:person_name_prefix_text"

    # element :name_sfx, String, tag: "person_name/ridp:person_name_suffix_text"


    # has_many :addresses, Parsers::Xml::Cv::AddressParser, :tag => 'address', :namespace => 'ridp'

    # has_many :emails, Parsers::Xml::Cv::EmailParser, :tag => "email", :namespace => 'ridp'

    # has_many :phones, Parsers::Xml::Cv::PhoneParser, :tag => "phone", :namespace => 'ridp'

  end
end

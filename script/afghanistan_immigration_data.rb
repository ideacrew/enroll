# Finds people who have vlp documents matching Afghanistan in country of citizenship or issuing country. 

country_of_citizenship_people = Person.where("consumer_role.vlp_documents.country_of_citizenship" => "Afghanistan")

issuing_country_people = Person.where("consumer_role.vlp_documents.issuing_country" => "Afghanistan")

binding.pry
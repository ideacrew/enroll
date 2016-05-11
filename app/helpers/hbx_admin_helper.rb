module HbxAdminHelper

  def full_name_of_person(person_id)
    Person.find(person_id).full_name
  end
  
end

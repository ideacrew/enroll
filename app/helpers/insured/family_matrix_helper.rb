module Insured::FamilyMatrixHelper
  def member_name_by_id(id)
    @family.family_members.where(id: id).first.person.full_name
  end	
end

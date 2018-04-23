module BenefitSponsors
  class Members::EmployeeMember < Member

    field :date_of_hire,        type: Date 
    field :date_of_termination, type: Date

    after_initilize :set_self_relationship


    private

    def set_self_relationship
      relationship_to_primary_member = :self
    end


  end
end

module SponsoredApplications
  class SponsorBenefits::Task

    attr_accesso :name, :parent

    def initialize(name)
      @name = name

      # Pointer to traverse upward from child tasks
      @parent = nil
    end


  end
end

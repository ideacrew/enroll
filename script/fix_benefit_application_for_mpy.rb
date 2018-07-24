BenefitSponsors::BenefitSponsorships::BenefitSponsorship.where(:"benefit_applications.effective_period.min".gte => Date.new(2018,8,1)).each do |benefit_sponsorship|
  benefit_sponsorship.census_employees.each do |census|
    census.benefit_group_assignments.each do |benefit_group_assignment|
      if benefit_group_assignment.benefit_application.present?
          benefit_group_assignment.update(is_active: false) if benefit_group_assignment.benefit_application.is_renewing? && benefit_group_assignment.is_active == true
          benefit_group_assignment.update(is_active: true) if benefit_group_assignment.benefit_application.active? && benefit_group_assignment.is_active == false
        end
      end
    end
  end
end

namespace :update_ivl do
  desc "populate csr_eligibility_kind  premium_credit_strategy_kind determined_at"
  task :eligibility_determination_attributes => :environment do 
    visited_count = 0
    changed_count = 0

    families = Family.all_assistance_applying.to_a
    puts "#{families.size} families with eligibility determinations found"
    families.each do |family|
      family.households.each do |household|
        household.tax_households.each do |tax_household|
          tax_household.eligibility_determinations.each do |ed|
            ed.determined_at = ed.tax_household.submitted_at if ed.determined_at.blank?
            ed.csr_percent_as_integer = ed.csr_percent_as_integer if ed.csr_eligibility_kind.blank?

            # ed.determined_at = ed.tax_household.submitted_at if ed.determined_at.blank?
            # ed.created_at = ed.tax_household.created_at if ed.created_at.blank?

            if ed.changed?
              ed.save! 
              changed_count += 1
            end
            visited_count += 1
          end
        end
      end
    end
    puts "visited #{visited_count} and updated #{changed_count} eligibility_determinations with csr_eligibility_kind and premium_credit_strategy_kind"
  end
end

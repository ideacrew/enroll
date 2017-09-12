module Aptc
  def get_shopping_tax_households_from_person(person, year)
    if person.present? && person.has_active_consumer_role?
      family = person.primary_family
      if family.active_approved_application.present?
        person.primary_family.active_approved_application.latest_active_tax_households_with_year(year) rescue nil
      else
        person.primary_family.latest_household.latest_active_tax_households_with_year(year) rescue nil
      end
    else
      nil
    end
  end

  def get_tax_households_from_family_members(person, family_member_ids)
    tax_households = []
    family_member_ids = family_member_ids.collect { |k,v| v}
    if person.present? && person.has_active_consumer_role?
      family = person.primary_family
      application = family.active_approved_application
      if application.present?
        application.tax_households.each do |th|
          tax_households << th if th.applicants.where(:family_member_id.in => family_member_ids).present?
        end
      else
        if family.active_household.latest_active_tax_households.present?
          family.active_household.latest_active_tax_households.each do |th|
            tax_households << th if th.tax_household_members.where(:applicant_id.in => family_member_ids).present?
            # thh_family_member_ids = th.tax_household_members.map(&:family_member).map(&:id).inject([]) do |fm_ids, id|
            #                           fm_ids << id.to_s
            #                           fm_ids.flatten
            #                         end

            # thh_family_member_ids.each do |tfm_id|
            #   tax_households << th if thh_family_member_ids.include?(tfm_id)
            # end
          end
        end
      end
    end
    tax_households.uniq
  end

  def total_aptc_on_tax_households(tax_households, hbx_enrollment)
    total = 0
    tax_households.each do |th|
      total = total + th.total_aptc_available_amount_for_enrollment(hbx_enrollment)
    end
    total
  end
end

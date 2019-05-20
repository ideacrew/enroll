Organization.where({
      :'employer_profile.plan_years' =>
      { :$elemMatch => {
        :start_on => TimeKeeper.date_of_record.next_month.next_month.beginning_of_month,
        :aasm_state => 'renewing_draft'
      }}
  }).each do |org|
    if org.employer_profile.renewing_plan_year.may_force_publish?
      org.employer_profile.renewing_plan_year.force_publish!
    end 
  end
file_name = '11455_report.csv'

file_name_2 = "#{Rails.root}/public/ivl_renewal_notice_8_report.csv"

field_names  = %w(family.e_case_id hbx_id)

families = []

enrollment_group_ids = []

CSV.foreach(file_name, headers: true) do |row|
  hbx_en = HbxEnrollment.by_hbx_id(row["policy.eg_id"]).first
  unless hbx_en.blank?
    families << hbx_en.household.family
    enrollment_group_ids << hbx_en.hbx_id
  end
end

families.uniq!

enrollment_group_ids.uniq!

CSV.open(file_name_2,"w",force_quotes: true) do |csv|
  csv << fiel
  families.each do |fam|
    event_kind = ApplicationEventKind.where(:event_name => 'ivl_renewal_notice_8').first
    notice_trigger = event_kind.notice_triggers.first
    consumer_role = fam.primary_applicant.person.consumer_role
    if consumer_role.present?
      builder = notice_trigger.notice_builder.camelize.constantize.new(consumer_role, {
                    template: notice_trigger.notice_template,
                    subject: event_kind.title,
                    mpi_indicator: notice_trigger.mpi_indicator,
                    data: fam.family_members.map(&:person),
                    person: fam.primary_applicant.person,
                    address: fam.primary_applicant.person.mailing_address,
                    primary_identifier: ic_ref
                    }.merge(notice_trigger.notice_trigger_element_group.notice_peferences)
                    )
      builder.deliver
    end
  end
end
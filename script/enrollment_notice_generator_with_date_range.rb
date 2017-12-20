@logger = Logger.new("#{Rails.root}/log/enrollment_notice_data_set.log")
@logger.info "Script Start #{TimeKeeper.datetime_of_record}"

unless ARGV[0].present? && ARGV[0].split("/").last.split("").count == 4
  puts "Please include end_date as an argument with a valid format(mm/dd/yyyy). Example: rails runner script/enrollment_notice_generator.rb 12/26/2017" unless Rails.env.test?
  @logger.info "Bad Input #{ARGV[0]} or No arguments"
  exit
end

@end_date = Date.strptime(ARGV[0], "%m/%d/%Y")
@start_date = Date.new(2017, 10, 31)

event_name = "enrollment_notice_with_date_range"

field_names = %w(
        primary_hbx_id
        primary_first_name
        primary_last_name
      )

report_name = "#{Rails.root}/enrollment_notice_data_set.csv"


def valid_enrollment_hbx_ids(family)
  hbx_enrollment_hbx_ids = []
  enrollments = family.enrollments
  good_enrollments = enrollments.by_created_datetime_range(@start_date, @end_date).enrolled
  bad_enrollments = enrollments.by_created_datetime_range(Date.new(2016, 12, 31), @start_date + 1.day).enrolled
  oe_enrs = []
  seps_2017 = []

  good_enrollments.each do |en|
    if (en.coverage_year == 2017 && en.enrollment_kind == "special_enrollment")
      seps_2017 << en.hbx_id
    elsif en.coverage_year == 2018 && !bad_enrollments
      oe_enrs << en.hbx_id
    elsif en.coverage_year == 2018 && bad_enrollments
      seps_2017 = []
      oe_enrs = []
    end
  end

  target_enrs = oe_enrs + seps_2017
  target_enrs.uniq!
  target_enrs

  # coverage_years = good_enrollments.flat_map(&:coverage_year).uniq!

  # if (coverage_years.count == 1 && coverage_years.first == 2017) || (coverage_years.count == 1 && coverage_years.first == 2018 && !bad_enrollments)
  #   hbx_enrollment_hbx_ids << good_enrollments.flat_map(&:hbx_id)
  # elsif coverage_years.include?(2018) && bad_enrollments
  #   hbx_enrollment_hbx_ids = []
  # else
  #   hbx_enrollment_hbx_ids = []
  # end

  # hbx_enrollment_hbx_ids.uniq!
  # hbx_enrollment_hbx_ids
end

CSV.open(report_name, "w", force_quotes: true) do |csv|
  csv << field_names
  Family.by_enrollment_individual_market.by_enrollment_created_datetime_range(@start_date, @end_date).each do |family|
    begin
      person = family.primary_applicant.person

      hbx_enrollment_hbx_ids = valid_enrollment_hbx_ids(family)
      hbx_enrollment_hbx_ids.compact!

      if hbx_enrollment_hbx_ids
        IvlNoticesNotifierJob.perform_later(person.id.to_s, event_name, {:hbx_enrollment_hbx_ids => hbx_enrollment_hbx_ids }) if person.consumer_role.present?
        @logger.info "#{event_name} generated to family with primary_person: #{person.hbx_id}" unless Rails.env.test?
        csv << [
          person.hbx_id,
          person.first_name,
          person.last_name
        ]
      end
    rescue Exception => e
      @logger.error "Unable to deliver #{event_name} to family with PrimaryPerson: #{person.hbx_id} due to the following error #{e.backtrace}" unless Rails.env.test?
    end
  end
  @logger.info "End of the scirpt" unless Rails.env.test?
end





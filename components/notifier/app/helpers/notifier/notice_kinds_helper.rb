module Notifier
  module NoticeKindsHelper
    include HtmlScrubberUtil

    def date_of_notice
      TimeKeeper.date_of_record.strftime('%m/%d/%Y')
    end

    def site_home_url
      EnrollRegistry[:enroll_app].setting(:home_url).item
    end

    def site_home_link
      link_to site_home_url, site_home_url
    end

    def site_short_name
      EnrollRegistry[:enroll_app].setting(:short_name).item
    end

    def employer_name
      'US Legal LLC'
    end

    def employer_staff_full_name
      'staff name'
    end

    def employer_address
    end

    def open_enrollment_begin
      'open enrollment begin date'
    end

    def open_enrollment_end
      'open enrollment end date'
    end

    def binder_due_date
      'due_date'
    end

    def broker_full_name
      'broker name'
    end

    def broker_agency_name
      'ageny name'
    end

    def broker_phone
      'broker phone'
    end

    def broker_email
      'broker_email'
    end

    def broker_present?
      false
    end

    def notice_template(notice_kind)
      sanitize_html(notice_kind.template.raw_body.gsub('#{', '<%=').gsub('}','%>').gsub('[[', '<%').gsub(']]', '%>'))
    end
  end
end

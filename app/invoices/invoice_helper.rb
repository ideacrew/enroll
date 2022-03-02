# frozen_string_literal: true

#NOTE : Intention is to make the styles and parts of the code reusable. But there is a lot more scope for improvment  -VBATTULA
module InvoiceHelper
# module Prawn::Graphics

  def default_options
    {
      :width => 250
    }
  end

  def currency_format(number)
    # rubocop:disable Style/FormatString
    number_string = "%.2f" % number
    # rubocop:enable Style/FormatString
    while number_string.sub!(/(\d+)(\d\d\d)/,'\1,\2'); end
    number_string
  end

  def build_pdf
    enrollment_summary = @hbx_enrollments.inject({}) do |hash,enrollment|
      if hash.include?(enrollment.plan.name)
        hash[enrollment.plan.name]["employee_count"] += 1
        hash[enrollment.plan.name]["dependents_count"] += enrollment.humanized_dependent_summary
        hash[enrollment.plan.name]["total_employer_contribution"] += enrollment.total_employer_contribution
        hash[enrollment.plan.name]["total_employee_cost"] += enrollment.total_employee_cost
        hash[enrollment.plan.name]["total_premium"] += enrollment.total_premium
      else
        hash[enrollment.plan.name] = {}
        hash[enrollment.plan.name]["enrollments"] = []
        hash[enrollment.plan.name]["issuer"] = enrollment.plan.carrier_profile.legal_name
        hash[enrollment.plan.name]["employee_count"] = 1
        hash[enrollment.plan.name]["dependents_count"] = enrollment.humanized_dependent_summary
        hash[enrollment.plan.name]["total_employer_contribution"] = enrollment.total_employer_contribution
        hash[enrollment.plan.name]["total_employee_cost"] = enrollment.total_employee_cost
        hash[enrollment.plan.name]["total_premium"] = enrollment.total_premium
      end
      hash[enrollment.plan.name]["enrollments"] << enrollment
      hash
    end

    @pdf = Prawn::Document.new
    cheque_amount_path = 'app/assets/images/cheque_amount.png'
    logopath = "app/assets/images/#{EnrollRegistry[:enroll_app].setting(:mailer_logo_file_name).item}"
    initial_y = @pdf.cursor
    initialmove_y = 25
    address_x = 15
    lineheight_y = 12
    font_size = 11
    address_x_pos = mm2pt(21.83)
    address_y_pos = 790.86 - mm2pt(57.15) - 65
    mpi_x_pos = mm2pt(6.15)
    mpi_y_pos = 57
    @pdf.font "Times-Roman"
    @pdf.font_size font_size

    invoice_header_x = 275
    activity_header_x = 275
    logo_x = 360
    cheque_amount_path_x = 350

    last_measured_y = @pdf.cursor
    @pdf.move_cursor_to @pdf.bounds.height
    @pdf.move_cursor_to last_measured_y

    @pdf.text_box contact_center_mailing_address_name.to_s, :at => [address_x_pos,  @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box contact_center_address_one.to_s, :at => [address_x_pos,  @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box "#{contact_center_city}, #{contact_center_state} #{contact_center_postal_code}", :at => [address_x_pos,  @pdf.cursor]
    @pdf.move_down lineheight_y

    address = mailing_or_primary_address(@organization)
    @pdf.text_box @employer_profile.legal_name.to_s, :at => [address_x_pos, address_y_pos]
    if address
      @pdf.text_box "#{address.address_1}, #{address.address_2}", :at => [address_x_pos, address_y_pos - 12]
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x_pos, address_y_pos - 24]
    end
    @pdf.text_box "SHOP_M031", :at => [mpi_x_pos,  mpi_y_pos]

    @pdf.start_new_page

    @pdf.start_new_page

    payment_page_for_initial_employer if @employer_profile

    @pdf.start_new_page

    @pdf.move_down initialmove_y

    @pdf.image logopath, :width => 150
    @pdf.move_down 12

    @pdf.text_box "#{DateTime.now.next_month.strftime('%m/%Y')} Group Coverage Bill", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold

    @pdf.move_down 48

    invoice_services_data = [
      ["Insurance Carrier Plan", "Covered Subscribers", "Covered Dependents", "New Charges"]
    ]
    enrollment_summary.each do |name,plan_summary|
      invoice_services_data << [name.to_s, (plan_summary['employee_count']).to_s, (plan_summary['dependents_count']).to_s, "$#{currency_format(plan_summary['total_premium'])}"]
    end
    invoice_services_data << ["New charges total", "", "", "$#{currency_format(@hbx_enrollments.map(&:total_premium).sum)}"]
    dchbx_table_item_list(invoice_services_data)

    enrollment_summary.each do |name, summary|
      carrier_plan_services_data = [
        ["Last Name","First Name", "No. of Enrolled (1=EE only)", "Coverage Month", "Employer Cost", "Employee Cost", "Premium"]
      ]
      @pdf.start_new_page

      @pdf.move_down initialmove_y

      @pdf.image logopath, :width => 150

      @pdf.move_down lineheight_y
      @pdf.text_box "Carrier Plan Summary", :align => :center, :style => :bold, :at => [address_x, @pdf.cursor]

      @pdf.move_down 24

      plan_header_data = [
        ["Insurance Carrier Plan","",name.to_s]
      ]

      dchbx_plan_header(plan_header_data)

      @pdf.move_down 24

      @pdf.text_box "Subscriber(s) and Adjustment(s) for Coverage Period: #{DateTime.now.next_month.strftime('%m/%Y')}", :style => :bold, :at => [0, @pdf.cursor]

      @pdf.move_down 24

      summary["enrollments"].each do |enrollment|
        subscriber = enrollment.subscriber.person.employee_roles.try(:first).try(:census_employee)
        carrier_plan_services_data << [subscriber.last_name.to_s, subscriber.first_name.to_s,enrollment.humanized_members_summary.to_s, DateTime.now.next_month.strftime("%m/%Y").to_s,"$#{currency_format(enrollment.total_employer_contribution)}",
                                       "$#{currency_format(enrollment.total_employee_cost)}","$#{currency_format(enrollment.total_premium)}"]
      end
      carrier_plan_services_data << ["PLAN TOTAL", "", "", "", "", "", "$#{currency_format(summary['total_premium'])}"]
      dchbx_table_by_plan(carrier_plan_services_data)
    end

    @pdf.page_count.times do |i|
      next if i < 3
      @pdf.go_to_page(i + 1)
      @pdf.font_size 9
      @pdf.bounding_box([0, @pdf.bounds.bottom + 25], :width => @pdf.bounds.width) do
        @pdf.text_box "Questions? Call the #{EnrollRegistry[:enroll_app].setting(:short_name).item} Customer Service at #{contact_center_phone_number}, go online to #{site_home_url}, or contact your broker.", :at => [address_x, @pdf.bounds.height],
                                                                                                                                                                                                                 :align => :center
      end
    end


    @pdf.page_count.times do |i|
      next if i < 2
      @pdf.go_to_page(i + 1)
      @pdf.bounding_box([0, @pdf.bounds.bottom + 25], :width => @pdf.bounds.width) do
        @pdf.draw_text "Page #{i - 1} of #{@pdf.page_count - 2}",:at => [480, @pdf.bounds.height - 30]
      end
    end

    @pdf
  end

  def mm2pt(mm)
    mm * (72 / 25.4)
  end

  def dchbx_plan_header(data)
    @pdf.table(data, :width => @pdf.bounds.width) do
      style(row(0), :border_color => '000000', :size => 10, :border_width => 0.5, :borders => [:top, :bottom])
      style(row(0).column(0), :borders => [:left,:top, :bottom])
      style(row(0).column(2), :borders => [:right,:top, :bottom])
      style(columns(0), :font_style => :bold, :width => 125)
      style(columns(2), :width => 400, :align => :right)
    end
  end

  def dchbx_table_light_blue(data,position = 25,options = {})
    options = default_options.merge(options)
    @pdf.table(data, :position => position, :width => options[:width]) do
      style(row(0..5).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
      style(row(0..5), :background_color => 'CDDDEE', :border_color => 'dddddd', :font_style => :bold)
      style(column(1), :align => :right)
    end
  end

  def stroke_dashed_horizontal_line(_position = 25,_options = {})
    @pdf.stroke do
      @pdf.move_down 20
      @pdf.dash(5, space: 2, phase: 0)
      @pdf.horizontal_rule
    end
  end

  def dchbx_table_item_list(data,position = 0,options = {})
    # rubocop:disable Lint/UselessAssignment
    options = default_options.merge(options)
    # rubocop:enable Lint/UselessAssignment
    @pdf.table(data, :position => position, :width => @pdf.bounds.width) do
      style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
      style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
      style(row(0).columns(0..-1), :borders => [:top, :bottom])
      style(row(0).columns(0), :borders => [:top, :left, :bottom])
      style(row(0).columns(-1), :borders => [:top, :right, :bottom])
      style(row(-1), :border_width => 2, :font_style => :bold)
      style(column(1..-1), :align => :center)
      style(columns(0), :width => 270)
      style(columns(1), :width => 80)
      style(columns(-1), :align => :right)
    end
  end

  def dchbx_table_by_plan(data,position = 0,options = {})
    # rubocop:disable Lint/UselessAssignment
    options = default_options.merge(options)
    # rubocop:enable Lint/UselessAssignment
    @pdf.table(data, :position => position, :width => @pdf.bounds.width) do
      style(row(1..-1).columns(0..-1), :size => 11, :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
      style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold, :size => 11)
      style(row(0).columns(0..-1), :borders => [:top, :bottom])
      style(row(0).columns(0), :borders => [:top, :left, :bottom])
      style(row(0).columns(-1), :borders => [:top, :right, :bottom])
      style(row(-1), :border_width => 2, :font_style => :bold)
      style(column(1..-1), :align => :center)
      style(columns(-1), :align => :right)
      style(columns(0).row(-1), :width => 80)
      style(columns(2), :width => 60)
      style(columns(3), :width => 60)
      style(columns(4), :width => 60)
      style(columns(5), :width => 70)
    end
  end

  def mailing_or_primary_address(organization)
    office_locations = organization.try(:office_locations)
    mailing_office_locations, primary_office_locations = office_locations.partition { |ol| ol.address.mailing? }
    mailing_office_locations.present? ? mailing_office_locations.first.address : primary_office_locations.first.address
  end

  def payment_page_for_initial_employer
    cheque_amount_path = 'app/assets/images/cheque_amount.png'
    logopath = "app/assets/images/#{EnrollRegistry[:enroll_app].setting(:mailer_logo_file_name).item}"
    initial_y = @pdf.cursor
    initialmove_y = 25
    address_x = 15
    lineheight_y = 12
    font_size = 11
    address_x_pos = mm2pt(21.83)
    address_y_pos = 790.86 - mm2pt(57.15) - 65
    mpi_x_pos = mm2pt(6.15)
    mpi_y_pos = 57
    @pdf.font "Times-Roman"
    @pdf.font_size font_size

    invoice_header_x = 275
    activity_header_x = 275
    logo_x = 360
    cheque_amount_path_x = 350
    @pdf.move_down 36

    @pdf.image logopath, :width => 150, :at => [address_x,  @pdf.cursor]
    invoice_header_data = [
      ["ACCOUNT NUMBER:", @employer_profile.organization.hbx_id.to_s],
      ["INVOICE NUMBER:", "#{@employer_profile.organization.hbx_id}#{DateTime.now.next_month.strftime('%m%Y')}"],
      ["INVOICE DATE:", DateTime.now.strftime("%m/%d/%Y").to_s],
      ["COVERAGE MONTH:", DateTime.now.next_month.strftime("%m/%Y").to_s],
      ["TOTAL AMOUNT DUE:", "$#{currency_format(@hbx_enrollments.map(&:total_premium).sum)}"],
      # ["DATE DUE:", "#{DateTime.now.strftime("%m/14/%Y")}"]
      ["DATE DUE:", PlanYear.calculate_open_enrollment_date(TimeKeeper.date_of_record.next_month.beginning_of_month)[:binder_payment_due_date].strftime("%m/%d/%Y").to_s]
    ]
    dchbx_table_light_blue(invoice_header_data,invoice_header_x)

    address = mailing_or_primary_address(@organization)
    @pdf.text_box @employer_profile.legal_name.to_s, :at => [address_x, 585]
    if address
      @pdf.text_box "#{address.address_1},#{address.address_2}", :at => [address_x, 573]
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 561]
    end

    @pdf.move_down 72
    @pdf.text_box "Please review the billing summary. This is a consolidated bill for all your benefits through the #{site_short_name}. Please pay the Total Amount Due.", :at => [address_x, @pdf.cursor]
    @pdf.move_down 48
    @pdf.text_box "Payment Options", :at => [address_x, @pdf.cursor], :style => :bold
    @pdf.move_down 24
    @pdf.text_box "\u2022 Make a secure online electronic check payment. Use the account number found at the top of your invoice to login at:", :at => [address_x, @pdf.cursor]
    @pdf.move_down 36
    @pdf.text_box site_invoice_bill_url.to_s, :at => [address_x, @pdf.cursor], :align => :center
    @pdf.move_down 24
    @pdf.text_box "\u2022 Return the attached payment coupon with a personal, business, or cashier’s check for prompt, accurate and timely posting of your payment. Address payments to:", :at => [address_x, @pdf.cursor]
    @pdf.move_down 36
    @pdf.text_box contact_center_mailing_address_name.to_s, :at => [240, @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box contact_center_address_one.to_s, :at => [240, @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box "#{contact_center_city}, #{contact_center_state} #{contact_center_postal_code}", :at => [240, @pdf.cursor]
    @pdf.move_down 24
    @pdf.text_box "\u2022 Call the #{site_short_name} Customer Service at 888-813-9220 (TTY #{contact_center_tty_number})", :at => [address_x, @pdf.cursor]
    @pdf.move_down 24

    @pdf.text_box "PLEASE DETACH HERE AND RETURN THE BOTTOM PORTION WITH YOUR PAYMENT", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold
    stroke_dashed_horizontal_line(10, 250)
    @pdf.move_down 36

    @pdf.image logopath, :width => 150, :at => [logo_x, @pdf.cursor]

    dchbx_table_light_blue(invoice_header_data,address_x)

    @pdf.move_down 18
    @pdf.text_box "Amount Enclosed:", :at => [address_x, 112], :align => :center, :style => :bold
    @pdf.image cheque_amount_path, :width => 160, :at => [cheque_amount_path_x, 122]

    @pdf.text_box contact_center_mailing_address_name.to_s, :at => [320,  72]
    @pdf.text_box contact_center_address_one.to_s, :at => [320,  60]
    @pdf.text_box "#{contact_center_city}, #{contact_center_state} #{contact_center_postal_code}", :at => [320,  48]

    address = mailing_or_primary_address(@organization)
    @pdf.text_box @employer_profile.legal_name.to_s, :at => [address_x, 72]
    if address
      @pdf.move_down lineheight_y
      @pdf.text_box address.address_1.to_s, :at => [address_x, 60]
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 48]
    end
  end
end

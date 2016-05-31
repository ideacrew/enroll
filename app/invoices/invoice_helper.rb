#NOTE : Intention is to make the styles and parts of the code reusable. But there is a lot more scope for improvment  -VBATTULA
module InvoiceHelper
# module Prawn::Graphics

	def default_options 
		{
			:width => 250
		}
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

    @pdf=Prawn::Document.new
    cheque_amount_path = 'app/assets/images/cheque_amount.png'
    logopath = 'app/assets/images/logo.png'
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

    @pdf.text_box "DC Health Link", :at => [address_x_pos,  @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box "PO Box 97022", :at => [address_x_pos,  @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box "Washington, DC 20090", :at => [address_x_pos,  @pdf.cursor]
    @pdf.move_down lineheight_y

    address = @organization.try(:office_locations).first.address 
    @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x_pos, address_y_pos]
    if address
      @pdf.text_box "#{address.address_1}, #{address.address_2}", :at => [address_x_pos, address_y_pos-12]
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x_pos, address_y_pos-24]
    end
    @pdf.text_box "MPI_Cover", :at => [mpi_x_pos,  mpi_y_pos]

    @pdf.start_new_page

    @pdf.move_down 36
    #Image
    @pdf.image logopath, :width => 150, :at => [address_x,  @pdf.cursor]
    invoice_header_data = [ 
      ["ACCOUNT NUMBER:", "#{@employer_profile.organization.hbx_id}"],
      ["INVOICE NUMBER:", "123123"],
      ["INVOICE DATE:", "#{DateTime.now.strftime("%m/%d/%Y")}"],
      ["COVERAGE MONTH:", "#{DateTime.now.next_month.strftime("%m/%Y")}"],
      ["TOTAL AMOUNT DUE:", "$#{@hbx_enrollments.map(&:total_premium).sum}"],
      ["DATE DUE:", "#{DateTime.now.strftime("%m/14/%Y")}"]
    ]

    dchbx_table_light_blue(invoice_header_data,invoice_header_x)
    
    @pdf.move_down 60

    address = @organization.try(:office_locations).first.address 
    @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x, 585]
    if address
      @pdf.text_box "#{address.address_1},#{address.address_2}", :at => [address_x, 573]
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 561]
    end
    
    @pdf.move_down 12
    @pdf.text_box "Please review the billing summary. This is a consolidated bill for all your benefits through DC Health Link. Please pay the Total Amount Due.", :at => [address_x, @pdf.cursor]
    @pdf.move_down 48
    @pdf.text_box "Payment Options", :at => [address_x, @pdf.cursor], :style => :bold
    @pdf.move_down 24
    @pdf.text_box "\u2022 Make a secure online electronic check payment. Use the account number found at the top of your invoice to login at:", :at => [address_x, @pdf.cursor]
    @pdf.move_down 36
    @pdf.text_box "https://www.e-BillExpress.com/ebpp/DCHealthPay", :at => [address_x, @pdf.cursor], :align => :center
    @pdf.move_down 24
    @pdf.text_box "\u2022 Return the attached payment coupon with a personal, business, or cashier’s check for prompt, accurate and timely posting of your payment. Address payments to:", :at => [address_x, @pdf.cursor]
    @pdf.move_down 36
    @pdf.text_box "DC Health Link", :at => [240, @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box "PO Box 97022", :at => [240, @pdf.cursor]
    @pdf.move_down lineheight_y
    @pdf.text_box "Washington, DC 20090", :at => [240, @pdf.cursor]
    @pdf.move_down 24
    @pdf.text_box "\u2022 Call DC Health Link Customer Service at 855-532-5465", :at => [address_x, @pdf.cursor]
    @pdf.move_down 24

    @pdf.text_box "PLEASE DETACH HERE AND RETURN THE BOTTOM PORTION WITH YOUR PAYMENT", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold
    stroke_dashed_horizontal_line(10, 250)
    @pdf.move_down 36

    @pdf.image logopath, :width => 150, :at => [logo_x, @pdf.cursor]

    dchbx_table_light_blue(invoice_header_data,address_x)

    @pdf.move_down 18
    @pdf.text_box "Amount Enclosed:", :at => [address_x, 112], :align => :center, :style => :bold
    @pdf.image cheque_amount_path, :width => 160, :at => [cheque_amount_path_x, 122]

    @pdf.text_box "DC Health Link", :at => [320,  72]
    @pdf.text_box "PO Box 97022", :at => [320,  60]
    @pdf.text_box "Washington, DC 20090", :at => [320,  48]
    
    address = @organization.try(:office_locations).first.address 
    @pdf.text_box "#{@employer_profile.legal_name}", :at => [address_x, 72]
    if address
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.address_1}", :at => [address_x, 60]
      @pdf.move_down lineheight_y
      @pdf.text_box "#{address.city}, #{address.state} #{address.zip}", :at => [address_x, 48]
    end


    @pdf.start_new_page
    
    @pdf.move_down initialmove_y

    @pdf.image logopath, :width => 150
    @pdf.move_down 12    

    @pdf.text_box "#{DateTime.now.next_month.strftime("%m/%Y")} Group Coverage Bill(Health & Dental)", :at => [address_x, @pdf.cursor], :align => :center, :style => :bold

    @pdf.move_down 48

    invoice_services_data = [ 
      ["Insurance Carrier Plan", "Covered Subscribers", "Covered Dependents", "New Charges"]
    ]
    enrollment_summary.each do |name,plan_summary| 
      invoice_services_data << ["#{name}", "#{plan_summary['employee_count']}", "#{plan_summary['dependents_count']}", "$#{plan_summary['total_premium']}"]

    end

    dchbx_table_item_list(invoice_services_data)
    @pdf.move_down 5
    @pdf.text_box "New Charges Total", :at => [0, @pdf.cursor], :style => :bold
    @pdf.text "$#{@hbx_enrollments.map(&:total_premium).sum}" , :align => :right, :style => :bold

    enrollment_summary.each do |name, summary| 
      carrier_plan_services_data = [ 
        ["Last 4 SSN", "Last Name","First Name", "No. of Enrolled (1=EE only)", "Coverage Month", "Employer Cost", "Employee Cost", "Premium"]
      ]
      @pdf.start_new_page

      @pdf.move_down initialmove_y
      
      @pdf.image logopath, :width => 150

      @pdf.move_down lineheight_y
      @pdf.text_box "Carrier Plan Summary", :align => :center, :style => :bold, :at => [address_x, @pdf.cursor]

      @pdf.move_down 24
    
      plan_header_data = [
        ["Insurance Carrier Plan","" ,"#{name}"]
      ]

      dchbx_plan_header(plan_header_data)

       @pdf.move_down 24

       @pdf.text_box "Subscriber(s) and Adjustment(s) for Coverage Period: #{DateTime.now.next_month.strftime("%m/%Y")}", :style => :bold, :at => [0, @pdf.cursor]

       @pdf.move_down 24

      summary["enrollments"].each do |enrollment|
        subscriber = enrollment.subscriber.person.employee_roles.try(:first).try(:census_employee)
        carrier_plan_services_data << ["#{subscriber.ssn.split(//).last(4).join}", "#{subscriber.last_name}", "#{subscriber.first_name}","#{enrollment.humanized_dependent_summary}", "#{DateTime.now.next_month.strftime("%m/%Y")}","$#{enrollment.total_employer_contribution}" ,"$#{enrollment.total_employee_cost}"  ,"$#{enrollment.total_premium}"]
      end

      dchbx_table_by_plan(carrier_plan_services_data)

      @pdf.move_down 5
      @pdf.text_box "PLAN TOTAL", :at => [0, @pdf.cursor], :style => :bold
      @pdf.text "$#{summary['total_premium']}", :align => :right, :style => :bold

    end

    @pdf.page_count.times do |i|
      next if i < 2
      @pdf.go_to_page(i+1)
      @pdf.font_size 9
      @pdf.bounding_box([0, @pdf.bounds.bottom + 25], :width => @pdf.bounds.width) {
        @pdf.text_box "Questions? Call DC Health Link Customer Service at 855-532-5465, go online to http://www.dchealthlink.com/, or contact your broker.", :at => [address_x, @pdf.bounds.height], :align => :center
      }
    end


    @pdf.page_count.times do |i|
      next if i < 1
      @pdf.go_to_page(i+1)
      @pdf.bounding_box([0, @pdf.bounds.bottom + 25], :width => @pdf.bounds.width) {
        @pdf.draw_text "Page #{i} of #{@pdf.page_count - 1}",:at => [480, @pdf.bounds.height - 30]
        # @pdf.draw_text "#{Time.now.strftime("%B %d, %Y")}" ,:at => [455, @pdf.bounds.height - 20]
      }
    end

    @pdf
  end
  
  def mm2pt(mm)
    return mm * (72 / 25.4)
  end


	def dchbx_plan_header(data)
		@pdf.table(data, :width => @pdf.bounds.width) do
		  style(row(0), :border_color => '000000', :size => 10, :border_width => 0.5, :borders => [:top, :bottom])
		  style(row(0).column(0), :borders => [:left,:top, :bottom])
		  style(row(0).column(2), :borders => [:right,:top, :bottom])
		  style(columns(0), :font_style => :bold, :width => 125, )
		  style(columns(2), :width => 200, :align => :right)
		end
	end

	def dchbx_table_light_blue(data,position=25,options={})
		options=default_options.merge(options)
	  @pdf.table(data, :position => position, :width => options[:width]) do
      style(row(0..5).columns(0..1), :padding => [1, 5, 1, 5], :borders => [])
      style(row(0..5), :background_color => 'CDDDEE', :border_color => 'dddddd', :font_style => :bold)
      style(column(1), :align => :right)
    end
	end


	def dchbx_table_with_border(data,position=25,options={})
		options=default_options.merge(options)
	  @pdf.table(data, :position => position, :width => options[:width]) do
	      style(row(0..5).columns(0..1), :padding => [1, 5, 1, 5], :borders => [], :font_style => :bold,)
	      style(row(0), :font_style => :italic)
	      style(column(1), :align => :right)
	      style(row(0..5).column(0), :borders => [:left])
	      style(row(0..5).column(1), :borders => [:right])
	      style(row(5).column(0), :borders => [:left, :bottom])
	      style(row(5).column(1), :borders => [:right, :bottom])
	      style(row(0).column(0), :borders => [:left, :top])
	      style(row(0).column(1), :borders => [:right, :top])
    end
  end

  def stroke_dashed_horizontal_line(position=25,options={})
    @pdf.stroke do 
      @pdf.move_down 20
      @pdf.dash(5, space: 2, phase: 0)
      @pdf.horizontal_rule
    end
  end

  def dchbx_table_item_list(data,position=0,options={})
  	options=default_options.merge(options)
  	@pdf.table(data, :position=> position, :width => @pdf.bounds.width) do
      style(row(1..-1).columns(0..-1), :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
      style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold)
      style(row(0).columns(0..-1), :borders => [:top, :bottom])
      style(row(0).columns(0), :borders => [:top, :left, :bottom])
      style(row(0).columns(-1), :borders => [:top, :right, :bottom])
      style(row(-1), :border_width => 2)
      style(column(1..-1), :align => :center)
      style(columns(0), :width => 270)
      style(columns(1), :width => 80)
    end
  end

  def dchbx_table_by_plan(data,position=0,options={})
    options=default_options.merge(options)
    @pdf.table(data, :position=> position, :width => @pdf.bounds.width) do
      style(row(1..-1).columns(0..-1), :size => 11, :padding => [4, 5, 4, 5], :borders => [:bottom], :border_color => 'dddddd')
      style(row(0), :background_color => 'e9e9e9', :border_color => 'dddddd', :font_style => :bold, :size => 11)
      style(row(0).columns(0..-1), :borders => [:top, :bottom])
      style(row(0).columns(0), :borders => [:top, :left, :bottom])
      style(row(0).columns(-1), :borders => [:top, :right, :bottom])
      style(row(-1), :border_width => 2)
      style(column(1..-1), :align => :center)
      style(columns(0), :width => 40)
      style(columns(3), :width => 60)
      style(columns(4), :width => 60)
      style(columns(5), :width => 60)
      style(columns(6), :width => 70)
    end
  end
end
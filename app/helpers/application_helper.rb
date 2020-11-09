module ApplicationHelper
  include FloatHelper

  def can_employee_shop?(date)
    return false if date.blank?
    date = Date.strptime(date.to_s,"%m/%d/%Y")
    Plan.has_rates_for_all_carriers?(date) == false
  end

  def rates_available?(employer, date=nil)
    employer.applicant? && !Plan.has_rates_for_all_carriers?(date) ? "blocking" : ""
  end

  def product_rates_available?(benefit_sponsorship, date=nil)
    date = Date.strptime(date.to_s, '%m/%d/%Y') if date.present?
    return false if benefit_sponsorship.present? && benefit_sponsorship.active_benefit_application.present?
    date = date || BenefitSponsors::BenefitApplications::BenefitApplicationSchedular.new.calculate_start_on_dates[0]
    benefit_sponsorship.applicant? && BenefitMarkets::Forms::ProductForm.for_new(date).fetch_results.is_late_rate
  end

  def deductible_display(hbx_enrollment, plan)
    if hbx_enrollment.hbx_enrollment_members.size > 1
      plan.family_deductible.split("|").last.squish
    else
      plan.deductible
    end
  end

  def draft_plan_year?(plan_year)
    if plan_year.aasm_state == "draft" && plan_year.try(:benefit_groups).empty?
      plan_year
    end
  end

  def get_portals_text(insured, employer, broker)
    my_portals = []
    if insured == true
      my_portals << "<strong>Insured</strong>"
    end
    if employer == true
      my_portals << "<strong>Employer</strong>"
    end
    if broker == true
      my_portals << "<strong>Broker</strong>"
    end
    my_portals.to_sentence
  end

  def copyright_notice
    if TimeKeeper.date_of_record.year.to_s == site_copyright_period_start.to_s
      copyright_attribution = "#{site_copyright_period_start} #{Settings.site.long_name}"
    else
      copyright_attribution = "#{site_copyright_period_start}-#{TimeKeeper.date_of_record.year} #{Settings.site.long_name}"
    end
    raw("<span class='copyright'><i class='far fa-copyright fa-lg' aria-hidden='true'></i> #{copyright_attribution}. All Rights Reserved. </span>")
  end

  def menu_tab_class(a_tab, current_tab)
    (a_tab == current_tab) ? raw(" class=\"active\"") : ""
  end

  #Purchased enrollment family premium (family home page - view details button on the enrollment)
  def current_cost(hbx_enrollment = nil, source = nil)
    # source is account or shopping
    return unless source == 'account' && hbx_enrollment.present? && hbx_enrollment.coverage_kind == 'health'

    (hbx_enrollment.total_premium - hbx_enrollment.applied_aptc_amount.to_f)
  end

  #Shopping enrollment family premium (plan shopping page)
  def shopping_group_premium(plan_cost, plan_ehb_cost, can_use_aptc=true)
    return plan_cost unless session['elected_aptc'].present? && session['max_aptc'].present? && can_use_aptc

    aptc_amount = session['elected_aptc'].to_f
    cost = float_fix(plan_cost - [plan_ehb_cost, aptc_amount].min)
    cost > 0 ? cost.round(2) : 0
  end

  def datepicker_control(f, field_name, options = {}, value = "")
    sanitized_field_name = field_name.to_s.sub(/\?$/,"")
    opts = options.dup
    obj_name = f.object_name
    obj_val = f.object.send(field_name.to_sym)
    current_value = obj_val.blank? ? value : obj_val.is_a?(DateTime) ? obj_val.strftime("%m/%d/%Y") : obj_val
    html_class_list = opts.delete(:class) { |k| "" }
    jq_tag_classes = (html_class_list.split(/\s+/) + ["jq-datepicker"]).join(" ")
    generated_field_name = "jq_datepicker_ignore_#{obj_name}[#{sanitized_field_name}]"
    provided_id = options[:id] || options["id"]
    generate_target_id = nil
    if !provided_id.blank?
      generated_target_id = "#{provided_id}_jq_datepicker_plain_field"
    end
    sanitized_object_name = "#{obj_name}_#{sanitized_field_name}".delete(']').tr('^-a-zA-Z0-9:.', "_")
    generated_target_id ||= "#{sanitized_object_name}_jq_datepicker_plain_field"
    capture do
      concat f.text_field(field_name, opts.merge(:class => html_class_list, :id => generated_target_id, :value=> obj_val.try(:to_s, :db)))
      concat text_field_tag(generated_field_name, current_value, opts.merge(:class => jq_tag_classes, :start_date => "07/01/2016", :style => "display: none;", "data-submission-field" => "##{generated_target_id}"))
    end
  end

  def generate_breadcrumbs(breadcrumbs)
    html = "<ul class='breadcrumb'>".html_safe
    breadcrumbs.each_with_index do |breadcrumb, index|
      if breadcrumb[:path]
        html += "<li>".html_safe + link_to(breadcrumb[:name], breadcrumb[:path], data: breadcrumb[:data])
        html += "<span class='divider'></span>".html_safe if index < breadcrumbs.length-1
        html += "</li>".html_safe
      else
        html += "<li class='active #{breadcrumb[:class]}'>".html_safe + breadcrumb[:name]
        html += "<span class='divider'></span>".html_safe if index < breadcrumbs.length-1
        html += "</li>".html_safe
      end
    end
    html += "</ul>".html_safe
    return html
  end

  # Formats version information in HTML string for the referenced object instance
  def version_for_record(obj)
    ver  = "version: #{obj.version}" if obj.respond_to?('version')
    date = "updated: #{format_date(obj.updated_at)}" if obj.respond_to?('updated_at')
    who  = "by: #{obj.updated_by}"if obj.respond_to?('updated_by')
    [ver, date, who].reject(&:nil? || empty?).join(' | ')
  end

  def format_date(date_value)
    date_value.strftime("%m/%d/%Y") if date_value.respond_to?(:strftime)
  end

  def format_datetime(date_value)
    date_value.to_time.strftime("%m/%d/%Y %H:%M %Z %:z") if date_value.respond_to?(:strftime)
  end

  def group_xml_transmitted_message(employer)
    employer.xml_transmitted_timestamp.present? ? "The group xml for employer #{employer.legal_name} was transmitted on #{format_time_display(employer.xml_transmitted_timestamp)}. Are you sure you want to transmit again?" : "Are you sure you want to transmit the group xml for employer #{employer.legal_name}?"
  end

  def format_time_display(timestamp)
    timestamp.present? ? timestamp.in_time_zone('Eastern Time (US & Canada)') : ""
  end

  # Builds a Dropdown button
  def select_dropdown(input_id, list)
    return unless list.is_a? Array
    content_tag(:select, class: "form-control", id: input_id) do
      concat(content_tag :option, "Select", value: "")
      list.each do |item|
        if item.is_a? Array
          concat(content_tag :option, item[0], value: item[1])
        else
          concat(content_tag :option, item.humanize, value: item)
        end
      end
    end
  end

  # Formats first data row in a table indicating an empty set
  def table_empty_to_human
    content_tag(:tr, (content_tag(:td, "None given")))
  end

  def transaction_status_to_label(ed)
    if ed.open?
      content_tag(:span, "#{ed.aasm_state}", class: "label label-warning")
    elsif ed.assigned?
      content_tag(:span, "#{ed.aasm_state}", class: "label label-info")
    else
      content_tag(:span, "#{ed.aasm_state}", class: "label label-success")
    end
  end

  # Formats a full name into upper/lower case with last name wrapped in HTML <strong> tag
  def name_to_listing(person)
    given_name = [person.first_name, person.middle_name].reject(&:nil? || empty?).join(' ')
    sir_name  = content_tag(:strong, mixed_case(person.last_name))
    raw([mixed_case(given_name), sir_name, person.name_sfx].reject(&:nil? || empty?).join(' '))
  end

  # Formats each word in a string to capital first character and lower case for all other characters
  def mixed_case(str)
    (str.downcase.gsub(/\b\w/) {|first| first.upcase }) unless str.nil?
  end

  # Formats a boolean value into 'Yes' or 'No' string
  def boolean_to_human(test)
    test ? "Yes" : "No"
  end

  # Uses a boolean value to return an HTML checked/unchecked glyph
  def boolean_to_glyph(test)
    test ? content_tag(:span, "", class: "far fa-check-square aria-hidden='true'") : content_tag(:span, "", class: "far fa-square aria-hidden='true'")
  end

  # Uses a boolean value to return an HTML checked/unchecked glyph with hover text
  def prepend_glyph_to_text(test)
    test.event_name ? "<i class='fa fa-link' data-toggle='tooltip' title='#{test.event_name}'></i>&nbsp;&nbsp;&nbsp;&nbsp;#{link_to test.notice_number, notifier.preview_notice_kind_path(test), target: '_blank'}".html_safe : "<i class='fa fa-link' data-toggle='tooltip' style='color: silver'></i>&nbsp;&nbsp;&nbsp;&nbsp;#{link_to test.notice_number, notifier.preview_notice_kind_path(test), target: '_blank'}".html_safe
  end

  # Formats a number into a 9-digit US Social Security Number string (nnn-nn-nnnn)
  def number_to_ssn(number)
    return unless number
    delimiter = "-"
    number.to_s.gsub!(/(\d{0,3})(\d{2})(\d{4})$/,"\\1#{delimiter}\\2#{delimiter}\\3")
  end

  # Formats a number into a US Social Security Number string (nnn-nn-nnnn), hiding all but last 4 digits
  def number_to_obscured_ssn(number)
    return unless number
    number_to_ssn(number)
    number.to_s.gsub!(/\w{3}-\w{2}/, '***-**')
  end

  # Formats a number into a nine-digit US Federal Entity Identification Number string (nn-nnnnnnn)
  def number_to_fein(number)
    return unless number
    delimiter = "-"
    number.to_s.gsub!(/(\d{0,2})(\d{7})$/,"\\1#{delimiter}\\2")
  end

  # Formats a number into a nine-digit US Federal Entity Identification Number string (nn-nnnnnn), hiding all but last 4 digits
  def number_to_obscured_fein(number)
    return unless number
    number[0,5] = "**-***"
    number
  end

  # Formats a string into HTML, concatenating it with a person glyph
  def prepend_glyph_to_name(name)
    content_tag(:span, raw("&nbsp;"), class: "glyphicon glyphicon-user") + name
  end

  # Formats a string into HTML, concatenating it with a male glyph
  def prepend_male_glyph_to_name(name)
    content_tag(:i, class: "fa fa-male") + name
  end

  # Formats a string into HTML, concatenating it with a female glyph
  def prepend_female_glyph_to_name(name)
    content_tag(:i, raw("&nbsp;"), class: "fa fa-female") + name
  end

  # Formats a string into HTML, concatenating it with a child glyph
  def prepend_child_glyph_to_name(name)
    content_tag(:i, raw("&nbsp;"), class: "fa fa-child") + name
  end

  # Formats a Font Awesome icon in HTML
  def prepend_fa_icon(fa_icon, str)
    content_tag(:i, raw("&nbsp;"), class: "fa fa-#{fa_icon}") + str
  end

  def active_menu_item(label, path, controller = nil)
    li_start = (params[:controller] == controller.to_s) ? "<li class=\"active\">" : "<li>"
    li_start + link_to(label, path) + "</li>"
  end

  def active_dropdown_classes(*args)
    args.map(&:to_s).include?(params[:controller].to_s) ? "dropdown active" : "dropdown"
  end

  def link_to_add_fields(name, f, association, classes='')
    new_object = f.object.send(association).klass.new
    id = new_object.object_id

    # TODO add ability to build nested attributes dynamically
    if f.object.send(association).klass == OfficeLocation
      new_object.build_address
      new_object.build_phone
    end

    if f.object.send(association).klass == BenefitGroup
      new_object.build_relationship_benefits
      new_object.build_composite_tier_contributions
      new_object.build_dental_relationship_benefits
    end


    fields = f.fields_for(association, new_object, fieldset: false, child_index: id) do |builder|
      render("shared/" + association.to_s.singularize + "_fields", f: builder)
    end
    link_to(content_tag(:span, raw("&nbsp;"), class: 'fui-plus-circle') + name,
            '#', class: "add_fields #{classes}", data: {id: id, fields: fields.gsub("\n", "")})
  end

  def render_flash
    rendered = []
    flash.each do |type, messages|
      if messages.respond_to?(:each)
        messages.each do |m|
          rendered << render(:partial => 'layouts/flash', :locals => {:type => type, :message => m}) unless m.blank?
        end
      else
        rendered << render(:partial => 'layouts/flash', :locals => {:type => type, :message => messages}) unless messages.blank?
      end
    end
    rendered.join('').html_safe
  end

  def dd_value(val)
    val.blank? ? "&nbsp;" : val
  end

  def sortable(column, title = nil)
    fui = params[:direction] == "desc" ? "down" : "up"
    title ||= column.titleize
    css_class = (column == sort_column) ? "fui-triangle-#{fui}-small" : nil
    direction = (column == params[:sort] && params[:direction] == "desc") ? "asc" : "desc"
    ((link_to title, params.merge(:sort => column, :direction => direction, :page => nil) ) + content_tag(:sort, raw("&nbsp;"), class: css_class))
  end

  def extract_phone_number(phones, type)
    phone = phones.select{|phone| phone.kind == type}
    if phone.present?
      phone = phone.first
      phone = phone.area_code.present? ? "#{phone.area_code} #{phone.number}" : nil
    else
      phone = nil
    end
    return phone
  end

# the following methods are used when we are embedding devise signin and signup pages in views other than devise.
  def resource_name
    :user
  end

  def resource
    @resource ||= User.new
  end

  def devise_mapping
    @devise_mapping ||= Devise.mappings[:user]
  end

  def get_dependents(family, person)
    members_list = []
    family_members = family.family_members
    family_members.each {|f| members_list << f.person } if family_members.present?
    return members_list
  end

  def add_progress_class(element_number, step)
    if element_number < step
      'complete'
    elsif element_number == step
      'active'
    end
  end

  def user_full_name
    if signed_in?
      current_user.person.try(:full_name) ? current_user.person.full_name : current_user.oim_id
    end
  end

  def user_first_name_last_name_and_suffix
    if signed_in?
      current_user.person.try(:first_name_last_name_and_suffix) ? current_user.person.first_name_last_name_and_suffix : (current_user.oim_id).downcase
    end
  end

  def retrieve_show_path(provider, message)
    return broker_agencies_inbox_path(provider, message_id: message.id) if provider.try(:broker_role)
    case(provider.model_name.name)
    when "Person"
      insured_inbox_path(provider, message_id: message.id)
    when "EmployerProfile"
      employers_inbox_path(provider, message_id: message.id)
    when "BrokerAgencyProfile"
      broker_agencies_inbox_path(provider, message_id: message.id)
    when "HbxProfile"
      exchanges_inbox_path(provider, message_id: message.id)
    when "GeneralAgencyProfile"
      general_agencies_inbox_path(provider, message_id: message.id)
    end
  end

  def retrieve_inbox_path(provider, folder: 'inbox')
    broker_agency_mailbox =  broker_agencies_profile_inbox_path(profile_id: provider.id, folder: folder)
    return broker_agency_mailbox if provider.try(:broker_role)
    case(provider.model_name.name)
    when "EmployerProfile"
      inbox_employers_employer_profiles_path(id: provider.id, folder: folder)
    when "HbxProfile"
      inbox_exchanges_hbx_profile_path(provider, folder: folder)
    when "BrokerAgencyProfile"
      broker_agencies_profile_inbox_path(profile_id: provider.id, folder: folder)
    when "Person"
      inbox_insured_families_path(profile_id: provider.id, folder: folder)
    when "GeneralAgencyProfile"
      inbox_general_agencies_profiles_path(profile_id: provider.id, folder: folder)
    end
  end

  def get_header_text(controller_name)
      portal_display_name(controller_name)
  end

  def can_register_new_account
    # Do this once we have invites working:
    # !params[:invitation_id].blank?
    true
  end

  def override_backlink
    link=''
    if current_user.try(:has_hbx_staff_role?)
      link = link_to 'HBX Portal', exchanges_hbx_profile_path(id: 1)
    elsif current_user.try(:has_broker_agency_staff_role?)
      link = link_to 'Broker Agency Portal',broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id)
    end
    return link
  end

  def carrier_logo(plan)
    if plan.extract_value.class.to_s == "Plan"
      return "" if !plan.carrier_profile.legal_name.extract_value.present?
      issuer_hios_id = plan.hios_id[0..4].extract_value
      Settings.aca.carrier_hios_logo_variant[issuer_hios_id] || plan.carrier_profile.legal_name.extract_value
    else
      return '' if plan.extract_value.issuer_profile.legal_name.nil?

      issuer_hios_id = plan.hios_id[0..4].extract_value
      Settings.aca.carrier_hios_logo_variant[issuer_hios_id] || plan.issuer_profile.legal_name.extract_value
    end
  end

  def display_carrier_logo(plan, options = {:width => 50})
    carrier_name = carrier_logo(plan)
    image_tag("logo/carrier/#{carrier_name.parameterize.underscore}.jpg", width: options[:width]) # Displays carrier logo (Delta Dental => delta_dental.jpg)
  end

  def digest_logos
    carrier_logo_hash = Hash.new(carriers:{})
    carriers = ::BenefitSponsors::Organizations::Organization.issuer_profiles
    carriers.each do |car|
      if Rails.env == "production"
        image = "logo/carrier/#{car.legal_name.parameterize.underscore}.jpg"
        digest_image = "/assets/#{::Sprockets::Railtie.build_environment(Rails.application).find_asset(image)&.digest_path}"
        carrier_logo_hash[car.legal_name] = digest_image
      else
        image = "/assets/logo/carrier/#{car.legal_name.parameterize.underscore}.jpg"
        carrier_logo_hash[car.legal_name] = image
      end
    end
    carrier_logo_hash
  end

  def display_carrier_pdf_logo(plan, options = {:width => 50})
    carrier_name = carrier_logo(plan)
    image_tag(wicked_pdf_asset_base64("logo/carrier/#{carrier_name.parameterize.underscore}.jpg"), width: options[:width]) # Displays carrier logo (Delta Dental => delta_dental.jpg)
  end

  def dob_in_words(age, dob)
    return age if age > 0
    time_ago_in_words(dob)
  end

  def date_col_name_for_broker_roaster
    if controller_name == 'applicants'
      case @status
      when 'active'
        'Accepted Date'
      when 'broker_agency_terminated'
        'Terminated Date'
      when 'broker_agency_declined'
        'Declined Date'
      else
      end
    else
      case @status
      when 'applicant'
        'Submitted Date'
      when 'certified'
        'Certified Date'
      when 'decertified'
        'Decertified Date'
      when 'denied'
        'Denied Date'
      when 'extended'
        'Extended Date'
      else
      end
    end
  end

  def relationship_options(dependent, referer)
    relationships = referer.include?("consumer_role_id") || @person.try(:is_consumer_role_active?) ?
      BenefitEligibilityElementGroup::Relationships_UI - ["self"] :
      PersonRelationship::Relationships_UI
    options_for_select(relationships.map{|r| [r.to_s.humanize, r.to_s] }, selected: dependent.try(:relationship))
  end

  def enrollment_progress_bar(plan_year, p_min, options = {:minimum => true})
    progress_bar_width = 0
    progress_bar_class = ''
    return if plan_year.nil?
    return if plan_year.employer_profile.census_employees.active.count > 200

    eligible = plan_year.eligible_to_enroll_count
    enrolled = plan_year.total_enrolled_count
    non_owner = plan_year.non_business_owner_enrolled.count
    covered = plan_year.progressbar_covered_count
    waived = plan_year.waived_count
    p_min = 0 if p_min.nil?
    
    unless eligible.zero?
      condition = enrolled >= p_min && non_owner > 0
      condition = false if covered == 0 && waived > 0
      progress_bar_class = condition ? 'progress-bar-success' : 'progress-bar-danger'
      progress_bar_width = (enrolled * 100)/eligible
    end

    content_tag(:div, class: 'progress-wrapper employer-dummy') do
      content_tag(:div, class: 'progress') do
        concat(content_tag(:div, class: "progress-bar #{progress_bar_class} progress-bar-striped", style: "width: #{progress_bar_width}%;", role: 'progressbar', aria: {valuenow: "#{enrolled}", valuemin: "0", valuemax: "#{eligible}"}, data: {value: "#{enrolled}"}) do
          concat content_tag(:span, '', class: 'sr-only')
        end)

        if eligible > 1
          concat content_tag(:small, enrolled, class: 'progress-current', style: "left: #{progress_bar_width - 2}%;")
        end

        if eligible >= 2 && plan_year.employee_participation_ratio_minimum != 0
          eligible_text = (options[:minimum] == false) ? "#{p_min}<br>(Minimum)" : "<i class='fa fa-circle manual' data-toggle='tooltip' title='Minimum Requirement' aria-hidden='true'></i>".html_safe
          concat content_tag(:p, eligible_text.html_safe, class: 'divider-progress', data: {value: "#{p_min}"}) 
        end

        concat(content_tag(:div, class: 'progress-val') do
          concat content_tag(:strong, '0', class: 'pull-left') if (options[:minimum] == false)
          concat content_tag(:strong, (options[:minimum] == false) ? eligible : '', data: {value: "#{eligible}"}, class: 'pull-right')
        end)
      end
    end
  end

  def is_readonly(object)
    return false if current_user.roles.include?("hbx_staff") # can edit, employer census roster
    return true if object.try(:linked?)  # cannot edit, employer census roster
    return !(object.new_record? or object.try(:eligible?)) # employer census roster
  end

  def may_update_census_employee?(census_employee)
    if current_user.roles.include?("hbx_staff") || census_employee.new_record? || census_employee.is_eligible?
      true
    else
      false
    end
  end

  def calculate_participation_minimum
    if @current_plan_year.present?
      if @current_plan_year.eligible_to_enroll_count == 0
        0
      else
        (@current_plan_year.eligible_to_enroll_count * @current_plan_year.employee_participation_ratio_minimum).ceil
      end
    end
  end

  def notice_eligible_enrolles(notice)
    notice.enrollments.inject([]) do |enrollees, enrollment|
      enrollees += enrollment.enrollees
    end.uniq
  end

  def show_oop_pdf_link(aasm_state)
    return false if aasm_state.blank?

    BenefitSponsors::BenefitApplications::BenefitApplication::SUBMITTED_STATES.include?(aasm_state.to_sym)
  end

  def calculate_age_by_dob(dob)
    now = TimeKeeper.date_of_record
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end

  def is_under_open_enrollment?
    HbxProfile.current_hbx.present? ? HbxProfile.current_hbx.under_open_enrollment? : nil
  end

  def ivl_enrollment_effective_date
    HbxProfile.current_hbx.try(:benefit_sponsorship).try(:earliest_effective_date)
  end

  def parse_ethnicity(value)
    return "" unless value.present?
    value = value.select{|a| a.present? }  if value.present?
    value.present? ? value.join(", ") : ""
  end

  def incarceration_cannot_purchase(family_member)
    pronoun = family_member.try(:gender)=='male' ? ' he ':' she '
    name=family_member.try(:first_name) || ''
    "Since " + name + " is currently incarcerated," + pronoun + "is not eligible to purchase a plan on #{Settings.site.short_name}.<br/> Other family members may still be eligible to enroll."
  end

  def purchase_or_confirm
    'Confirm'
  end

  def qualify_qle_notice
    content_tag(:span) do
      concat "In order to purchase benefit coverage, you must be in either an Open Enrollment or Special Enrollment period. "
      concat link_to("Click here", find_sep_insured_families_path)
      concat " to see if you qualify for a Special Enrollment period"
    end
  end

  def trigger_notice_observer(recipient, event_object, notice_event, params={})
    observer = BenefitSponsors::Observers::NoticeObserver.new
    observer.deliver(recipient: recipient, event_object: event_object, notice_event: notice_event, notice_params: params)
  end

  def disable_purchase?(disabled, hbx_enrollment, options = {})
    disabled || !hbx_enrollment.can_select_coverage?(qle: options[:qle])
  end

  def get_key_and_bucket(uri)
    splits = uri.split('#')
    key = splits.last
    bucket =splits.first.split(':').last
    [key, bucket]
  end

  def env_bucket_name(bucket_name)
    aws_env = ENV['AWS_ENV'] || "qa"
    "dchbx-enroll-#{bucket_name}-#{aws_env}"
  end

  def display_dental_metal_level(plan)
    if plan.class == Plan || (plan.is_a?(Maybe) && plan.extract_value.class.to_s == 'Plan')
      return plan.metal_level.to_s.titleize if plan.coverage_kind.to_s == 'health'

      (plan.active_year == 2015 ? plan.metal_level : plan.dental_level).try(:to_s).try(:titleize) || ""
    else
      return plan.metal_level_kind.to_s.titleize if plan.kind.to_s == 'health'

      (plan.active_year == 2015 ? plan.metal_level_kind : plan.dental_level).try(:to_s).try(:titleize) || ""
    end
  end

  def ivl_metal_network(plan)
    (plan.nationwide ? 'nationwide' : 'dc metro') if plan.benefit_market_kind == :aca_individual
  end

  def ivl_hsa_status(plan_hsa_status, plan)
    (plan_hsa_status[plan.id.to_s]) if plan.benefit_market_kind == :aca_individual
  end

  def products_count(products)
    return 0 unless products

    products.count
  end

  def network_type(product)
    if product.nationwide
      'Nationwide'
    elsif product.dc_in_network
      'DC-Metro'
    end
  end

  def make_binder_checkbox_disabled(employer)
    eligibility_criteria(employer)
    (@participation_count == 0 && @non_owner_participation_rule == true) ? false : true
  end

  def favorite_class(broker_role, general_agency_profile)
    return "" if broker_role.blank?

    if broker_role.included_in_favorite_general_agencies?(general_agency_profile.id)
      "glyphicon-star"
    else
      "glyphicon-star-empty"
    end
  end

  def show_default_ga?(general_agency_profile, broker_agency_profile)
    return false if general_agency_profile.blank? || broker_agency_profile.blank?
    broker_agency_profile.default_general_agency_profile == general_agency_profile
  end

  def asset_data_base64(path)
    asset = ::Sprockets::Railtie.build_environment(Rails.application).find_asset(path)
    throw "Could not find asset '#{path}'" if asset.nil?
    base64 = Base64.encode64(asset.to_s).gsub(/\s+/, "")
    "data:#{asset.content_type};base64,#{Rack::Utils.escape(base64)}"
  end

  def find_plan_name(hbx_id)
    HbxEnrollment.where(id: hbx_id).first.try(:plan).try(:name)
  end

  def has_new_hire_enrollment_period?(census_employee)
    census_employee.new_hire_enrollment_period.present?
  end

  def eligibility_criteria(employer)
    return unless employer.respond_to?(:show_plan_year)
    show_plan_year = employer.show_plan_year
    if show_plan_year.present?
      participation_rule_text = participation_rule_for_plan_year(show_plan_year)
      non_owner_participation_rule_text = non_owner_participation_rule_for_plan_year(show_plan_year)
      text = (@participation_count == 0 && @non_owner_participation_rule == true ? "Yes" : "No")
      eligibility_text = ("Criteria Met : #{text}" + "<br>" + participation_rule_text + "<br>" + non_owner_participation_rule_text).html_safe
      if text == "Yes"
        "Eligible"
      else
        "Ineligible"
        #{}"<i class='fa fa-info-circle' data-html='true' data-placement='top' aria-hidden='true' data-toggle='tooltip' title='#{eligibility_text}'></i>".html_safe
      end
    else
      "Ineligible"
    end
  end

  def participation_rule_for_plan_year(plan_year)
    @participation_count = plan_year.additional_required_participants_count

    if @participation_count == 0
      "1. 2/3 Rule Met? : Yes"
    else
      "1. 2/3 Rule Met? : No (#{@participation_count} more required)"
    end
  end

  def eligibility_criteria_for_export(employer)
    if employer.show_plan_year.present?
      @participation_count == 0 && @non_owner_participation_rule == true ? "Eligible" : "Ineligible"
    else
      "Ineligible"
    end
  end

  def participation_rule(employer)
    participation_rule_for_plan_year(employer.show_plan_year)
  end

  def non_owner_participation_rule_for_plan_year(plan_year)
    # fix me compare with total enrollments
    # fix me once new model enrollment and benefit group assignments got fixed
    @non_owner_participation_rule = plan_year.assigned_census_employees_without_owner.present?
    if @non_owner_participation_rule == true
      "2. Non-Owner exists on the roster for the employer"
    else
      "2. You have 0 non-owner employees on your roster"
    end
  end

  def non_owner_participation_rule(employer)
    # fix me compare with total enrollments
    # fix me once new model enrollment and benefit group assignments got fixed
    non_owner_participation_rule_for_plan_year(employer.show_plan_year)
  end

  def is_new_paper_application?(current_user, app_type)
    app_type = app_type&.downcase
    current_user.has_hbx_staff_role? && app_type == "paper"
  end

  def is_new_in_person_application?(current_user, app_type)
    app_type = app_type&.humanize&.downcase
    current_user.has_hbx_staff_role? && app_type == "in person"
  end

  def load_captcha_widget?
    !Rails.env.test?
  end

  def previous_year
    TimeKeeper.date_of_record.prev_year.year
  end

  def resident_application_enabled?
    if Settings.aca.individual_market.dc_resident_application
      policy(:family).hbx_super_admin_visible?
    else
      false
    end
  end

  def can_show_covid_message_on_sep_carousel?(person)
    return false unless sep_carousel_message_enabled?
    return false unless person.present?
    return true if person.consumer_role.present? || person.resident_role.present?
    person&.active_employee_roles&.any?{ |employee_role| employee_role.market_kind == 'shop'}
  end

  def transition_family_members_link_type row, allow
    if Settings.aca.individual_market.transition_family_members_link
      allow && row.primary_applicant.person.has_consumer_or_resident_role? ? 'ajax' : 'disabled'
    else
      "disabled"
    end
  end

  def convert_to_bool(val)
    return true if val == true || val == 1  || val =~ (/^(true|t|yes|y|1)$/i)
    return false if val == false || val == 0 || val =~ (/^(false|f|no|n|0)$/i)
    raise(ArgumentError, "invalid value for Boolean: \"#{val}\"")
  end

  def plan_match_dc
    Settings.checkbook_services.plan_match == "DC"
  end

  def exchange_icon_path(icon)
    site_key = Settings.site.key
      "icons/#{site_key}-#{icon}"
  end

  def benefit_application_summarized_state(benefit_application)
    return if benefit_application.nil?
    aasm_map = {
      :draft => :draft,
      :enrollment_open => :enrolling,
      :enrollment_eligible => :enrolled,
      :binder_paid => :enrolled,
      :approved => :published,
      :pending => :publish_pending
    }

    renewing = benefit_application.predecessor_id.present? && [:active, :terminated, :termination_pending].exclude?(benefit_application.aasm_state) ? "Renewing" : ""
    summary_text = aasm_map[benefit_application.aasm_state] || benefit_application.aasm_state
    summary_text = "#{renewing} #{summary_text.to_s.humanize.titleize}"
    return summary_text.strip
  end

  def json_for_plan_shopping_member_groups(member_groups)
    member_groups.map do |member_group|
      member_group_hash = JSON.parse(member_group.group_enrollment.to_json)
      member_group_hash['product'].merge!(
        "issuer_name" => member_group.group_enrollment.product.issuer_profile.legal_name,
        "product_type" => member_group.group_enrollment.product.product_type
      )
      member_group_hash
    end.to_json
  end

  def can_access_pay_now_button
    hbx_staff_role = current_user.person.hbx_staff_role
    return true if hbx_staff_role.blank?

    hbx_staff_role.permission.can_access_pay_now
  end

  def float_fix(float_number)
    BigDecimal((float_number).to_s).round(8).to_f
  end

  def round_down_float_two_decimals(float_number)
    BigDecimal((float_number).to_s).round(8).round(2, BigDecimal::ROUND_DOWN).to_f
  end

  def external_application_configured?(application_name)
    external_app = ::ExternalApplications::ApplicationProfile.find_by_application_name(application_name)
    return false unless external_app
    return false unless external_app.is_authorized_for?(current_user)
    !external_app.url.blank?
  end

  def jwt_for_external_application
    current_token = WhitelistedJwt.newest
    return current_token.token if current_token
    current_user.generate_jwt(warden.config[:default_scope], nil)
  end

  def csr_percentage_options_for_select
    EligibilityDetermination::CSR_PERCENT_VALUES.inject([]) do |csr_options, csr|
      ui_display = csr == '-1' ? 'limited' : csr
      csr_options << [ui_display, csr]
    end
  end

  def show_component(url) # rubocop:disable Metrics/CyclomaticComplexity TODO: Remove this
    if url.split('/')[2] == "consumer_role" || url.split('/')[1] == "insured" && url.split('/')[2] == "interactive_identity_verifications" || url.split('/')[1] == "financial_assistance" && url.split('/')[2] == "applications" || url.split('/')[1] == "insured" && url.split('/')[2] == "family_members" || url.include?("family_relationships")
      false
    else
      true
    end
  end
end

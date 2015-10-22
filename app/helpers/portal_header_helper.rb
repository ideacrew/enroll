module PortalHeaderHelper
  def portal_display_name(controller)

    if current_user.nil?
      "Welcome to the District's Health Insurance Marketplace"
    elsif current_user.try(:has_hbx_staff_role?)
      hbx_staff_header
    elsif current_user.person.try(:broker_role)
      broker_header
    elsif current_user.try(:person).try(:csr_role) || current_user.try(:person).try(:assister_role)
      agent_header
    elsif current_user.try(:has_employee_role?)
        "#{image_tag 'icons/icon-individual.png'} &nbsp; I'm Shopping for Employee Health Insurance".html_safe
    elsif (controller_path.include?("insured") && current_user.try(:has_consumer_role?))
        "#{image_tag 'icons/icon-family.png'} &nbsp; Individual and Family".html_safe
    elsif current_user.try(:has_broker_agency_staff_role?)
      "#{image_tag 'icons/icon-expert.png'} &nbsp; I'm a Broker".html_safe
    elsif current_user.try(:has_employer_staff_role?)
      "#{image_tag 'icons/icon-business-owner.png'} &nbsp; I'm an Employer".html_safe
    else
      "Welcome to the District's Health Insurance Marketplace"
    end
  end

  def enrollment_name
    begin
      person = Person.find(session[:person_id])
      name=  'Assisting: ' + person.full_name
    rescue
      name = ''
    end
  end
  def agent_header
    if current_user.person.assister_role
    	agent = "I'm an In Person Assister"
    elsif  current_user.person.csr_role.cac
    	agent = "I'm a Certified Applicant Counselor"
    else
    	agent = "I'm a Customer Service Representative"
    end
    header_text = "<div style='display:inline-block'>&nbsp; #{agent}<br/>&nbsp; #{enrollment_name}</div>"
    link_to "#{image_tag 'icons/icon-expert.png'}#{header_text}".html_safe,
      home_exchanges_agents_path
  end

  def hbx_staff_header
    header_text = "<div style='display:inline-block'>&nbsp; I'm HBX Staff<br/>&nbsp; #{enrollment_name}</div>"
    link_to "#{image_tag 'icons/icon-exchange-admin.png'} #{header_text}".html_safe,
      exchanges_hbx_profiles_root_path
  end

  def broker_header
    header_text = "<div style='display:inline-block'>&nbsp; I'm a Broker<br/>&nbsp; #{enrollment_name}</div>"
    link_to "#{image_tag 'icons/icon-expert.png'} #{header_text}".html_safe,
      broker_agencies_profile_path(id: current_user.person.broker_role.broker_agency_profile_id)
  end
end

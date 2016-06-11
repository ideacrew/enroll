feins = [Organization.where(:legal_name=>'er10').first.fein]

def publish(payload, file_name)
  File.open(File.join("employer_xmls.v2", "#{file_name}.xml"), 'w') do |f|
    f.puts payload
  end
end

feins.each do |fein|

  views = Rails::Application::Configuration.new(Rails.root).paths["app/views"]

  views_helper = ActionView::Base.new views

  include EventsHelper

  employer_profile = Organization.where(:fein => fein.gsub("-","")).first.employer_profile

  carriers = employer_profile.plan_years.select(&:eligible_for_export?).flat_map(&:benefit_groups).flat_map(&:elected_plans).flat_map(&:carrier_profile).uniq! || []

  carriers.each do |carrier|
    @carrier = carrier
    cv_xml = views_helper.render file: File.join(Rails.root, "/app/views/events/v2/employers/updated.xml.haml"), :locals => {carrier:carrier, employer:employer_profile}

    #cv_xml = render "", locals:{carrier:carrier, employer: employer_profile}
    publish(cv_xml, employer_profile.fein + "_" + carrier.legal_name)
  end
end
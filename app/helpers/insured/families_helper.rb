module Insured::FamiliesHelper

  def render_plan_type_details(plan)
    plan_details = [ plan.try(:plan_type).try(:upcase) ].compact

    if plan_level = plan.try(:metal_level).try(:humanize)
      plan_details << "<span class=\"#{plan_level.try(:downcase)}-icon\">#{plan_level}</span>"
    end

    if plan.try(:nationwide)
      plan_details << "NATIONWIDE NETWORK"
    end

    plan_details.inject([]) do |data, element| 
      data << "<label>#{element}</label>"
    end.join("&nbsp<label class='separator'></label>").html_safe
  end
end
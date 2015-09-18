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

  def qle_link_generater(qle, index)
    options = {class: 'qle-menu-item'}
    data = {
      title: qle.title, id: qle.id.to_s, label: qle.event_kind_label,
      post_event_sep_in_days: qle.post_event_sep_in_days, 
      pre_event_sep_in_days: qle.pre_event_sep_in_days,
      date_hint: qle.date_hint, is_self_attested: qle.is_self_attested 
    } 

    if qle.tool_tip.present?  
      data.merge!(toggle: 'tooltip', placement: index > 1 ? 'top' : 'bottom')
      options.merge!(data: data, title: qle.tool_tip)
    else
      options.merge!(data: data)
    end
    link_to qle.title, "javascript:void(0)", options
  end
end

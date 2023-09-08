# frozen_string_literal: true

module ApplicationHelper
  def menu_tab_class(a_tab, current_tab)
    a_tab == current_tab ? raw(" class=\"active\"") : ""
  end

  def link_to_with_noopener_noreferrer(name, path, options = {})
    link_to(name, path, options.merge(rel: 'noopener noreferrer'))
  end

  # rubocop:disable Naming/MethodParameterName
  def datepicker_control(f, field_name, options = {}, value = "")
    sanitized_field_name = field_name.to_s.sub(/\?$/,"")
    opts = options.dup
    obj_name = f.object_name
    obj_val = f.object.send(field_name.to_sym)
    current_value = if obj_val.blank?
                      value
                    else
                      obj_val.is_a?(DateTime) ? obj_val.strftime("%m/%d/%Y") : obj_val
                    end
    html_class_list = opts.delete(:class) { |_k| "" }
    jq_tag_classes = (html_class_list.split(/\s+/) + ["jq-datepicker"]).join(" ")
    generated_field_name = "jq_datepicker_ignore_#{obj_name}[#{sanitized_field_name}]"
    provided_id = options[:id] || options["id"]
    generated_target_id = nil
    generated_target_id = "#{provided_id}_jq_datepicker_plain_field" unless provided_id.blank?
    sanitized_object_name = "#{obj_name}_#{sanitized_field_name}".delete(']').tr('^-a-zA-Z0-9:.', "_")
    generated_target_id ||= "#{sanitized_object_name}_jq_datepicker_plain_field"
    capture do
      concat f.text_field(field_name, opts.merge(:class => html_class_list, :id => generated_target_id, :value => obj_val.try(:to_s, :db)))
      concat text_field_tag(generated_field_name, current_value, opts.merge(:class => jq_tag_classes, :start_date => "07/01/2016", :style => "display: none;", "data-submission-field" => "##{generated_target_id}"))
    end
  end
  # rubocop:enable Naming/MethodParameterName

  # Not sure if this is the best way to handle templates that call for javascript_pack_tag
  # but I'm not sure how to mock it out otherwise
  def javascript_pack_tag(*args); end
end

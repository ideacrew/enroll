# frozen_string_literal: true

# helper for generating view blocks. currently this is an experiment and should not be used without persmission from lead engineer.
module ViewControlsHelper
  # this method is used to render a fieldset with inputs for RR setting
  # this is a deprecated pattern replacing a RR helper and should not be used in new code
  def build_fieldset_inputs_from_rr(setting, form)
    return unless setting.meta&.enum&.any? && [:radio_select, :checkbox_select].include?(setting.meta&.content_type)

    if setting.meta.content_type == :radio_select
      input_type = "radio"
      fieldset_classes = ["d-flex"]
    else
      input_type = "checkbox"
      fieldset_classes = ["d-block two-column"]
    end
    legend = setting.meta.description.present? ? setting.meta.description : setting.meta.label
    choices = build_fieldset_choices(setting, form)
    build_fieldset(choices, setting.meta.is_required, l10n(legend), input_type, fieldset_classes)
  end

  def build_fieldset_choices(setting, form)
    setting.meta.enum.map do |input|
      choice = input.first.first
      choice_label = l10n("exchange.manage_sep_types.#{setting.key}.#{choice}")
      input_value = form.object&.send(setting.key)&.to_s || setting.meta.default.to_s
      build_input_hash(choice, setting, form&.object_name.to_s, input_value, choice_label)
    end
  end

  def build_input_hash(choice, setting, object_name, input_value, label)
    input_hash = {
      label: label,
      name: object_name + "[#{setting.key}]",
      value: choice.first,
      id: "#{setting.key}_#{choice}"
    }
    input_hash[:name] += "[]" if setting.meta.content_type == :checkbox_select
    input_hash[:checked] = true if input_value.to_s == choice.to_s || (input_value.map(&:to_s).include?(choice.to_s) if input_value.is_a?(Array))
    input_hash
  end

  # this method is used to build a 508 compliant fieldset with bs4 markup
  # right now assumes fieldset will contain checkbox or radio inputs
  def build_fieldset(inputs, required, legend, content_type, fieldset_classes = ["d-flex"])
    h(content_tag(:fieldset, class: fieldset_classes) do
      legend_classes = required ? ["required"] : nil
      concat(content_tag(:legend, class: legend_classes) do
        legend
      end)
      inputs.each do |input|
        next unless input[:label].present? && input[:name].present? && input[:value].present?
        input_id = input[:id] || input[:name]
        input_args = input.except(:label, :label_classes)
        input_args[:required] = true if required
        concat(content_tag(:label, nil, class: input[:label_classes] || ["weight-n"], for: input_id) do
          concat(content_tag(:input, nil, type: content_type, **input_args))
          concat(content_tag(:span, input[:label], class: ["ml-1"], id: input_id))
        end)
      end
    end.to_s)
  end
end

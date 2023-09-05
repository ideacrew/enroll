# frozen_string_literal: true

# new form builder that includes an SSN field method to make implementing standard
# ssn_fields simpler and much more consistent
class HbxFormBuilder < ActionView::Helpers::FormBuilder
  include ::L10nHelper

  def ssn_field(method, options = {})
    is_required = options.delete(:required) || false
    is_readonly = options.delete(:readonly) || false
    class_list  = options.delete(:class)    || ""
    class_list += " #{'required' if is_required} floatlabel form-control mask-ssn"
    shared_options = {
      class: class_list.split(/\s+/).uniq.join(" "),
      maxlength: 11,
      required: is_required,
      placeholder: "#{l10n('social_security').to_s.upcase} #{'*' if is_required}",
      readonly: is_readonly
    }
    if EnrollRegistry.feature_enabled?(:ssn_ui_validation)
      @template.text_field(
        @object_name,
        method,
        options.merge(
          pattern: "(?!666|000|9\\d{2})\\d{3}[\\- ]{0,1}(?!00)\\d{2}[\\- ]{0,1}(?!0{4})\\d{4}",
          oninvalid: "this.setCustomValidity('#{l10n('social_security_invalid')}')",
          oninput: "this.setCustomValidity('')"
        ).merge(
          shared_options
        )
      )
    else
      @template.text_field(
        @object_name,
        method,
        options.merge(
          shared_options
        )
      )
    end
  end
end

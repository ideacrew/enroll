# Use this in views.   Needed to make rspec work.
# allow(view).to receive(:policy_helper).and_return(double("PersonPolicy", updateable?: true))
# https://github.com/elabs/pundit/issues/339
# https://www.relishapp.com/rspec/rspec-rails/v/3-0/docs/view-specs/view-spec#passing-view-spec-that-stubs-a-helper-method
module PermissionHelper
  def policy_helper pundit_object
    policy(pundit_object) 
  end

  def pundit_span pundit_object, pundit_method
    return ' <span class="blocking" >' unless pundit_object

    result = policy_helper(pundit_object).send(pundit_method) ? '<span class="no-op">' : ' <span class="blocking" >'
    raw result
  end

  def pundit_class pundit_object, pundit_method
    return '  blocking ' unless pundit_object

    result = policy_helper(pundit_object).send(pundit_method) ? ' no-op ' : '  blocking '
    raw result
  end

  def pundit_allow pundit_object, pundit_method
    result = policy_helper(pundit_object).send(pundit_method)
  end

  def permission_options(current_permission=nil, selected_permission=nil)
    options = (@permissions ||= Permission.all).map do |permission|
      tag.option permission.name.humanize,
        disabled: !Permission.hierarchy_check(current_permission, permission),
        selected: permission.id == selected_permission&.id,
        value: permission.id
    end

    options.join('\n').html_safe
  end
end

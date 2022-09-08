module Views::ViewHelper

  def display_standard_plan(plan)
    if plan.is_standard_plan
      l10n("yes")
    elsif plan.is_standard_plan == false
      l10n("no")
    else
      "N/A"
    end
  end
end
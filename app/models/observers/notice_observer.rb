module Observers
  class NoticeObserver < Observer

    def update(event_name, target, options = {})
      if target.is_a?(PlanYear)
        plan_year = ObserverModels::PlanYear.new(event_name, target, options)
        plan_year.process
      end
    end
  end
end
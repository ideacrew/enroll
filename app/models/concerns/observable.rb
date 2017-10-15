module Concerns::Observable
  extend ActiveSupport::Concern

  included do
    after_initialize do |instance|
      # klass_name = "Observers::" + self.class.name + "Observer"
      # instance.add_observer(Object.const_get(klass_name).new)
      register_observers
    end

    # aasm do
    #   after_all_events :notify_state_change
    #   after_all_events do
    #     notify_observers(self, aasm: aasm)
    #   end
    # end
  end

  def add_observer(observer, func=:update)
    @observer_peers = {} unless defined? @observer_peers

    unless observer.respond_to? func
      raise NoMethodError, "observer does not respond to '#{func.to_s}'"
    end

    if @observer_peers.none?{|k, v| k.is_a?(observer.class)}
      @observer_peers[observer] = func
    end
  end

  def delete_observers
    @observer_peers.clear if defined? @observer_peers
  end

  def notify_observers(*arg)
    if defined? @observer_peers
      @observer_peers.each do |k, v|
        k.send v, *arg
      end
    end
  end

   def register_observers
    # add_observer(Observers::EdiObserver.new,      :employer_profile_update)
    add_observer(Observers::NoticeObserver.new,   :employer_profile_update)
    # add_observer(Observers::AnalyticObserver.new, :employer_profile_update)
    # add_observer(Observers::LedgerObserver.new,   :employer_profile_update)
    # add_observer(Observers::AcapiObserver.new,    :employer_profile_update)
    # add_observer(Observers::LogObserver.new,      :employer_profile_update)
  end
end
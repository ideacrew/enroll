module Concerns::Observable
  extend ActiveSupport::Concern

  included do
    extend ObservableMethods
    include ObservableMethods

    after_initialize do |instance|
      register_observers
    end
  end

  module ObservableMethods
    attr_reader :observer_peers

    def self.extended(base)
      base.register_observers
    end

    def update_method_name
      if self.is_a?(Class)
        self.model_name.param_key + '_date_change'
      else
        self.class.model_name.param_key + '_update'
      end
    end

    def register_observers
      add_observer(Observers::NoticeObserver.new, update_method_name.to_sym)
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
  end
end
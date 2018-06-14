module BenefitSponsors
  module Concerns::Observable
    extend ActiveSupport::Concern

    included do
      after_update :notify_observers

      def notify_observers(*arg)
        if self.class.observer_peers.any?
          self.class.observer_peers.each do |k, v|
            puts k.inspect
            k.send v, *arg
          end
        end
      end
    end

    class_methods do
      def add_observer(observer, func=:update)
        @observer_peers ||= {}
        unless observer.respond_to? func
          raise NoMethodError, "observer does not respond to '#{func.to_s}'"
        end

        if @observer_peers.none?{|k, v| k.is_a?(observer.class)}
          @observer_peers[observer] = func
        end
        @observer_peers
      end

      def observer_peers
        @observer_peers
      end
    end
  end
end

module BenefitMarkets
  module RulesEngine
    extend ActiveSupport::Concern

    included do
      class_attribute :rule_policies
      class_attribute :rules
      self.rule_policies = {}
      self.rules = []
    end

    module ClassMethods
      def register_rule_policy(new_rule_policy_name, rule_policy)
        raise Error, "policy #{new_rule_policy_name} already exists" if rule_policies.has_key?(new_rule_policy_name)
        rule_policies[new_rule_policy_name] = rule_policy
      end

      def rule_policy(new_rule_policy_name, options={})
        if options[:rules].present? and options[:rules].size > 0
          options[:rules] = options[:rules].reduce([]) do |list, rule|
            if rule.is_a? RulesEngine::RulePolicy
              list << rule
            else
              rule_instance = find_rule_by_name(rule)

              if rule_instance.present?
                list << rule
              else
                raise Error, "rule definition not found: #{missing_rules}"
              end
            end

            list
          end
        end

        rule_policy = RulesEngine::RulePolicy.new(new_rule_policy_name, options)
        register_rule_policy(name, rule_policy)
      end

      def rule_policies
        self.rule_policies ||= {}
      end

      def [](name)
        rule_policies[name] if rule_policies.has_key?(name)
      end

      def rule(new_rule_name, options={})
        rule = RulesEngine::Rule.new(new_rule_name, options={})
        self.rules << rule
        rule
      end

      def rules
        self.rules || []
      end

      def find_rule_by_name(name)
        self.rules.detect { |rule| name == rule.name }
      end

      def assert_rule_policy(rule_policy_name)
        rule_policies[rule_policy_name].send(:process_rules) if rule_policies.has_key?(rule_policy_name)
      end

      def reset_rule_policies
        self.rule_policies = {}
      end
    end

    class RulePolicy
      def initialize(name = nil, options={})
        self.name(name) if name.present?

        @rules = options[:rules] || []
        @errors = []
      end

      def name(name = nil)
        @name = name if (name && ! @name)
        @name if defined?(@name)
      end

      def inspect
        "<RulePolicy name: #{name}, rules: #{rules.each {|rule| rule.inspect} }, errors: #{errors} >"
      end

      def process_rules
        rules.sort_by(&:priority).each do |rule|
          errors << rule.run
        end
      end

      def errors
        @errors || []
      end

      def reset_errors
        @errors = []
      end

      def rules
        @rules || []
      end

      def reset_rules
        @rules = []
        reset_errors
      end
    end

    class Rule
      # To use, just include it in any file where you need some rules engine love ...
      # then defile rules like so:
      #
      # rule :name_of_rule,
      #       validate: lambda {|o| # do something with o}
      #       fail: lambda {|o| o.fail!}}
      #       priority: 10,
      #
      # then to run the engine
      # process_rules(your_data_set)

      attr_accessor :name, :priority

      # proc to test
      attr_accessor :validate

      # if valid
      attr_accessor :success

      # if invalid
      attr_accessor :fail

      NO_OP = lambda {|o| true }


      def initialize(name = nil, options={})
        self.name(name) if name.present?
        # self.params   = options[:params]    || {}
        self.validate = options[:validate]  || NO_OP
        self.success  = options[:success]   || NO_OP
        self.fail     = options[:fail]      || NO_OP
        self.priority = options[:priority]  || 10
      end

      def name(name = nil)
        @name = name if (name && ! @name)
        @name if defined?(@name)
      end


      def run(data)
        if validate.call(data)
          success.call(data)
        else
          fail.call(data)
        end
      end

      def inspect
        "<Rule name: #{name}, priority: #{self.priority}, validate: #{self.validate}, success: #{self.success}, fail: #{self.fail} >"
      end

    end
  end
end

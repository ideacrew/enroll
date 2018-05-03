class RuleSet

  class Rule
    def initialize(name, blk)
      @name = name
      @blk = blk
    end

    def run
       @blk.call
    end
  end

  attr_reader :inputs, :outputs, :facts, :rules

  def initialize
    @rules ||= []
    @facts ||= []
    @outputs ||= []
  end

  def rule(rule_name, &blk)
    @rules << Rule.new(rule_name, blk)
  end

  def run
    @rules.each do |r|
      @outputs[r.name] << r.run
    end
  end



end

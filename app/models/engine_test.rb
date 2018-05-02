class EngineTest
  include SimpleRulesEngine
  rule :equal_one,
         priority: 10,
         validate: lambda {|o| o == 1 },
         success: lambda {|o| puts "wohoo" },
         fail: lambda {|o| puts "fail"}

   rule :greater_equal_to_one,
          priority: 10,
          validate: lambda {|o| o >= 1 },
          success: lambda {|o| puts "wohoo" },
          fail: lambda {|o| puts "fail"}

end

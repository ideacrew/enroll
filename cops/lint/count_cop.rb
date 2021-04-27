module RuboCop
  module Cop
    module Hired
      class CountCop < Cop
        MSG = "Avoid using `count?` Consider using any? or blank?."

        def_node_matcher :count?, <<-END
          (send _ :count)
        END

        def on_send(node)
          return unless unscoped?(node)
          add_offense(node, :expression, MSG % node.source)
        end
      end
    end
  end
end
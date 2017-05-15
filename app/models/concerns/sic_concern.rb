module SicConcern
  SIC_NESTING_CODES = {
    1 => 'major_group_code',
    2 => 'industry_group_code',
    3 => 'sic_code'
  }
  SIC_NESTING_LABELS = {
    1 => 'major_group_label',
    2 => 'industry_group_label',
    3 => 'sic_label'
  }
  SIC_DIVISION_CODES = %w(A B C D E F G H I J)
  def generate_sic_array
    nodes = []

    SIC_DIVISION_CODES.each do |division_code|
      division_sic = SicCode.where(division_code: division_code).first
      next unless division_sic.present?

      nodes << {
                  text: division_sic.division_label.strip,
                  nodes: generate_child_nodes(1, division_code: division_code)
                }
    end
    nodes
  end

  private

  def generate_child_nodes(next_level, **attr)
    nodes = []
    all_children = SicCode.where(**attr)
    child_column_sym = SIC_NESTING_CODES[next_level].to_sym
    child_column_label = SIC_NESTING_LABELS[next_level].to_sym
    distinct_child_groups = all_children.distinct(child_column_sym)

    distinct_child_groups.each do |next_level_code|
      last_node = next_level_code.length == 4    ### If the code is a length of 4 e.g 1111 it means it's the actual SIC code
      node_text = all_children.find_by(child_column_sym => next_level_code).public_send(child_column_label)
      nodes << {
                  text: node_text
                }
      if last_node
        nodes.last[:text] = node_text + " - #{next_level_code}"
      else
        nodes.last[:nodes] = generate_child_nodes(next_level+1, attr.merge(child_column_sym => next_level_code))   ## Generate more nodes
      end
    end

    nodes
  end
end

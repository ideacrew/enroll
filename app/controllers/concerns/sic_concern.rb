module SicConcern
  def generate_sic_array
    @divisions = []
    @major_groups = []
    @industry_groups = []

    %w(A B C D E F G H I J).each do |division_code|
      @divisions << {
                      id: division_code,
                      parent: "#",
                      icon: "glyphicon glyphicon-plus",
                      text: SicCode.find_by(division_code: division_code).division_label.strip
                    }

      distinct_major_groups = SicCode.where(division_code: division_code).distinct(:major_group_code)
      distinct_major_groups.each do |major_group_code|
        @major_groups << {
                            id: major_group_code,
                            parent: division_code,
                            icon: "glyphicon glyphicon-th-list",
                            text: SicCode.find_by(division_code: division_code, major_group_code: major_group_code).major_group_label
                          }

        distinct_industry_groups = SicCode.where(division_code: division_code, major_group_code: major_group_code).distinct(:industry_group_code)
        distinct_industry_groups.each do |industry_group_code|
          @industry_groups << {
                                id: industry_group_code,
                                parent: major_group_code,
                                icon: "glyphicon glyphicon-tree-deciduous",
                                text: SicCode.find_by(division_code: division_code, major_group_code: major_group_code, industry_group_code: industry_group_code).industry_group_label
                              }
        end
      end
    end ## end loop horror show

    @low_level_sics = SicCode.pluck(:industry_group_code, :sic_code, :sic_label).map do |sic|
      {
        parent: sic.first,
        id: sic.second,
        text: "#{sic.third} (#{sic.second})",
        icon: "glyphicon glyphicon-glyphicon-leaf",
        a_attr: sic.second
      }
    end

    @divisions + @major_groups + @industry_groups + @low_level_sics
  end
end

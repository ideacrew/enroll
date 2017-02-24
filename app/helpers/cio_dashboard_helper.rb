module CioDashboardHelper
  def get_indicator_class(object)
    return "" unless object.respond_to?(:row_indicator)
    case object.row_indicator.to_i
     when 1
        return '<span class="glyphicon glyphicon-asterisk green"></span>'
      when 2
        return '<span class="glyphicon glyphicon-asterisk red"></span>'
       when 3
        return '<span class="glyphicon glyphicon-arrow-down red"></span>'
      else 
        ""
    end
  end
end
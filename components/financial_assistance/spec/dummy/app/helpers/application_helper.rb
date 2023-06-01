# frozen_string_literal: true

module ApplicationHelper
  def menu_tab_class(a_tab, current_tab)
    a_tab == current_tab ? raw(" class=\"active\"") : ""
  end

  def link_to_with_noopener_noreferrer(name, path, options = {})
    link_to(name, path, options.merge(rel: 'noopener noreferrer'))
  end
end

module DataTablesAdapter
  DataTablesInQuery = Struct.new(:draw, :skip, :take)

  def extract_datatable_parameters
    draws = params[:draw]
    start_idx = params[:start].to_i || 0
    window_size = params[:length] || 10
    DataTablesInQuery.new(draws, start_idx, window_size)
  end
end

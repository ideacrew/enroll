module Moped
  class Collection
    def raw_aggregate(pipeline)
      command = { aggregate: name.to_s, pipeline: pipeline }
      database.session.command(command)["result"]
    end
  end
end

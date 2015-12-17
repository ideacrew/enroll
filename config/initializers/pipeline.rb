module Mongo
  class Collection
    def raw_aggregate(pipeline)
      command = { aggregate: name.to_s, pipeline: pipeline }
      database.client.command(command)
    end
  end
end

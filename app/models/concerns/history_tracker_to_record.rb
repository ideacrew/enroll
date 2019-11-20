module HistoryTrackerToRecord
  extend ActiveSupport::Concern

  def history_tracker_to_record(ht_date)
    # Example: If is a HistoryTracker in person model
    # history_track.trackable will return consumer_role
    # if the consumer_role was modified. trackable_root
    # will return person for both
    self.reload
    # Example structure of modified: {"is_state_resident"=>false}
    all_tracks = self.history_tracks.unscoped.to_a.sort_by(&:created_at)
    tracks_to_reverse = all_tracks.reject do |ht|
      # Reject everything that comes before history tracker including history tracker record itself
      # And then apply them in reverse
      (ht.created_at <= ht_date) || ((ht.created_at.to_f - self.created_at.to_f).abs < 1.1)
    end.reverse
    tracks_to_reverse.each do |rt|
      if rt.trackable && (rt.trackable.id == rt.trackable_root.id)
        self.attributes = rt.undo_attr(nil)
      else
        case rt.action
        when "create"
          #binding.pry
          association_chain_without_last = rt.association_chain[0..-2]
          last_in_chain = rt.association_chain.last
          chain_target = association_chain_without_last.inject(self) do |acc, chain_location|
            if self.id == chain_location["id"]
              self
            elsif acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).where(id: chain_location["id"].to_s).first
            else # embeds_one
              acc.send(chain_location["name"].to_sym)
            end
          end
          if chain_target.send(last_in_chain["name"]).is_a?(Enumerable)
            remaining_items = chain_target.send(last_in_chain["name"].to_sym).reject do |record|
              record.id.to_s == last_in_chain["id"].to_s
            end
            chain_target.send((last_in_chain["name"] + "=").to_sym, remaining_items)
          else
            chain_target.send((last_in_chain["name"] + "=").to_sym, nil)
          end
        when "destroy"
          association_chain_without_last = rt.association_chain[0..-2]
          last_in_chain = rt.association_chain.last
          chain_target = association_chain_without_last.inject(self) do |acc, chain_location|
            if self.id == chain_location["id"]
              self
            elsif acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).where(id: chain_location["id"].to_s).first
            else # embeds_one
              acc.send(chain_location["name"].to_sym)
            end
          end
          if chain_target.send(last_in_chain["name"]).is_a?(Enumerable)
            chain_target.send(last_in_chain["name"].to_sym).build(rt.original)
          else
            chain_target.send(("build_" + last_in_chain["name"]).to_sym, rt.original)
          end
        else
          #binding.pry
          chain_target = rt.association_chain.inject(self) do |acc, chain_location|
            if self.id == chain_location["id"]
              self
            elsif acc.send(chain_location["name"]).is_a?(Enumerable) # embeds_many
              acc.send(chain_location["name"]).where(id: chain_location["id"].to_s).first
            else # embeds_one
              acc.send(chain_location["name"].to_sym)
            end
          end
          chain_target.attributes = rt.undo_attr(nil)
        end
      end
    end
    self
  end
end
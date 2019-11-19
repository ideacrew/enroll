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
      ht.created_at <= ht_date
    end.reverse

    tracks_to_reverse.each do |rt|
      if (rt.trackable.id == rt.trackable_root.id)
        self.attributes = rt.undo_attr({})
      else
        chain_target = rt.association_chain.inject(self) do |acc, chain_location|
          # Modifies top level document itself
          if self.id == chain_location["id"]
            self.attributes = rt.original
          else # Modifies embedded document. Compensates for embeds_one and embeds_many
            self.send(chain_location["name"].to_sym).attributes = rt.original
          end
        end
      end
    end
    self
  end
end

module HistoryTrackerToRecord
  extend ActiveSupport::Concern

  # trackable_class should be capitalized as string like "Person"
  def history_tracker_to_record(ht_date)
    # Example: If is a HistoryTracker in person model
    # history_track.trackable will return consumer_role
    # if the consumer_role was modified. trackable_root
    # will return person for both
    self.reload
    # Example structure of modified: {"is_state_resident"=>false}
    all_tracks = self.history_tracks.unscoped.to_a.sort_by(&:created_at)
    tracks_to_reverse_count = all_tracks.reject do |ht|
      # Reject everything that comes before history tracker including history tracker record itself
      # And then apply them in reverse
      ht.created_at > ht_date
    end.length
    reverse_track_count = (all_tracks.length - tracks_to_reverse_count)
    undone = self.undo(nil, :last => reverse_track_count)
    puts undone.inspect
    self
  end
end

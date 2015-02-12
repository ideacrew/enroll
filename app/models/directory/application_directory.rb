class Directory::ApplicationDirectory
  include Mongoid::Document


  # after_commit :flush_cache

  def self.cache_attributes
    self.attribute_names.delete_if { |attr| ["_id", "_type"].include? attr }
  end

  def self.cached_find(id)
    Rails.cache.fetch([name, id], expires_in: 5.minutes) { find(id) }
  end

  def flush_cache
    Rails.cache.delete([self.class.name, id])
  end
 

end

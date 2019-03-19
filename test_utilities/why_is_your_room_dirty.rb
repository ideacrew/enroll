class DirtyDbRoom

  def self.initialize_stern_mom!
    @db_room_mutex = Mutex.new
    @room_status_list = Hash.new { |h,k| h[k] = Array.new }
  end

  def self.db_was_cleaned!(example)
    @db_room_mutex.synchronize do
      @room_status_list.delete(example.location)
    end
  end

  def self.room_made_dirty!(factory_name)
    if RSpec.current_example
      @db_room_mutex.synchronize do
        @room_status_list[RSpec.current_example.location] = 
          @room_status_list[RSpec.current_example.location] + 
          [[factory_name, RSpec.current_example.full_description]]
      end
    end
  end

  def self.format_unmatched_examples!
    @db_room_mutex.synchronize do
      @room_status_list.each_pair do |k, v|
        v.each do |fname_loc|
          fn, loc = *fname_loc
          puts "*****DIRTY_SPEC #{k} - #{fn} - #{loc}"
        end
      end
    end
  end
end

at_exit do
  DirtyDbRoom.format_unmatched_examples!
end

module FactoryGirl::Syntax::Methods
  def create_with_log(name, *traits_and_overrides, &block)
    DirtyDbRoom.room_made_dirty!(name)
    create_without_log(name, *traits_and_overrides, &block)
  end

  alias_method_chain :create, :log

  def build_with_log(name, *traits_and_overrides, &block)
    DirtyDbRoom.room_made_dirty!(name)
    build_without_log(name, *traits_and_overrides, &block)
  end

  alias_method_chain :build, :log
end

DirtyDbRoom.initialize_stern_mom!

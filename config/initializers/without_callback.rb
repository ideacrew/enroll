module ActiveSupport::Callbacks::ClassMethods
  def without_callback(*args, &block)
    skip_callback(*args)
    result = yield
    set_callback(*args)
    result
  end

  def without_callbacks(args, &block)
    args.each { |args| skip_callback(*args) }
    result = yield
    args.each { |args| set_callback(*args) }
    result
  end
end

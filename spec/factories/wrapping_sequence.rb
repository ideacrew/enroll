class WrappingSequence

  def initialize(start_at, wrap_after)
    @start_at = start_at
    @value = @start_at
    @wrap_max = wrap_after
  end

  def next
    if @value == @wrap_max
      @value = @start_at
    else
      @value = @value + 1
    end
  end

  def peek
    @value
  end
end

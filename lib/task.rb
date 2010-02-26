class Task
  include HotCocoa::Behaviors
  
  # intentionally not defining time as accessor, because macruby makes you reimplement kvo willChangeValueForKey didChangeValueForKey stuff
  attr_accessor :id, :name, :start_time
  
  @time = 0
  
  def display_time
    total_seconds = get_time.to_i
    
    days = total_seconds / 86400
    hours = (total_seconds / 3600) - (days * 24)
    minutes = (total_seconds / 60) - (hours * 60) - (days * 1440)
    seconds = total_seconds % 60
    
    display = ''
    display_concat = ''
    if days > 0
      display = display + display_concat + "#{days}d"
      display_concat = ' '
    end
    if hours > 0 || display.length > 0
      display = display + display_concat + "#{hours}h"
      display_concat = ' '
    end
    if minutes > 0 || display.length > 0
      display = display + display_concat + "#{minutes}m"
      display_concat = ' '
    end
    display = display + display_concat + "#{seconds}s"
    display
  end
  
  def get_time
    @time = 0 unless @time
    
    if start_time
      @time + (Time.now.to_f - @start_time)
    else
      @time
    end
  end
  
  def start
    if @start_time == nil
      @start_time = Time.now.to_f
    end
  end
  
  def started?
    @start_time != nil
  end
  
  def stop
    if @start_time != nil
      diff = Time.now.to_f - @start_time
      @time = @time + diff
      @start_time = nil
    end
  end
  
  def stopped?
    @start_time == nil
  end
  
  def clear
    @time = 0
  end
end
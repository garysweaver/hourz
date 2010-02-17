require 'rubygems'
require 'hotcocoa'
require 'pathname'

require File.expand_path(File.dirname(__FILE__)) + '/task'

class Hourz

  include HotCocoa
  
  attr_accessor :tasks, :new_task_name_field, :task_to_edit, :edit_task_name_field, :table, :add_view, :edit_view
  
  def start
    @tasks = []
    application :name => "Hourz" do |app|
      app.delegate = self
      
      @main_window = window(:size => [640, 480], :title => "Hourz", :center => true) do |win|
        win.will_miniaturize { exit }
        win.view = layout_view(:layout => {:expand => [:width, :height],
                                           :padding => 0, :margin => 0}) do |vert|
          @add_view = layout_view(:frame => [0, 0, 0, 40], :mode => :horizontal,
                              :layout => {:padding => 0, :margin => 0,
                                          :start => false, :expand => [:width]}) do |horiz|
            horiz << label(:text => "New Task", :layout => {:align => :center})
            horiz << @new_task_name_field = text_field(:layout => {:expand => [:width]})
            @new_task_name_field.stringValue = ''
            horiz << button(:title => 'Add', :layout => {:align => :center}) do |b|
              b.on_action { add_new_task }
            end
          end
          vert << @add_view
          
          @edit_view = layout_view(:frame => [0, 0, 0, 40], :mode => :horizontal,
                              :layout => {:padding => 0, :margin => 0,
                                          :start => false, :expand => [:width]}) do |horiz|
            horiz << label(:text => "Edit Task", :layout => {:align => :center})
            horiz << @edit_task_name_field = text_field(:layout => {:expand => [:width]})
            @edit_task_name_field.stringValue = ''
            horiz << button(:title => 'Update', :layout => {:align => :center}) do |b|
              b.on_action {
                update_task
                in_add_mode
              }
            end
            horiz << button(:title => 'Cancel', :layout => {:align => :center}) do |b|
              b.on_action {
                in_add_mode
              }
            end
          end
          vert << @edit_view
          
          #in_edit_mode
          
          vert << scroll_view(:layout => {:expand => [:width, :height]}) do |scroll|
            scroll.setAutohidesScrollers(true)            
            scroll << @table = table_view(:columns => [column(:id => :id, :title => 'ID', :hidden => true, :editable => false),
                                          column(:id => :name, :title => 'Name', :editable => false),
                                          column(:id => :time, :title => 'Time', :editable => false),
                                          column(:id => :on_off, :title => '', :editable => false),
                                          column(:id => :edit, :title => '', :editable => false),
                                          column(:id => :remove, :title => '', :editable => false)],
                                          :data => []) do |table|
               table.setUsesAlternatingRowBackgroundColors(true)
               table.setGridStyleMask(NSTableViewSolidHorizontalGridLineMask)
               table.setAction(:task_action)                                           
            end
          end
        end
      end
      
      load_tasks_from_file
      
      set_table_data
      
      queue = Dispatch::Queue.new('hourz.refresh_data')
      # Refresh table data each second in seperate thread
      queue.async do
        loop {
          sleep 1.0
          set_table_data
        }
      end      
    end
  end
  
  def load_tasks_from_file
    if !File.exist?("hourz.dat") && !File.exist?("hourz.bak")
      alert :message => "Welcome to Hourz", :info => "Welcome to Hourz! Feel free to add some tasks and get started!"
      return
    end
    
    if !File.exist?("hourz.dat") && File.exist?("hourz.bak")
      copy_file("hourz.bak", "hourz.dat")
      alert :message => "Recovered from backup", :info => "Save file 'hourz.dat' was missing, but was able to recover tasks from 'hourz.bak' file, even though it doesn't have your latest changes."
    end
    
    begin
      @tasks = load_tasks_from_file_impl("hourz.dat")
    rescue Exception => e
      alert :message => "Problem loading tasks data", :info => "Could not load data from save file 'hourz.dat'. Error: #{e.message} {#{e.backtrace}"
      begin
        copy_file("hourz.bak", "hourz.dat")
        @tasks = load_tasks_from_file_impl("hourz.bak") 
        alert :message => "Recovered from backup", :info => "Was able to recover from 'hourz.bak' file, even though it doesn't have your latest changes."
      rescue Exception => e2
        alert :message => "Problem loading tasks data from backup", :info => "Could not load data from backup save file 'hourz.bak'. Error: #{e2.message} {#{e2.backtrace}"
      end      
    end
  end
  
  def load_tasks_from_file_impl(filename)
    alert :message => "Debug", :info => "Loading file '#{Pathname.pwd}/#{filename}'"
    f = File.open(filename, "r")
    tasks = Marshal.load(f)
    set_table_data
    f.close
    tasks
  end
  
  def save_tasks_to_file    
    #copy_file("hourz.dat", "hourz.bak") if File.exist?("hourz.dat")
    save_tasks_to_file_impl(@tasks, "hourz.dat")
  end
  
  def save_tasks_to_file_impl(tasks, filename)
    alert :message => "Debug", :info => "Saving file '#{Pathname.pwd}/#{filename}'"
    f = File.open(filename, "w")
    tasks = Marshal.dump(tasks, f)
  end
  
  # copy didn't work, so for now, just reuse unmarshal and marshal
  def copy_file(filename1, filename2)
    save_tasks_to_file_impl(load_tasks_from_file_impl(filename1), filename2)
  end
  
  def task_action
    id = "#{@table.dataSource.data[@table.clickedRow][:id]}"
    if ("#{@table.clickedColumn}" == "3")      
      @tasks.each do |task|
        if "#{task.id}" == "#{id}"
          task.started? ? task.stop() : task.start()
        else
          task.stop
        end
      end
      save_tasks_to_file
    elsif ("#{@table.clickedColumn}" == "4")
      @tasks.each do |task|
        if "#{task.id}" == "#{id}"
          @task_to_edit = task
          in_edit_mode
        end
      end
    elsif ("#{@table.clickedColumn}" == "5")
      @tasks.each do |task|
        if "#{task.id}" == "#{id}"
          @tasks.delete(task)
        end
      end
      save_tasks_to_file
    else
      throw "Something clicked that we didn't handle! clickedColumn=#{@table.clickedColumn} clickedRow=#{@table.clickedRow}"
    end
    set_table_data
  end
  
  # file/open
  #def on_open(menu)
  #end
  
  # file/new 
  #def on_new(menu)
  #end
  
  # help menu item
  def on_help(menu)
  end
  
  # This is commented out, so the minimize menu item is disabled
  #def on_minimize(menu)
  #end
  
  # window/zoom
  def on_zoom(menu)
  end
  
  # window/bring_all_to_front
  #def on_bring_all_to_front(menu)
  #end
  
  #def applicationDockMenu(sender)
    #menu do |dock|
    #  @tasks.each do |task|
    #    dock.item(:set_current_task,
    #      :title => "#{task.name}",
    #      :action => 'setCurrentTask:',
    #      :representedObject => task
    #    )
    #  end
    #end
  #end
  
private
  def in_add_mode
    #@edit_view.frame = [0, 0, 0, 0]
    #@edit_view.hidden = true
    #@add_view.frame = [0, 0, 0, 40]
    #@add_view.hidden = false
  end
  
  def in_edit_mode
    #@add_view.frame = [0, 0, 0, 0]
    #@add_view.hidden = true
    #@edit_view.frame = [0, 0, 0, 40]
    #@edit_view.hidden = false
    @edit_task_name_field.stringValue = @task_to_edit.name
  end

  def set_table_data
    @table.dataSource.data.clear
    @tasks.each do |task|
      on_off_label = "Start"
      if task.started?
        on_off_label = "Stop"
      end      
      @table.dataSource.data << { :id => task.id, :name => task.name, :time => task.display_time, :on_off => on_off_label, :edit => 'Edit', :remove => 'Del' }
    end
    @table.reloadData
  end
  
  def add_new_task
    name = @new_task_name_field.stringValue
    unless name.nil? || name =~ /^\s*$/
      task = Task.new
      task.id = "#{task.__id__}"
      task.name = name
      @tasks << task
      save_tasks_to_file
      set_table_data
      @new_task_name_field.stringValue = ''
    else
      alert :message => "Cannot create task", :info => "Please enter a task name. '#{name}' is invalid. @new_task_name_field.stringValue=#{@new_task_name_field.stringValue}. @edit_task_name_field.stringValue=#{@edit_task_name_field.stringValue}"
    end
  end
  
  def update_task
    name = @edit_task_name_field.stringValue
    unless name.nil? || name =~ /^\s*$/
      @task_to_edit.name = name
      save_tasks_to_file
      set_table_data
      @edit_task_name_field.stringValue = ''
    else
      alert :message => "Cannot update task", :info => "Please enter a task name. '#{name}' is invalid. @new_task_name_field.stringValue=#{@new_task_name_field.stringValue}. @edit_task_name_field.stringValue=#{@edit_task_name_field.stringValue}"
    end
  end
end

Hourz.new.start
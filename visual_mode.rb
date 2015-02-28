# Visual mode initializers
@file_to_watch_changed = false
@last_modified_time = Time.now
@file_to_watch = '/tmp/.' + SecureRandom.uuid.to_s + '.command'
File.open(@file_to_watch, 'w') {}

def read_file_to_execute
  # read the file, THEN get the last modified time
  command = File.read(@file_to_watch)
  @last_modified_time = File.mtime(@file_to_watch)
  command
end

file_to_execute = Thread.new {
  loop do
    if command_file_changed
     @last_modified_time = File.mtime(@file_to_watch)
     @file_to_watch_changed = true
     Thread.current['file_changed'] = :true
    else
      Kernel.sleep 1
    end
  end
}

def open_command_in_editor(input)
  File.open(@file_to_watch, 'w', 777) { |file|
   file.write(input)
  }
  system("$editor " + @file_to_watch)
end

def command_file_changed
  File.mtime(@file_to_watch) != @last_modified_time
end

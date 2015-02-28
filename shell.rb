require 'io/console'
require 'colorize'
require 'securerandom'
require 'pry'

@constants = {}
@constants[:backspace] = "\x7F"
@constants[:command_c] = "\x03"

@history = []
@history_index = 0
@mode = 'insert'

@aliases = {}
@file_to_watch_changed = false

def get_branch_name
  if system("git branch > /dev/null 2> /dev/null")
    b = `git branch`.split("\n").delete_if { |i| i[0] != "*" }
    branch_name = b.first.gsub("* ","")

    if branch_name == 'master'
      branch_name.green
    else
      branch_name.red
    end
  else
    ''
  end
end

def current_dir
  Dir.pwd.yellow
end

def calc_prefix
  branch = ''
  branch += current_dir
  if get_branch_name != ''
    branch += '::' + get_branch_name
  end
  branch += '> '
end

@shell_prefix = "calc_prefix"
## @shell_prefix = "Dir.pwd.green + '> '"

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



def command_file_changed
  File.mtime(@file_to_watch) != @last_modified_time
end

def shell_prefix
  return eval(@aliases['shell_prefix'] || @shell_prefix).to_s 
end

print shell_prefix
exit_keywords = %w[quit exit]

input = ''

def display_error_message(input)
  puts "Unknown command: " + input
end

def execute_command(input)
  if input == ""
    # nop
  else
    output = system(input)
    if output.nil?
      display_error_message(input)
    end
  end
end

def exit_shell
  File.delete(@file_to_watch)
  puts
  exit
end

def handle_up_arrow
  if @history_index < @history.length + 1
    input = @history.reverse.values_at(@history_index).first
    @history_index += 1 
  end

  input ||= ''
    
  print "\e[1K\e[0K\r" + shell_prefix + input

  input
end

def handle_down_arrow
  if @history_index > 0
    @history_index -= 1 
    input = @history.reverse.values_at(@history_index).first
  else
    input = ""
  end
  input ||= ''
 
  print "\e[1K\e[0K\r" + shell_prefix + input

  input
end

def handle_special_char(char)
  case char
  when '[A'
    input = handle_up_arrow
  when '[B'
    input = handle_down_arrow
  when '[D'
    puts 'left arrow'
  when '[C'
    puts 'right arrow'
  else
    puts 'Not sure what you gave me...'
  end

  input
end

def open_command_in_editor(input)
  File.open(@file_to_watch, 'w') { |file|
   file.write(input)
  }
  system("$editor " + @file_to_watch)
end

def update_input_string(input)
  # get last character and display it
  last_char = STDIN.getch

  case last_char 
  when '`'
      open_command_in_editor(input)
  when "\e"
        # get any modifiers
        last_char = STDIN.getch
        last_char << STDIN.getch
        input = handle_special_char(last_char)
  when @constants[:backspace]
      # stop us from removing the shell prefix
      if input.length > 0
        print "\b \b"
        input = input[0..-2]
      end
  when @constants[:command_c]
      exit_shell 
  else
      print last_char
      input << last_char
  end

  input
end

def exec_builtins(input)
  executed = false

  args = input.split(" ")
  case args.first
  when 'cd'
    begin
      # show where we are
      puts shell_prefix + input

      #actually change
      Dir.chdir(args[1..-1].join(" "))

      # Show where we went
      puts Dir.pwd

      # back to accept a new command
      print shell_prefix
      executed = true
    rescue
      puts 'Could not cd into path: ' + args[1..-1].join(" ")
      executed = true
      print shell_prefix
    end
  when 'history'
    puts shell_prefix + input
    @history.each_with_index do |entry, index|
      puts index.to_s + ' : ' + entry
    end
    print shell_prefix

    executed = true
  when 'alias'
    puts shell_prefix + input
    key = input.split(' ')[1].split('=').first
    value = input.split('=').last.gsub('"', '')
 
    @aliases[key] = value
    puts key + ' aliased to: ' + value 
    executed = true 
    print shell_prefix
  end

  executed
end

def substitute_last_arg(input)
    if @history.last.split(" ")[1..-1]
      input.gsub!('!$', @history.last.split(" ")[1..-1].join(" "))
    end
    input
end

def parse_special_symbols(input)
  if @history.last != nil
    input.gsub!('!!', @history.last)
    input = substitute_last_arg(input)
  end

  if input.scan(/!\d/) != []
    # get all digits, convert to int
    input = @history[input.scan(/!\d+/).first[1..-1].to_i]
  end
 
  input
end

while(true) do
  
  input ||= ''

  input = update_input_string(input)

  if @file_to_watch_changed #file_to_execute['file_changed'] == :true
    input = read_file_to_execute
    @file_to_watch_changed = false
  #  file_to_execute['file_changed'] = :false
  end
 
  # handle returning a nil value 
  input ||= ''

  if (input[-1] == "\r" || input[-1] == "\n")
    # remove return 
    input = input.strip

    if (!exit_keywords.include? (input))
      if (@aliases.has_key? input)
        puts shell_prefix + input
        input = @aliases[input]
      end
      input = parse_special_symbols(input)
      already_executed = exec_builtins(input)
      if already_executed
        @history << input
        @history_index = 0
        input = ''
      else
        puts shell_prefix + input
        execute_command(input)

        if (!input.empty? && input[0] != '!')
          @history << input
          @history_index = 0
        end

        input = '';
        print shell_prefix
      end
    else
      exit_shell
    end
  end
end

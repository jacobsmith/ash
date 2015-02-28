require_relative 'helper'

# initialize constants
@constants = {}
@constants[:backspace] = "\x7F"
@constants[:command_c] = "\x03"
@constants[:tab] = "\t"

# initialize history
@history = []
@history_index = 0

# initialize aliases
@aliases = {}
# TODO: read in alias file

@directory_locations = []
@directory_locations << Dir.pwd
@back_history = 0

@shell_prefix = "calc_prefix"

def shell_prefix
  return eval(@aliases['shell_prefix'] || @shell_prefix).to_s 
end

# Setup UI
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

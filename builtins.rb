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

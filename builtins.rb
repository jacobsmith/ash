def exec_builtins(input)
  executed = false

  args = input.split(" ")
  case args.first
  when 'cd'
    begin
      # handle jumping to the last directory
      if args[1] == "-"
        @back_history = 0
        puts shell_prefix + input
       
        Dir.chdir(@directory_locations[(@directory_locations.length)-2])
        @directory_locations << Dir.pwd 
        
        # Show where we went
        puts Dir.pwd
        
        # back to accept a new command
        print shell_prefix
        executed = true
      elsif args[1] == "<"
        Dir.chdir(
          @directory_locations[@directory_locations.length - @back_history - 1])
        @back_history += 1
        
        puts shell_prefix + input
        # Show where we went
        puts Dir.pwd
        
        # back to accept a new command
        print shell_prefix
        executed = true
      elsif %w[history -h].include? args[1]
        puts shell_prefix + input
        puts @directory_locations
        
        # back to accept a new command
        print shell_prefix
        executed = true
      else  
        @back_history = 0
        # show where we are
        puts shell_prefix + input
        #actually change
        Dir.chdir(args[1..-1].join(" "))
        @directory_locations << Dir.pwd

        # Show where we went
        puts Dir.pwd

        # back to accept a new command
        print shell_prefix
        executed = true
      end
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
    if input.scan(/$alias -g/)
      persist = true
      input.sub!("alias -g", 'alias')
    end

    puts shell_prefix + input
    key = input.split(' ')[1].split('=').first
    value = input.split('=').last.gsub('"', '')
 
    @aliases[key] = value
    puts key + ' aliased to: ' + value 

    if persist
      File.open('aliases.yaml', 'a') { |file|
        file.write({key => value}.to_yaml.sub("---", ''))
      }
    end

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

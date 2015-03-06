def handle_tab_expansion(input, last_char)
    input << last_char

    if input.match(/ \S*\t/)
      glob = input.match(/ \S*\t/).to_s
      glob.gsub!(/\t/, "")
      glob.gsub!(/ /, "")
    elsif input.match(/ \t/)
      glob = input.match(/ \t/).to_s 
      glob.gsub!(/\t/, "")
      glob.gsub!(/ /, "")
    elsif input.match(/\.\/\w*\t/)
      glob = input.match(/\.\/\w*\t/).to_s
      glob.gsub!(/\t/, "")
    end

    puts

    options = Dir.glob("#{glob}*")

    if options.length == 1
      input.gsub!(/ \S*\t/, ' ' + options.first)
    else
      known_path = input.scan(/\S*\t/).first.sub("\t", '').sub(/\S\\/, '')
      b = options.each do |file|
        case File.ftype(file)
        when 'file'
          if known_path[-1] == "/"
            puts file.sub(known_path, '').green
          else
            puts file.green
          end
        when 'directory'
          if known_path[-1] == "/"
            puts (file.sub(known_path, '') + '/').instance_eval(@colors['directories'])
          else
            puts (file + '/').instance_eval(@colors['directories'])
          end
        else
          puts file.blue
        end
      end
    end
  
    if options != [] 
      match = find_unambiguous_string(options)
      input.gsub!(/\S*\t/, match)
    end
     
    input.sub!(/\t/, "") 
    print shell_prefix + input
end

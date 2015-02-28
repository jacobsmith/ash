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

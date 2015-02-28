def read_in_aliases
  @aliases = YAML.load_file('aliases.yaml')
end

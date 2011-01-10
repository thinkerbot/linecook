#############################################################################
helpers '<%= project_name %>'
attributes '<%= project_name %>'
#############################################################################

# Write to the script target using 'script'
target.puts '# An example script.'

# Helpers are now available, as are attributes.
echo *attrs['<%= project_name %>']['letters']
echo *attrs['<%= project_name %>']['numbers']

# Use files like this:
cat file_path('file.txt')

# Use templates like this:
cat template_path('template.txt', :n => 10)

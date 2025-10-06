#!/usr/bin/env ruby
# DOGE Network Ruby Template Setup Script
# This script helps customize the template for your state

require "fileutils"

puts "🐕 DOGE Network Ruby Template Setup"
puts "=================================="
puts

# Get state information from user
print "Enter your state name (e.g., Kansas): "
state_name = gets.chomp.strip

print "Enter your state abbreviation (e.g., KS): "
state_abbrev = gets.chomp.strip.upcase

print "Enter your state URL subdomain (e.g., kansas): "
state_subdomain = gets.chomp.strip.downcase

puts
puts "Setting up template for #{state_name} (#{state_abbrev})..."
puts

# Files to process
files_to_update = [
  "_config.yml",
  "index.md",
  "savings.md",
  "regulations.md",
  "_includes/header.html",
]

# Replace template variables
files_to_update.each do |file|
  if File.exist?(file)
    puts "Updating #{file}..."
    content = File.read(file)

    # Replace template variables
    content.gsub!("{{STATE_NAME}}", state_name)
    content.gsub!("{{STATE_ABBREV}}", state_abbrev)
    content.gsub!("{{STATE_SUBDOMAIN}}", state_subdomain)

    File.write(file, content)
    puts "✓ #{file} updated"
  else
    puts "⚠ #{file} not found, skipping"
  end
end

puts
puts "🎉 Template setup complete!"
puts
puts "Next steps:"
puts "1. Replace state-flag.svg with your state's flag. Keep the same name."
puts "2. Update the example data in savings.md and regulations.md"
puts "3. Run: bundle exec jekyll serve"
puts "4. Visit: http://localhost:4000"
puts
puts "For more help, see README.md"

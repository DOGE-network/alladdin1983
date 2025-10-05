#!/usr/bin/env ruby
# DOGE Network Template Sync Script
# Helps state sites sync updates FROM the template repository

require 'fileutils'
require 'open3'
require 'yaml'

class TemplateSync
  TEMPLATE_REPO = "https://github.com/DOGE-network/DOGE_Network_Ruby_Template.git"
  TEMPLATE_BRANCH = "main"
  TEMP_DIR = ".template_temp"
  
  # Files that are usually safe to merge (no state-specific content)
  SAFE_TO_MERGE = [
    'Gemfile',
    'Gemfile.lock',
    '_includes/footer.html',
    '_includes/tweet.html',
    'assets/main.scss',
    'assets/css/main.scss',
    'LICENSE.md',
    'doge-network.png'
  ]
  
  # Files that likely have state-specific content needing review
  NEEDS_REVIEW = [
    '_config.yml',
    'index.md',
    'savings.md',
    'regulations.md',
    '_includes/header.html'
  ]
  
  # Template-only files (your state site shouldn't modify these)
  TEMPLATE_TOOLS = [
    'setup.rb',
    'sync.rb',
    'CHANGELOG.md',
    'UPGRADE_FROM_v0.1.0.md'
  ]
  
  def initialize
    @config = load_config
  end
  
  def load_config
    if File.exist?('_config.yml')
      YAML.load_file('_config.yml')
    else
      {}
    end
  end
  
  def run
    puts "🐕 DOGE Network Template Sync"
    puts "============================="
    puts
    
    current_version = @config['version'] || 'unknown'
    state_name = @config['state_name'] || 'Unknown State'
    
    puts "Your state site: #{state_name}"
    puts "Your version: v#{current_version}"
    puts "Template repo: #{TEMPLATE_REPO}"
    puts
    
    puts "Choose an option:"
    puts "1. Check for template updates"
    puts "2. Compare specific file with template"
    puts "3. List file categories (safe vs. needs review)"
    puts "4. Setup template remote (for manual sync)"
    puts "5. View changelog"
    puts "6. Exit"
    print "\nChoice: "
    
    choice = gets.chomp
    
    case choice
    when "1"
      check_template_updates
    when "2"
      compare_file
    when "3"
      list_categories
    when "4"
      setup_remote
    when "5"
      view_changelog
    when "6"
      puts "Exiting..."
      exit 0
    else
      puts "Invalid choice"
    end
  end
  
  def check_template_updates
    puts "\n📥 Fetching template repository..."
    
    if Dir.exist?(TEMP_DIR)
      FileUtils.rm_rf(TEMP_DIR)
    end
    
    # Clone template repo
    system("git clone --depth 1 -b #{TEMPLATE_BRANCH} #{TEMPLATE_REPO} #{TEMP_DIR} 2>&1 | grep -v 'Cloning'")
    
    if !$?.success?
      puts "❌ Failed to fetch template repository"
      puts "Make sure you have internet connection and git is installed"
      return
    end
    
    puts "✓ Template fetched successfully\n"
    
    # Check version
    template_config_path = File.join(TEMP_DIR, '_config.yml')
    if File.exist?(template_config_path)
      template_config = YAML.load_file(template_config_path)
      template_version = template_config['version']
      
      puts "📦 Template version: v#{template_version}"
      puts "📦 Your version: v#{@config['version']}"
      puts
      
      if template_version != @config['version']
        puts "🆕 New template version available!"
        puts
      else
        puts "✓ You're on the latest template version"
        puts
      end
    end
    
    # Compare files
    compare_all_files
    
    cleanup
  end
  
  def compare_all_files
    puts "📊 Comparing your files with template...\n"
    
    changes = {
      safe: [],
      needs_review: [],
      tools: [],
      new_in_template: []
    }
    
    # Check files that exist locally
    all_tracked = SAFE_TO_MERGE + NEEDS_REVIEW + TEMPLATE_TOOLS
    
    all_tracked.each do |file|
      template_file = File.join(TEMP_DIR, file)
      
      if File.exist?(file) && File.exist?(template_file)
        if files_differ?(file, template_file)
          if SAFE_TO_MERGE.include?(file)
            changes[:safe] << file
          elsif NEEDS_REVIEW.include?(file)
            changes[:needs_review] << file
          elsif TEMPLATE_TOOLS.include?(file)
            changes[:tools] << file
          end
        end
      elsif File.exist?(template_file) && !File.exist?(file)
        changes[:new_in_template] << file
      end
    end
    
    # Display results
    if changes[:safe].any?
      puts "✅ SAFE TO MERGE (no state-specific content):"
      changes[:safe].each { |f| puts "   - #{f}" }
      puts "   → These files are usually safe to copy from template"
      puts
    end
    
    if changes[:needs_review].any?
      puts "⚠️  NEEDS REVIEW (may have your state data):"
      changes[:needs_review].each { |f| puts "   - #{f}" }
      puts "   → Check these carefully before merging"
      puts "   → Use option 2 to compare specific files"
      puts
    end
    
    if changes[:tools].any?
      puts "🔧 TEMPLATE TOOLS UPDATED:"
      changes[:tools].each { |f| puts "   - #{f}" }
      puts "   → Safe to copy, these are template utilities"
      puts
    end
    
    if changes[:new_in_template].any?
      puts "🆕 NEW FILES IN TEMPLATE:"
      changes[:new_in_template].each { |f| puts "   - #{f}" }
      puts "   → Consider adding these to your site"
      puts
    end
    
    if changes.values.all?(&:empty?)
      puts "✨ No differences found! Your site matches the template."
      puts
    else
      puts "💡 Next steps:"
      puts "   1. Use option 2 to compare specific files"
      puts "   2. Review CHANGELOG.md for details about changes"
      puts "   3. Test changes in a branch before merging to main"
      puts "   4. Keep your state-specific data (names, stats, links)"
      puts
    end
  end
  
  def files_differ?(file1, file2)
    content1 = File.read(file1)
    content2 = File.read(file2)
    
    # Normalize line endings
    content1.gsub!("\r\n", "\n")
    content2.gsub!("\r\n", "\n")
    
    content1 != content2
  end
  
  def compare_file
    print "\nEnter filename to compare (e.g., _config.yml): "
    filename = gets.chomp.strip
    
    if filename.empty?
      puts "❌ No filename provided"
      return
    end
    
    if !File.exist?(filename)
      puts "❌ File not found locally: #{filename}"
      puts "   (If it's a new file in template, use option 1 to see it)"
      return
    end
    
    puts "\n📥 Fetching template repository..."
    
    if !Dir.exist?(TEMP_DIR)
      system("git clone --depth 1 -b #{TEMPLATE_BRANCH} #{TEMPLATE_REPO} #{TEMP_DIR} 2>&1 | grep -v 'Cloning'")
      if !$?.success?
        puts "❌ Failed to fetch template"
        return
      end
    end
    
    template_file = File.join(TEMP_DIR, filename)
    
    if !File.exist?(template_file)
      puts "❌ File doesn't exist in template: #{filename}"
      puts "   (This might be a file specific to your state site)"
      cleanup
      return
    end
    
    puts "\n📋 Comparing #{filename}...\n"
    puts "━" * 60
    
    # Use diff to show differences
    diff_output, status = Open3.capture2("diff -u #{template_file} #{filename}")
    
    if status.success?
      puts "✓ Files are identical"
    else
      # Colorize output if possible
      lines = diff_output.split("\n")
      lines.each do |line|
        if line.start_with?('---') || line.start_with?('+++')
          puts line
        elsif line.start_with?('-')
          puts line  # Would be red in color terminal
        elsif line.start_with?('+')
          puts line  # Would be green in color terminal
        elsif line.start_with?('@@')
          puts "\n#{line}"
        else
          puts line
        end
      end
    end
    
    puts "\n━" * 60
    puts "\n💡 Legend:"
    puts "   Lines with '-' are from TEMPLATE (may want to adopt)"
    puts "   Lines with '+' are YOURS (your customizations)"
    puts "\n📖 See CHANGELOG.md for context on template changes"
    
    cleanup
  end
  
  def list_categories
    puts "\n📋 File Categories\n"
    
    puts "✅ SAFE TO MERGE (usually no state-specific content):"
    SAFE_TO_MERGE.each { |f| puts "   - #{f}" }
    puts
    
    puts "⚠️  NEEDS REVIEW (contains your state data):"
    NEEDS_REVIEW.each { |f| puts "   - #{f}" }
    puts
    
    puts "🔧 TEMPLATE TOOLS (safe to update):"
    TEMPLATE_TOOLS.each { |f| puts "   - #{f}" }
    puts
    
    puts "Strategy:"
    puts "   • SAFE TO MERGE: Copy from template freely"
    puts "   • NEEDS REVIEW: Compare carefully, keep your state info"
    puts "   • TEMPLATE TOOLS: Update to get latest features"
    puts
  end
  
  def setup_remote
    puts "\n⚙️  Setting up template remote for manual sync...\n"
    
    # Check if template remote exists
    stdout, stderr, status = Open3.capture3("git remote get-url template 2>&1")
    
    if status.success?
      puts "✓ Template remote already exists: #{stdout.strip}"
      puts
      print "Do you want to update it? (y/n): "
      if gets.chomp.downcase == 'y'
        system("git remote set-url template #{TEMPLATE_REPO}")
        puts "✓ Updated template remote"
      end
    else
      system("git remote add template #{TEMPLATE_REPO}")
      puts "✓ Added template remote: #{TEMPLATE_REPO}"
    end
    
    puts "\n📖 Manual sync commands:"
    puts "   # Fetch template changes"
    puts "   git fetch template"
    puts
    puts "   # Compare specific file"
    puts "   git diff template/#{TEMPLATE_BRANCH} -- _config.yml"
    puts
    puts "   # See all changes"
    puts "   git diff template/#{TEMPLATE_BRANCH}"
    puts
    puts "   # Merge specific file (careful!)"
    puts "   git checkout template/#{TEMPLATE_BRANCH} -- Gemfile"
    puts
    puts "⚠️  Always test changes in a branch first!"
    puts
  end
  
  def view_changelog
    if Dir.exist?(TEMP_DIR)
      changelog_path = File.join(TEMP_DIR, 'CHANGELOG.md')
    else
      puts "\n📥 Fetching template repository..."
      system("git clone --depth 1 -b #{TEMPLATE_BRANCH} #{TEMPLATE_REPO} #{TEMP_DIR} 2>&1 | grep -v 'Cloning'")
      changelog_path = File.join(TEMP_DIR, 'CHANGELOG.md')
    end
    
    if File.exist?(changelog_path)
      puts "\n📖 Template Changelog:\n"
      puts "━" * 60
      puts File.read(changelog_path)
      puts "━" * 60
    else
      puts "❌ CHANGELOG.md not found in template"
    end
    
    cleanup
  end
  
  def cleanup
    if Dir.exist?(TEMP_DIR)
      FileUtils.rm_rf(TEMP_DIR)
    end
  end
end

# Handle cleanup on interrupt
trap("INT") do
  puts "\n\n🧹 Cleaning up..."
  FileUtils.rm_rf(TemplateSync::TEMP_DIR) if Dir.exist?(TemplateSync::TEMP_DIR)
  exit
end

# Run the sync tool
begin
  sync = TemplateSync.new
  sync.run
rescue => e
  puts "\n❌ Error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
  FileUtils.rm_rf(TemplateSync::TEMP_DIR) if Dir.exist?(TemplateSync::TEMP_DIR)
  exit 1
end
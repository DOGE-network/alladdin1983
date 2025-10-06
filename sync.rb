#!/usr/bin/env ruby
# DOGE Network Template Sync Script
# Helps state sites sync updates FROM the template repository

require "English"
require "fileutils"
require "open3"
require "yaml"

class TemplateSync
  TEMPLATE_REPO = "https://github.com/DOGE-network/DOGE_Network_Ruby_Template.git".freeze
  TEMPLATE_BRANCH = "master".freeze
  TEMP_DIR = ".template_temp".freeze

  # Files that are usually safe to merge (no state-specific content)
  SAFE_TO_MERGE = [
    "Gemfile",
    "Gemfile.lock",
    "_includes/footer.html",
    "_includes/tweet.html",
    "_includes/youtube.html",
    "assets/main.scss",
    "assets/css/main.scss",
    "LICENSE.md",
    "doge-network.png",
  ].freeze

  # Files that likely have state-specific content needing review
  NEEDS_REVIEW = [
    "_config.yml",
    "index.md",
    "savings.md",
    "regulations.md",
    "_includes/header.html",
  ].freeze

  # Template-only files (your state site shouldn't modify these)
  TEMPLATE_TOOLS = [
    "setup.rb",
    "sync.rb",
    "CHANGELOG.md",
    "UPGRADE_FROM_v0.1.0.md",
  ].freeze

  def initialize
    @config = load_config
  end

  def load_config
    if File.exist?("_config.yml")
      YAML.load_file("_config.yml")
    else
      {}
    end
  end

  def run
    puts "🐕 DOGE Network Template Sync"
    puts "============================="
    puts

    current_version = @config["version"] || "unknown"
    state_name = @config["state_name"] || "Unknown State"

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
    puts "6. Create PR with diff between template and local repository"
    puts "7. Exit"
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
      create_pr_with_diff
    when "7"
      puts "Exiting..."
      exit 0
    else
      puts "Invalid choice"
    end
  end

  def check_template_updates
    puts "\n📥 Fetching template repository..."

    FileUtils.rm_rf(TEMP_DIR)

    # Clone template repo
    system("git clone --depth 1 -b #{TEMPLATE_BRANCH} #{TEMPLATE_REPO} #{TEMP_DIR} 2>&1 | grep -v 'Cloning'")

    unless $CHILD_STATUS.success?
      puts "❌ Failed to fetch template repository"
      puts "Make sure you have internet connection and git is installed"
      return
    end

    puts "✓ Template fetched successfully\n"

    # Check version
    template_config_path = File.join(TEMP_DIR, "_config.yml")
    if File.exist?(template_config_path)
      template_config = YAML.load_file(template_config_path)
      template_version = template_config["version"]

      puts "📦 Template version: v#{template_version}"
      puts "📦 Your version: v#{@config['version']}"
      puts

      if template_version == @config["version"]
        puts "✓ You're on the latest template version"
      else
        puts "🆕 New template version available!"
      end
      puts
      puts
    end

    # Compare files
    compare_all_files

    cleanup
  end

  def compare_all_files
    puts "📊 Comparing your files with template...\n"

    changes = {
      safe:            [],
      needs_review:    [],
      tools:           [],
      new_in_template: [],
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
    else
      puts "💡 Next steps:"
      puts "   1. Use option 2 to compare specific files"
      puts "   2. Review CHANGELOG.md for details about changes"
      puts "   3. Test changes in a branch before merging to main"
      puts "   4. Keep your state-specific data (names, stats, links)"
    end
    puts
  end

  def files_differ?(file1, file2)
    begin
      # Check if files are binary first
      if binary_file?(file1) || binary_file?(file2)
        # For binary files, compare file sizes and modification times
        return File.size(file1) != File.size(file2) if File.exist?(file1) && File.exist?(file2)
        return true # One exists, one doesn't
      end
      
      # Try different encodings for text files
      content1 = read_file_with_encoding(file1)
      content2 = read_file_with_encoding(file2)

      # Normalize line endings
      content1.gsub!("\r\n", "\n")
      content2.gsub!("\r\n", "\n")

      content1 != content2
    rescue => e
      # If there's an encoding error, treat as different
      puts "   Warning: Could not compare #{file1} and #{file2}: #{e.message}"
      true
    end
  end

  def read_file_with_encoding(file_path)
    # Try different encodings in order of preference
    encodings = ['UTF-8', 'ISO-8859-1', 'Windows-1252', 'US-ASCII']
    
    encodings.each do |encoding|
      begin
        return File.read(file_path, encoding: encoding)
      rescue => e
        next
      end
    end
    
    # If all encodings fail, read as binary and convert to string
    File.read(file_path, mode: 'rb').force_encoding('UTF-8')
  end

  def compare_file
    print "\nEnter filename to compare (e.g., _config.yml): "
    filename = gets.chomp.strip

    if filename.empty?
      puts "❌ No filename provided"
      return
    end

    unless File.exist?(filename)
      puts "❌ File not found locally: #{filename}"
      puts "   (If it's a new file in template, use option 1 to see it)"
      return
    end

    puts "\n📥 Fetching template repository..."

    unless Dir.exist?(TEMP_DIR)
      system("git clone --depth 1 -b #{TEMPLATE_BRANCH} #{TEMPLATE_REPO} #{TEMP_DIR} 2>&1 | grep -v 'Cloning'")
      unless $CHILD_STATUS.success?
        puts "❌ Failed to fetch template"
        return
      end
    end

    template_file = File.join(TEMP_DIR, filename)

    unless File.exist?(template_file)
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
        if line.start_with?("---", "+++")
          puts line
        elsif line.start_with?("-")
          puts line  # Would be red in color terminal
        elsif line.start_with?("+")
          puts line  # Would be green in color terminal
        elsif line.start_with?("@@")
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
    stdout, _, status = Open3.capture3("git remote get-url template 2>&1")

    if status.success?
      puts "✓ Template remote already exists: #{stdout.strip}"
      puts
      print "Do you want to update it? (y/n): "
      if gets.chomp.downcase == "y"
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
    unless Dir.exist?(TEMP_DIR)
      puts "\n📥 Fetching template repository..."
      system("git clone --depth 1 -b #{TEMPLATE_BRANCH} #{TEMPLATE_REPO} #{TEMP_DIR} 2>&1 | grep -v 'Cloning'")
    end
    changelog_path = File.join(TEMP_DIR, "CHANGELOG.md")

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

  def create_pr_with_diff
    puts "\n📤 Create PR with Template Repository"
    puts "=====================================\n"
    puts "This will open your browser to create a pull request"
    puts "comparing your local repository with the template repository."
    puts

    # Check if we're in a git repository
    unless Dir.exist?(".git")
      puts "❌ Not in a git repository. Please run this from your state site directory."
      return
    end

    # Get current repository info
    repo_info = get_repo_info
    unless repo_info
      puts "❌ Could not determine repository information."
      return
    end

    puts "📋 Repository Information:"
    puts "   Local repo: #{repo_info[:local_repo]}"
    puts "   Template repo: #{TEMPLATE_REPO}"
    puts

    # Get current branch name
    current_branch = get_current_branch
    puts "   Current branch: #{current_branch}"
    puts

    # Create PR URL
    pr_url = "https://github.com/DOGE-network/DOGE_Network_Ruby_Template/compare/master...#{repo_info[:owner]}:#{repo_info[:repo]}:#{current_branch}?expand=1"
    
    puts "🌐 Opening browser to create PR..."
    puts "   URL: #{pr_url}"
    puts

    # Open browser
    if RUBY_PLATFORM =~ /darwin/
      system("open '#{pr_url}'")
      puts "✅ Browser opened on macOS"
    elsif RUBY_PLATFORM =~ /linux/
      system("xdg-open '#{pr_url}'")
      puts "✅ Browser opened on Linux"
    elsif RUBY_PLATFORM =~ /mswin|mingw|cygwin/
      system("start '#{pr_url}'")
      puts "✅ Browser opened on Windows"
    else
      puts "❌ Could not determine how to open browser on this platform"
      puts "   Please manually visit: #{pr_url}"
      return
    end

    puts "\n📋 Next steps:"
    puts "   1. The browser should open to the PR creation page"
    puts "   2. Add a title like: 'Sync changes from #{repo_info[:repo]}'"
    puts "   3. Add a description explaining your changes"
    puts "   4. Review the diff and submit the PR"
    puts "\n💡 This will create a PR from your #{current_branch} branch to the template's master branch"
  end

  def get_current_branch
    stdout, _, status = Open3.capture3("git rev-parse --abbrev-ref HEAD")
    if status.success?
      stdout.strip
    else
      "main" # fallback
    end
  end

  def get_repo_info
    # Get the remote origin URL
    stdout, _, status = Open3.capture3("git remote get-url origin 2>&1")
    
    unless status.success?
      puts "❌ Could not get remote origin URL. Make sure you have a remote configured."
      return nil
    end

    origin_url = stdout.strip
    
    # Extract owner and repo from URL - handle both HTTPS and SSH formats
    # Try HTTPS format first
    if match = origin_url.match(/github\.com\/([^\/]+)\/([^\/]+?)(?:\.git)?$/)
      owner = match[1]
      repo = match[2]
      return {
        local_repo: "#{owner}/#{repo}",
        owner: owner,
        repo: repo,
        origin_url: origin_url
      }
    # Try SSH format
    elsif match = origin_url.match(/git@github\.com:([^\/]+)\/([^\/]+?)(?:\.git)?$/)
      owner = match[1]
      repo = match[2]
      return {
        local_repo: "#{owner}/#{repo}",
        owner: owner,
        repo: repo,
        origin_url: origin_url
      }
    else
      puts "❌ Could not parse GitHub repository from origin URL: #{origin_url}"
      puts "   Expected format: https://github.com/owner/repo or git@github.com:owner/repo"
      return nil
    end
  end

  def generate_repo_diff
    # Create a comprehensive diff between template and local repository
    # This will show all differences in tracked files
    
    # Get list of all files in both repositories
    local_files = get_tracked_files(".")
    template_files = get_tracked_files(TEMP_DIR)
    
    all_files = (local_files + template_files).uniq.sort
    
    diff_parts = []
    
    all_files.each do |file|
      begin
        local_file = file
        template_file = File.join(TEMP_DIR, file)
        
        # Skip if both files don't exist
        next unless File.exist?(local_file) || File.exist?(template_file)
        
        # Skip if files are identical
        if File.exist?(local_file) && File.exist?(template_file)
          begin
            next unless files_differ?(local_file, template_file)
          rescue => e
            puts "   Warning: Could not compare #{file} due to error: #{e.message}"
            next
          end
        end
        
        # Check if file is binary
        is_binary = binary_file?(local_file) || binary_file?(template_file)
        
        # Generate diff for this file
        if File.exist?(local_file) && File.exist?(template_file)
          # Both files exist, show diff
          if is_binary
            diff_parts << "diff --git a/#{file} b/#{file}"
            diff_parts << "index #{get_file_hash(template_file)}..#{get_file_hash(local_file)}"
            diff_parts << "Binary files differ"
          else
            diff_output, _ = Open3.capture2("diff -u #{template_file} #{local_file}")
            diff_parts << "diff --git a/#{file} b/#{file}"
            diff_parts << "index #{get_file_hash(template_file)}..#{get_file_hash(local_file)}"
            diff_parts << "--- a/#{file}"
            diff_parts << "+++ b/#{file}"
            diff_parts << diff_output.split("\n")[2..-1].join("\n") if diff_output.split("\n").length > 2
          end
        elsif File.exist?(local_file)
          # File only exists locally
          diff_parts << "diff --git a/#{file} b/#{file}"
          diff_parts << "new file mode 100644"
          diff_parts << "index 0000000..#{get_file_hash(local_file)}"
          diff_parts << "--- /dev/null"
          diff_parts << "+++ b/#{file}"
          if is_binary
            diff_parts << "Binary file added"
          else
            begin
              content = read_file_with_encoding(local_file)
              diff_parts << "+" + content.lines.map { |line| line.chomp }.join("\n+")
            rescue => e
              diff_parts << "+[Binary file content]"
            end
          end
        else
          # File only exists in template
          diff_parts << "diff --git a/#{file} b/#{file}"
          diff_parts << "deleted file mode 100644"
          diff_parts << "index #{get_file_hash(template_file)}..0000000"
          diff_parts << "--- a/#{file}"
          diff_parts << "+++ /dev/null"
          if is_binary
            diff_parts << "Binary file removed"
          else
            begin
              content = read_file_with_encoding(template_file)
              diff_parts << "-" + content.lines.map { |line| line.chomp }.join("\n-")
            rescue => e
              diff_parts << "-[Binary file content]"
            end
          end
        end
        
        diff_parts << "" # Empty line between files
      rescue => e
        puts "   Warning: Skipping file #{file} due to error: #{e.message}"
        next
      end
    end
    
    diff_parts.join("\n")
  end

  def get_tracked_files(repo_path)
    # Get all tracked files in the repository
    Dir.chdir(repo_path) do
      stdout, _, status = Open3.capture3("git ls-files")
      return [] unless status.success?
      stdout.lines.map(&:strip)
    end
  end

  def get_file_hash(file_path)
    # Get a short hash for the file (simplified)
    return "0000000" unless File.exist?(file_path)
    
    # Use file size and modification time as a simple hash
    stat = File.stat(file_path)
    "#{stat.size.to_s(16)}#{stat.mtime.to_i.to_s(16)}"[0...7]
  end

  def binary_file?(file_path)
    return false unless File.exist?(file_path)
    
    # Check if file is binary by reading first 1024 bytes
    begin
      File.open(file_path, 'rb') do |file|
        chunk = file.read(1024)
        return chunk.include?("\0") || chunk.include?("\x00")
      end
    rescue
      # If we can't read the file, assume it's binary
      true
    end
  end

  def count_different_files(diff_output)
    # Count the number of files that have differences
    diff_output.scan(/^diff --git/).count
  end

  def create_github_pr(repo_info, diff_output)
    puts "\n🔧 Creating GitHub PR..."
    
    # Create a branch for the PR
    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    branch_name = "template-diff-#{timestamp}"
    
    puts "📝 Creating branch: #{branch_name}"
    
    # Create and checkout new branch
    system("git checkout -b #{branch_name}")
    unless $CHILD_STATUS.success?
      puts "❌ Failed to create branch. You may already be on a different branch."
      return
    end
    
    # Create a diff file
    diff_file = "template-diff-#{timestamp}.patch"
    File.write(diff_file, diff_output)
    
    # Add and commit the diff file
    system("git add #{diff_file}")
    system("git commit -m 'Add diff between template and local repository'")
    
    # Push the branch
    puts "📤 Pushing branch to origin..."
    system("git push origin #{branch_name}")
    
    unless $CHILD_STATUS.success?
      puts "❌ Failed to push branch. Please check your git configuration."
      puts "   Make sure you have push access to the repository."
      return
    end
    
    # Generate PR URL
    pr_url = "https://github.com/#{repo_info[:local_repo]}/compare/#{branch_name}"
    
    puts "\n✅ Branch created and pushed successfully!"
    puts "\n📋 Next steps:"
    puts "   1. Visit: #{pr_url}"
    puts "   2. Click 'Create pull request'"
    puts "   3. Add a title like: 'Diff between template and local repository'"
    puts "   4. Add description explaining the differences"
    puts "   5. Submit the PR"
    puts "\n💡 The diff file '#{diff_file}' has been included in the commit for reference."
    
    # Try to open the URL if possible
    if RUBY_PLATFORM =~ /darwin/
      system("open '#{pr_url}'")
    elsif RUBY_PLATFORM =~ /linux/
      system("xdg-open '#{pr_url}'")
    end
  end

  def identify_push_candidates
    candidates = []

    # Check SAFE_TO_MERGE and TEMPLATE_TOOLS files
    pushable_files = SAFE_TO_MERGE + TEMPLATE_TOOLS

    pushable_files.each do |file|
      template_file = File.join(TEMP_DIR, file)

      next unless File.exist?(file)

      if !File.exist?(template_file)
        # New file we created that might be useful for template
        candidates << {
          path:     file,
          status:   :new,
          category: categorize_file(file),
        }
      elsif files_differ?(file, template_file)
        # We have changes that differ from template
        candidates << {
          path:     file,
          status:   :modified,
          category: categorize_file(file),
        }
      end
    end

    # Also check for new includes or assets
    %w[_includes assets].each do |dir|
      next unless Dir.exist?(dir)

      Dir.glob("#{dir}/**/*").each do |file|
        next if File.directory?(file)
        next if file.include?("state-") # Skip state-specific files

        template_file = File.join(TEMP_DIR, file)

        if !File.exist?(template_file)
          candidates << {
            path:     file,
            status:   :new,
            category: "new feature",
          }
        elsif files_differ?(file, template_file)
          candidates << {
            path:     file,
            status:   :modified,
            category: "improvement",
          }
        end
      end
    end

    candidates
  end

  def categorize_file(file)
    return "template tool" if TEMPLATE_TOOLS.include?(file)
    return "safe update" if SAFE_TO_MERGE.include?(file)

    "enhancement"
  end

  def review_changes_interactively(candidates)
    puts "\n📖 Reviewing Changes\n"

    selected_files = []

    candidates.each_with_index do |candidate, idx|
      puts "\n#{'=' * 60}"
      puts "File #{idx + 1}/#{candidates.length}: #{candidate[:path]}"
      puts "Status: #{candidate[:status].to_s.upcase}"
      puts "=" * 60

      template_file = File.join(TEMP_DIR, candidate[:path])

      if candidate[:status] == :new
        puts "\n📄 New file content (first 30 lines):"
        puts "-" * 60
        lines = File.readlines(candidate[:path])
        puts lines[0...30].join
        puts "-" * 60
      else
        # Show diff
        diff_output, status = Open3.capture2("diff -u #{template_file} #{candidate[:path]}")

        if status.success?
          puts "✓ Files are now identical"
        else
          puts "\n📊 Changes:"
          puts diff_output.split("\n")[0...40].join("\n")
        end
      end

      print "\nInclude this file in contribution? (y/n): "
      if gets.chomp.downcase == "y"
        selected_files << candidate
        puts "✓ Added to contribution list"
      else
        puts "⊘ Skipped"
      end
    end

    if selected_files.any?
      puts "\n#{selected_files.length} file(s) selected."
      print "Create contribution branch now? (y/n): "
      if gets.chomp.downcase == "y"
        create_contribution_branch(selected_files)
      else
        puts "Cancelled. Run this tool again when ready."
      end
    else
      puts "\nNo files selected for contribution."
    end
  end

  def create_contribution_branch(candidates)
    puts "\n🌿 Creating Contribution Branch\n"

    # Check if template remote exists
    _, _, status = Open3.capture3("git remote get-url template 2>&1")

    unless status.success?
      puts "⚙️  Setting up template remote first..."
      system("git remote add template #{TEMPLATE_REPO}")
      puts "✓ Added template remote"
    end

    # Fetch template
    puts "📥 Fetching template branches..."
    system("git fetch template")

    # Create a new branch based on template
    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    branch_name = "template-contribution-#{timestamp}"

    puts "\n🔀 Creating branch: #{branch_name}"
    system("git checkout -b #{branch_name} template/#{TEMPLATE_BRANCH}")

    unless $CHILD_STATUS.success?
      puts "❌ Failed to create branch from template"
      puts "   You may need to resolve conflicts manually"
      return
    end

    # Copy selected files
    puts "\n📋 Copying improved files..."

    candidates.each do |candidate|
      file_path = candidate[:path]

      # Ensure directory exists
      dir = File.dirname(file_path)
      FileUtils.mkdir_p(dir) unless Dir.exist?(dir) || dir == "."

      # Copy the file from main/master branch
      system("git checkout #{get_main_branch} -- #{file_path}")

      if $CHILD_STATUS.success?
        puts "   ✓ #{file_path}"
      else
        puts "   ⚠️  Failed to copy #{file_path}"
      end
    end

    # Show status
    puts "\n📊 Changes staged:"
    system("git status --short")

    puts "\n💡 Next steps:"
    puts "   1. Review the changes: git diff"
    puts "   2. Commit: git commit -m 'Your contribution message'"
    puts "   3. Push to your fork: git push origin #{branch_name}"
    puts "   4. Create a PR on GitHub to #{TEMPLATE_REPO}"
    puts
    puts "   Or return to your original branch: git checkout #{get_main_branch}"
    puts
  end

  def show_contribution_commands(candidates)
    puts "\n📋 Manual Contribution Commands\n"
    puts "=" * 60
    puts
    puts "# 1. Setup template remote (if not done)"
    puts "git remote add template #{TEMPLATE_REPO}"
    puts "git fetch template"
    puts
    puts "# 2. Create contribution branch from template"
    timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
    branch_name = "template-contribution-#{timestamp}"
    puts "git checkout -b #{branch_name} template/#{TEMPLATE_BRANCH}"
    puts
    puts "# 3. Cherry-pick your improvements"
    candidates.each do |candidate|
      puts "git checkout #{get_main_branch} -- #{candidate[:path]}"
    end
    puts
    puts "# 4. Review and commit"
    puts "git diff"
    puts "git add ."
    puts "git commit -m 'feat: improvements from #{@config['state_name'] || 'state site'}'"
    puts
    puts "# 5. Push to your fork and create PR"
    puts "git push origin #{branch_name}"
    puts
    puts "# 6. Return to your original branch"
    puts "git checkout #{get_main_branch}"
    puts
    puts "=" * 60
    puts
    puts "💡 Remember to:"
    puts "   • Fork #{TEMPLATE_REPO} on GitHub first"
    puts "   • Add your fork as a remote: git remote add origin YOUR_FORK_URL"
    puts "   • Remove any state-specific content before committing"
    puts "   • Write a clear description of your improvements in the PR"
    puts
  end

  def get_main_branch
    # Try to detect the main branch name
    stdout, _, status = Open3.capture3("git rev-parse --abbrev-ref HEAD")

    if status.success?
      current = stdout.strip
      return current unless current.start_with?("template-contribution")
    end

    # Check if main or master exists
    _, _, status = Open3.capture3("git show-ref --verify --quiet refs/heads/main")
    return "main" if status.success?

    _, _, status = Open3.capture3("git show-ref --verify --quiet refs/heads/master")
    return "master" if status.success?

    "main" # default
  end

  def cleanup
    FileUtils.rm_rf(TEMP_DIR)
  end
end

# Handle cleanup on interrupt
trap("INT") do
  puts "\n\n🧹 Cleaning up..."
  FileUtils.rm_rf(TemplateSync::TEMP_DIR)
  exit
end

# Run the sync tool
begin
  sync = TemplateSync.new
  sync.run
rescue StandardError => e
  puts "\n❌ Error: #{e.message}"
  puts e.backtrace if ENV["DEBUG"]
  FileUtils.rm_rf(TemplateSync::TEMP_DIR)
  exit 1
end

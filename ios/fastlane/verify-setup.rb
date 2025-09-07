#!/usr/bin/env ruby

# Fastlane Environment Verification Script
# This script helps verify your local environment matches CI requirements

puts "🔍 Fastlane Environment Verification"
puts "=" * 50

# Check if running in CI
is_ci = ENV["CI"] == "true"
puts "Environment: #{is_ci ? 'CI' : 'Local'}"
puts

# Required environment variables
required_always = [
  "FASTLANE_TEAM_ID",
  "MATCH_PASSWORD", 
  "MATCH_GIT_URL",
  "MATCH_CERTS_PAT"
]

puts "📋 Checking required environment variables..."
required_always.each do |var|
  if ENV[var] && !ENV[var].empty?
    puts "✅ #{var}: Set (#{ENV[var][0..10]}...)"
  else
    puts "❌ #{var}: Missing"
  end
end
puts

# API Key configuration
puts "🔑 Checking App Store Connect API Key configuration..."

# Method 1: JSON file (preferred for local)
json_path = ENV["FASTLANE_API_KEY_PATH"]
if json_path && File.exist?(json_path)
  puts "✅ FASTLANE_API_KEY_PATH: #{json_path} (exists)"
  
  # Try to parse JSON
  begin
    require 'json'
    json_data = JSON.parse(File.read(json_path))
    puts "   📄 JSON contains: key_id=#{json_data['key_id']}, issuer_id=#{json_data['issuer_id'][0..10]}..."
    puts "   📄 Key content: #{json_data['key'] ? 'Present' : 'Missing'}"
  rescue => e
    puts "   ❌ JSON parse error: #{e.message}"
  end
elsif json_path
  puts "❌ FASTLANE_API_KEY_PATH: #{json_path} (file not found)"
else
  puts "⚠️  FASTLANE_API_KEY_PATH: Not set"
end

# Method 2: Content (for CI)
if ENV["APP_STORE_CONNECT_API_KEY_CONTENT"] && !ENV["APP_STORE_CONNECT_API_KEY_CONTENT"].empty?
  puts "✅ APP_STORE_CONNECT_API_KEY_CONTENT: Present (#{ENV['APP_STORE_CONNECT_API_KEY_CONTENT'].length} chars)"
else
  puts "⚠️  APP_STORE_CONNECT_API_KEY_CONTENT: Not set"
end

# Method 3: Individual parameters
individual_vars = [
  "APP_STORE_CONNECT_API_KEY_ID",
  "APP_STORE_CONNECT_ISSUER_ID", 
  "APP_STORE_CONNECT_API_KEY_PATH"
]

puts "\n📝 Individual API key parameters:"
individual_vars.each do |var|
  if ENV[var] && !ENV[var].empty?
    if var == "APP_STORE_CONNECT_API_KEY_PATH"
      file_exists = File.exist?(ENV[var])
      puts "✅ #{var}: #{ENV[var]} (#{file_exists ? 'exists' : 'not found'})"
    else
      puts "✅ #{var}: #{ENV[var]}"
    end
  else
    puts "❌ #{var}: Missing"
  end
end

puts "\n🎯 Recommendations:"

# Check what setup the user has
has_json = json_path && File.exist?(json_path)
has_content = ENV["APP_STORE_CONNECT_API_KEY_CONTENT"] && !ENV["APP_STORE_CONNECT_API_KEY_CONTENT"].empty?
has_individual = individual_vars.all? { |var| ENV[var] && !ENV[var].empty? && (var != "APP_STORE_CONNECT_API_KEY_PATH" || File.exist?(ENV[var])) }

if has_json
  puts "✅ Perfect! You're using the recommended JSON file method."
  puts "   This will work great for local development."
elsif has_content && has_individual
  puts "✅ Good! You have CI-compatible setup with content and individual params."
elsif has_individual
  puts "⚠️  You're using individual parameters. Consider switching to JSON file method:"
  puts "   1. Create ~/.appstoreconnect/private/AuthKey_[KEY_ID].json"
  puts "   2. Add FASTLANE_API_KEY_PATH to ~/.zshrc"
elsif has_content
  puts "⚠️  You only have content method (CI-style). For local development, also set individual params."
else
  puts "❌ No valid API key configuration found!"
  puts "   Set up at least one method from CLAUDE.md"
end

puts "\n🚀 Next steps:"
puts "1. Local test: cd ios && fastlane beta"
puts "2. CI test: gh workflow run ios-deploy.yml --ref main"
puts "3. Monitor: gh run watch"
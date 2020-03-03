# frozen_string_literal: true

require 'json'
require 'dotenv/load'

PLUGIN_BACKEND_FOLDER = 'process'

class PluginBackend
  def initialize(path, versions, sign)
    @sign = sign
    @path = "#{path}/#{PLUGIN_BACKEND_FOLDER}"
    @versions = versions
    @state = false
    @sign_state = !@sign ? 'no need' : ''
  end

  def exist
    return false unless File.directory?(@path)

    true
  end

  def valid
    package_json_path = "#{@path}/package.json"
    unless File.exist?(package_json_path)
      puts "Fail to find #{package_json_path}"
      return false
    end
    @package_json_str = File.read(package_json_path)
    @package_json = JSON.parse(@package_json_str)
    unless @package_json.key?('scripts')
      puts "File #{package_json_path} doesn't have section \"scripts\""
      return false
    end
    unless @package_json['scripts'].key?('build')
      puts "Fail to find script \"build\" in section \"scripts\" of file #{package_json_path}"
      return false
    end
    true
  end

  def install
    Rake.cd @path do
      begin
        puts 'Install'
        Rake.sh 'npm install --prefere-offline'
        puts 'Build'
        Rake.sh 'npm run build'
        puts 'Remove node_modules'
        Rake.rm_r('./node_modules', force: true)
        puts 'Install in production'
        Rake.sh 'npm install --production --prefere-offline'
        puts 'Install electron and electron-rebuild'
        Rake.sh "npm install electron@#{@versions['electron']} electron-rebuild@#{@versions['electron-rebuild']} --prefere-offline"
        puts 'Rebuild'
        Rake.sh './node_modules/.bin/electron-rebuild'
        # sign_plugin_binary("#{PLUGINS_SANDBOX}/#{plugin}/process")
        puts 'Uninstall electron and electron-rebuild'
        Rake.sh 'npm uninstall electron electron-rebuild'
        @state = true
        return self.class.notarize(@path)
      rescue StandardError => e
        puts e.message
        @state = nil
        return false
      end
    end
  end

  def get_path
    @path
  end

  def get_state
    @state
  end

  def get_json
    @package_json
  end

  def get_sign_state
    @sign_state
  end

  def self.notarize(path)
    return true unless OS.mac?
    return true if ENV['SKIP_NOTARIZE'].eql?('true')

    if ENV.key?('SIGNING_ID')
      signing_id = ENV['SIGNING_ID']
    elsif ENV.key?('CHIPMUNK_DEVELOPER_ID')
      signing_id = ENV['CHIPMUNK_DEVELOPER_ID']
    else
      puts 'Cannot sign plugins because cannot find signing_id.'
      puts 'Define it in APPLEID (for production) or in CHIPMUNK_DEVELOPER_ID (for developing)'
      return false
    end
    puts "Detected next SIGNING_ID = #{signing_id}\nTry to sign code for: #{path}"
    if ENV.key?('KEYCHAIN_NAME')
      Rake.sh 'security unlock-keychain -p "$KEYCHAIN_PWD" "$KEYCHAIN_NAME"'
    end
    full_path = File.expand_path("../#{path}", File.dirname(__FILE__))
    codesign_execution = "codesign --force --options runtime --deep --sign \"#{signing_id}\" {} \\;"
    Rake.sh "find #{full_path} -name \"*.node\" -type f -exec #{codesign_execution}"
    true
  end
end

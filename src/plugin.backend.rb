require 'json'
require 'dotenv/load'

PLUGIN_BACKEND_FOLDER = "process"

class PluginBackend

    def initialize(path, versions, sign)
        @sign = sign  
        @path = "#{path}/#{PLUGIN_BACKEND_FOLDER}"
        @versions = versions
        @state = false
    end  
      
    def exist
        if !File.directory?(@path)
            return false
        end
        return true
    end

    def valid
        package_json_path = "#{@path}/package.json"
        if !File.exist?(package_json_path)
            puts "Fail to find #{package_json_path}"
            return false
        end
        @package_json_str = File.read(package_json_path)
        @package_json = JSON.parse(@package_json_str)
        if !@package_json.has_key?('scripts')
            puts "File #{package_json_path} doesn't have section \"scripts\""
            return false
        end
        if !@package_json['scripts'].has_key?('build')
            puts "Fail to find script \"build\" in section \"scripts\" of file #{package_json_path}"
            return false
        end
        return true
    end

    def install
        Rake.cd @path do
            begin  
                puts "Install"
                Rake.sh "npm install --prefere-offline"
                puts "Build"
                Rake.sh "npm run build"
                puts "Remove node_modules"
                Rake.rm_r("./node_modules", force: true)
                puts "Install in production"
                Rake.sh "npm install --production --prefere-offline"
                puts "Install electron and electron-rebuild"
                Rake.sh "npm install electron@#{@versions['electron']} electron-rebuild@#{@versions['electron-rebuild']} --prefere-offline"
                puts "Rebuild"
                Rake.sh "./node_modules/.bin/electron-rebuild"
                #sign_plugin_binary("#{PLUGINS_SANDBOX}/#{plugin}/process")
                puts "Uninstall electron and electron-rebuild"
                Rake.sh "npm uninstall electron electron-rebuild"
                @state = true
                if @sign == true
                  return self.class.notarize(@path)
                end
                return true
            rescue StandardError => e  
                puts e.message
                @state = nil
                return false
            end
        end
    end

    def get_path
        return @path
    end

    def get_state
        return @state
    end

    def self.notarize(path)
      if !OS.mac?
        return true
      end
      if ENV['SKIP_NOTARIZE'].eql?('true')
        return true
      end
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
        Rake.sh "security unlock-keychain -p \"$KEYCHAIN_PWD\" \"$KEYCHAIN_NAME\""
      end
      full_path = File.expand_path("../#{path}", File.dirname(__FILE__))
      codesign_execution = "codesign --force --options runtime --deep --sign \"#{signing_id}\" {} \\;"
      Rake.sh "find #{full_path} -name \"*.node\" -type f -exec #{codesign_execution}"
      return true
    end

end

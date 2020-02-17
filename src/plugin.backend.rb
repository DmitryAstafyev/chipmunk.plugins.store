require 'json'

PLUGIN_BACKEND_FOLDER = "process"

class PluginBackend

    def initialize(path, versions)  
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

end
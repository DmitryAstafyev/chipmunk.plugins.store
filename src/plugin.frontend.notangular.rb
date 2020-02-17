require 'json'

class PluginFrontendNotAngular

    def initialize(path, versions, package_json)
        @path = path
        @versions = versions
        @package_json = package_json
    end  
      
    def is
        if File.file?("#{@path}/#{PLUGIN_FRONTEND_ANGULAR_PACKAGE}")
            return false
        end
        return true
    end

    def valid
        if !@package_json.has_key?('name')
            puts "Field \"name\" not found in package.json"
            return false
        end
        return true
    end

    def install
        begin
            Rake.cd @path do
                puts "Install"
                Rake.sh "npm install --prefere-offline"
                puts "Build"
                Rake.sh "npm run build"
                puts "Remove node_modules"
                Rake.rm_r("./node_modules", force: true)
                puts "Install in production"
                Rake.sh "npm install --production --prefere-offline"
            end
            return true
        rescue StandardError => e  
            puts e.message  
            return false
        end
    end

end
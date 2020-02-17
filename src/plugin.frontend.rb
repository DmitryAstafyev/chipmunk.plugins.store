require 'json'
require './src/plugin.frontend.angular'

PLUGIN_FRONTEND_FOLDER = "render"

class PluginFrontend

    def initialize(path, versions)  
        @path = "#{path}/#{PLUGIN_FRONTEND_FOLDER}"
        @versions = versions
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
        return true
    end

    def install
        angular = PluginFrontendAngular.new(@path, @versions, self.class.get_package_json("#{@path}/package.json"))
        if angular.is()
            angular.install()
        end

    end

    def self.get_package_json(path) 
        package_json_str = File.read(path)
        package_json = JSON.parse(package_json_str)
        return package_json
    end

end
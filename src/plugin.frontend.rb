require 'json'
require './src/plugin.frontend.angular'
require './src/plugin.frontend.notangular'

PLUGIN_FRONTEND_FOLDER = "render"
PLUGIN_FRONTEND_ANGULAR_PACKAGE = "ng-package.json"
PLUGIN_FRONTEND_ANGULAR_BASE_REPO = "https://github.com/DmitryAstafyev/chipmunk.frontend.angular.git"
PLUGIN_FRONTEND_ANGULAR_BASE_NAME = "chipmunk.frontend.angular"
TMP_FOLDER = "./tmp"

class PluginFrontend

    def initialize(path, versions)  
        @path = "#{path}/#{PLUGIN_FRONTEND_FOLDER}"
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
        return true
    end

    def install
        angular = PluginFrontendAngular.new(@path, @versions, self.class.get_package_json("#{@path}/package.json"))
        if angular.is()
            if angular.install()
                @state = true
                @path = angular.get_dist_path()
            else
                @state = nil
            end
            return true
        end
        frontend = PluginFrontendNotAngular.new(@path, @versions, self.class.get_package_json("#{@path}/package.json"))
        if frontend.is()
            if frontend.install()
                @state = true
                @path = frontend.get_dist_path()
            else
                @state = nil
            end
            return true
        end
        return false
    end

    def get_path
        return @path
    end

    def get_state
        return @state
    end

    def self.get_package_json(path) 
        package_json_str = File.read(path)
        package_json = JSON.parse(package_json_str)
        return package_json
    end

end
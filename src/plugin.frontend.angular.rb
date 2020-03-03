require 'json'

class PluginFrontendAngular

    def initialize(path, versions, package_json)
        @path = path
        @versions = versions
        @package_json = package_json
    end  
      
    def is
        if !File.file?("#{@path}/#{PLUGIN_FRONTEND_ANGULAR_PACKAGE}")
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
        if !File.directory?(TMP_FOLDER)
            Rake.mkdir_p(TMP_FOLDER, verbose: true)
            puts "Creating temporary folder: #{TMP_FOLDER}"
        end
        if !File.directory?("#{TMP_FOLDER}/#{PLUGIN_FRONTEND_ANGULAR_BASE_NAME}")
            puts "Cloning angular base"
            Rake.cd TMP_FOLDER do
                Rake.sh "git clone #{PLUGIN_FRONTEND_ANGULAR_BASE_REPO}"
            end
            puts "Install angular base"
            Rake.cd "#{TMP_FOLDER}/#{PLUGIN_FRONTEND_ANGULAR_BASE_NAME}" do
                Rake.sh "npm install --prefere-offline"
            end
        end

        Rake.cd "#{TMP_FOLDER}/#{PLUGIN_FRONTEND_ANGULAR_BASE_NAME}" do
            begin
                puts "Generate library \"#{@package_json['name']}\""
                Rake.sh "./node_modules/.bin/ng generate library #{@package_json['name']}"
                puts "Remove default sources"
                Rake.rm_r("./projects/#{@package_json['name']}", force: true)
                puts "Create empty folder"
                Rake.mkdir("./projects/#{@package_json['name']}")
            rescue StandardError => e  
                puts e.message  
                return false
            end
        end
        begin
            puts "Copy plugin sources"
            Rake.cp_r("#{@path}/.", "#{TMP_FOLDER}/#{PLUGIN_FRONTEND_ANGULAR_BASE_NAME}/projects/#{@package_json['name']}", verbose: false)
        rescue StandardError => e  
            puts e.message  
            return false
        end
        Rake.cd "#{TMP_FOLDER}/#{PLUGIN_FRONTEND_ANGULAR_BASE_NAME}" do
            begin
                puts "Lint \"#{@package_json['name']}\""
                Rake.sh "./node_modules/.bin/ng lint #{@package_json['name']}"
                puts "Build \"#{@package_json['name']}\""
                Rake.sh "./node_modules/.bin/ng build #{@package_json['name']}"
                return true
            rescue StandardError => e  
                puts e.message  
                return false
            end
        end
    end

    def get_dist_path
        return "#{TMP_FOLDER}/#{PLUGIN_FRONTEND_ANGULAR_BASE_NAME}/dist/#{@package_json['name']}"
    end
    
end
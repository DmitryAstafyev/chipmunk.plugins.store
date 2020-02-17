require 'json'
require 'fileutils'
require './src/plugin.backend'
require './src/plugin.frontend'

class Plugin

    def initialize(name, repo, path, versions)  
        @name = name
        @repo = repo
        @path = path
        @versions = versions
    end

    def build
        self.class.clone(@name, @repo, @path)
        <<-backend
        backend = PluginBackend.new("#{@path}/#{@name}", @versions)
        if !backend.exist() 
            puts "Plugin \"#{@name}\" doesn't have backend"
        else
            if !backend.valid()
                puts "Fail to build plugin \"#{@name}\" because backend isn't valid"
                return nil
            end
            if backend.install()
                puts "Install backend of \"#{@name}\": SUCCESS"
            else
                puts "Install backend of \"#{@name}\": FAIL"
            end
        end
        backend
        
        frontend = PluginFrontend.new("#{@path}/#{@name}", @versions)
        if !frontend.exist()
            puts "Plugin \"#{@name}\" doesn't have frontend"
        else
            if !frontend.valid()
                puts "Fail to build plugin \"#{@name}\" because frontend isn't valid"
                return nil
            end
            if frontend.install()
                puts "Install frontend of \"#{@name}\": SUCCESS"
            else
                puts "Install frontend of \"#{@name}\": FAIL"
            end
        end
        return true
    end
      
    def self.clone(name, repo, path)
        if !File.directory?(path)
            Rake.mkdir_p(path, verbose: true)
            puts "Creating plugin's destination folder: #{path}"
        end
        if !File.directory?("#{path}/#{name}")
            Rake.cd path do
                puts "Cloning plugin #{name} into #{path}"
                Rake.sh "git clone #{repo}"
            end
        end
    end

end
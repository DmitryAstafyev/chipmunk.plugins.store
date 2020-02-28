require 'json'
require 'fileutils'
require './src/plugin.backend'
require './src/plugin.frontend'
require './src/tools'

class Plugin

    def initialize(info, path, versions, hash, releases)  
        @info = info
        @path = path
        @versions = versions
        @hash = hash
        @root = "#{@path}/#{@info['name']}"
        @releases = releases
    end

    def build
        target_file_name = self.class.get_name(@info['name'], @hash, @info['version'])
        if @releases.exist(target_file_name)
            puts "No need to build plugin #{@info['name']} because it's already exist"
            @releases.write()
            return true
        end
        self.class.clone(@info['name'], @info['repo'], @path)
        backend = PluginBackend.new(@root, @versions)
        if !backend.exist() 
            puts "Plugin \"#{@info['name']}\" doesn't have backend"
        else
            if !backend.valid()
                puts "Fail to build plugin \"#{@info['name']}\" because backend isn't valid"
                return nil
            end
            if backend.install()
                puts "Install backend of \"#{@info['name']}\": SUCCESS"
            else
                puts "Install backend of \"#{@info['name']}\": FAIL"
            end
        end
        frontend = PluginFrontend.new(@root, @versions)
        if !frontend.exist()
            puts "Plugin \"#{@info['name']}\" doesn't have frontend"
        else
            if !frontend.valid()
                puts "Fail to build plugin \"#{@info['name']}\" because frontend isn't valid"
                return nil
            end
            if frontend.install()
                puts "Install frontend of \"#{@info['name']}\": SUCCESS"
            else
                puts "Install frontend of \"#{@info['name']}\": FAIL"
            end
        end
        if backend.get_state() == nil || frontend.get_state() == nil 
            puts "Fail to build plugin \"#{@info['name']}\" because backend or frontend weren't installed correctly"
            return false
        end
        if backend.get_state() && !frontend.get_state()
            puts "Fail to build plugin \"#{@info['name']}\" because plugin has only backend"
            return false
        end
        if !File.directory?(PLUGIN_RELEASE_FOLDER)
            Rake.mkdir_p(PLUGIN_RELEASE_FOLDER, verbose: true)
            puts "Creating release folder: #{TMP_FOLDER}"
        end
        dest = "#{PLUGIN_RELEASE_FOLDER}/#{@info['name']}"
        if !File.directory?(dest)
            Rake.mkdir_p(dest, verbose: true)
            puts "Creating plugin release folder: #{dest}"
        end
        if backend.get_state()
            copy_dist(backend.get_path(), "#{dest}/process")
        end
        if frontend.get_state()
            copy_dist(frontend.get_path(), "#{dest}/render")
        end
        file_name = self.class.get_name(@info['name'], @hash, @info['version'])
        self.class.add_info(dest, @info['name'], @releases.get_url(file_name), file_name, @info['version'], @hash)
        compress("#{PLUGIN_RELEASE_FOLDER}/#{file_name}", PLUGIN_RELEASE_FOLDER, @info['name'])
        @releases.add(@info['name'], file_name, @info['version'])
        @releases.write()
        return true
    end

    def cleanup
        puts "Cleanup #{@info['name']}"
        Rake.rm_r(@root, force: true)
        Rake.rm_r("#{PLUGIN_RELEASE_FOLDER}/#{@info['name']}", force: true)
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

    def self.get_name(name, hash, version)
        return "#{name}@#{hash}-#{version}-#{get_nodejs_platform()}.tgz"
    end

    def self.add_info(dest, name, url, file_name, version, hash)
        info = {
            "name" => name,
            "file" => file_name,
            "version" => version,
            "hash" => hash,
            "url" => url
        }
        File.open("./#{dest}/info.json","w") do |f|
            f.write(info.to_json)
        end
    end

end
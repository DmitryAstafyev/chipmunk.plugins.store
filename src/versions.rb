require 'json'

VERSIONS_FILE = "./versions.json";

class Versions

    def initialize()
        if !File.file?(VERSIONS_FILE)
            raise "Fail to find versions file: #{VERSIONS_FILE}"
        end
        @versions_str = File.read("#{VERSIONS_FILE}")
        @versions = JSON.parse(@versions_str)
        puts "Next versions of frameworks/modules will be used:\n"
        puts "\telectron: #{@versions['electron']}\n"
        puts "\telectron-rebuild: #{@versions['electron-rebuild']}\n"
        puts "\tchipmunk.client.toolkit: #{@versions['chipmunk.client.toolkit']}\n"
        puts "\tchipmunk.plugin.ipc: #{@versions['chipmunk.plugin.ipc']}\n"
    end

    def get
        return @versions
    end

    def get_hash
        electron = @versions['electron'].split(".")
        rebuild = @versions['electron-rebuild'].split(".")
        toolkit = @versions['chipmunk.client.toolkit'].split(".")
        ipc = @versions['chipmunk.plugin.ipc'].split(".")
        return "#{electron[0]}#{rebuild[0]}#{toolkit[0]}#{ipc[0]}.#{electron[1]}#{rebuild[1]}#{toolkit[1]}#{ipc[1]}.#{electron[2]}#{rebuild[2]}#{toolkit[2]}#{ipc[2]}"
    end

end

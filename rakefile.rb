require './src/register'
require './src/plugin'
require './src/versions'
require './src/tools'
require './src/releases'
require "zlib"
require 'base64'

PLUGINS_DEST_FOLDER = "./plugins";
PLUGIN_RELEASE_FOLDER = "./releases"

task :build do
    success = true
    register = Register.new()
    versions = Versions.new()
    releases = Releases.new()
    puts "Current versions hash:\n\t#{versions.get_hash()}\n"
    loop do
        plugin_info = register.next()
        if plugin_info == nil
            break
        end
        plugin = Plugin.new(plugin_info, PLUGINS_DEST_FOLDER, versions.get(), versions.get_hash(), releases)
        if plugin.build()
            plugin.cleanup()
            puts "Plugin #{plugin_info['name']} is built SUCCESSFULLY"
        else
            success = false
            puts "Fail to build plugin #{plugin_info['name']}"
        end
    end
    if success
        cleanup()
    end
end


require './src/register'
require './src/plugin'
require './src/versions'
require './src/tools'
require './src/releases'

PLUGINS_DEST_FOLDER = "./plugins";
PLUGIN_RELEASE_FOLDER = "./releases"

task :build do
    success = true
    register = Register.new()
    versions = Versions.new()
    releases = Releases.new()
    loop do
        plugin_info = register.next()
        if plugin_info == nil
            break
        end
        plugin = Plugin.new(plugin_info['name'], plugin_info['repo'], PLUGINS_DEST_FOLDER, plugin_info['version'], versions.get(), versions.get_hash(), releases)
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

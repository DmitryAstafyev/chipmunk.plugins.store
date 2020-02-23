require './src/register'
require './src/plugin'
require './src/versions'
require './src/tools'
require './src/github'
PLUGINS_DEST_FOLDER = "./plugins";

task :build do
    success = true
    register = Register.new()
    versions = Versions.new()
    loop do
        plugin_info = register.next()
        if plugin_info == nil
            break
        end
        git = Github.new()
        assets = git.get_assets_names()
        plugin = Plugin.new(plugin_info['name'], plugin_info['repo'], PLUGINS_DEST_FOLDER, plugin_info['version'], versions.get(), versions.get_hash(), assets)
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

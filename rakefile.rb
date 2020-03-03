require './src/register'
require './src/plugin'
require './src/versions'
require './src/tools'
require './src/releases'

PLUGINS_DEST_FOLDER = "./plugins";
PLUGIN_RELEASE_FOLDER = "./releases"

task :build, [:target] do |t, args|
    success = true
    register = Register.new()
    versions = Versions.new()
    releases = Releases.new(register, versions)
    summary = ""
    puts "Current versions hash:\n\t#{versions.get_hash()}\n"
    loop do
        plugin_info = register.next()
        if plugin_info == nil
            break
        end
        if args.target == nil || (args.target != nil && plugin_info['name'] == args.target)
            plugin = Plugin.new(plugin_info, PLUGINS_DEST_FOLDER, versions, releases)
            if plugin.build()
                summary += plugin.get_summary()
                plugin.cleanup()
                puts "Plugin #{plugin_info['name']} is built SUCCESSFULLY"
            else
                success = false
                puts "Fail to build plugin #{plugin_info['name']}"
            end
        end
    end
    if success
        releases.normalize(register)
        releases.write()
        cleanup()
        puts summary
    end
end

task :test do
    register = Register.new()
    versions = Versions.new()
    releases = Releases.new(register, versions)
end
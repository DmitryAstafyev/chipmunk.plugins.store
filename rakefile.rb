require './src/register'
require './src/plugin'
require './src/versions'

PLUGINS_DEST_FOLDER = "./plugins";

task :clone do 
    register = Register.new()
    versions = Versions.new()
    loop do
        plugin_info = register.next()
        if plugin_info == nil
            break
        end
        plugin = Plugin.new(plugin_info['name'], plugin_info['repo'], PLUGINS_DEST_FOLDER, versions.get())
        plugin.build()
        puts plugin
    end

end

task :list do
    folders = Dir.entries(PLUGINS_DEST_FOLDER).select {|f| !File.directory? f}
    folders.each do |plugin_folder|
        puts "Checking: #{plugin_folder}"
        cd "#{PLUGINS_DEST_FOLDER}/#{plugin_folder}" do
            if !File.directory?(PLUGIN_FRONTEND_FOLDER) && !File.directory?(PLUGIN_BACKEND_FOLDER) 
                puts "Plugin \"#{plugin_folder}\" doesn't have not front-end, not back-end. Will be skipped"
            end
        end
    end
end
require 'json'
require './src/github'
require './src/tools'

RELEASES_FILE_NAME = "releases"
RELEASE_URL_PATTERN = "https://github.com/DmitryAstafyev/chipmunk.plugins.store/releases/download/${tag}/${file_name}"

class Releases

    def initialize(register, versions)
        @register = register
        @versions = versions
        @git = Github.new()
        @releases = self.class.validate(@git.get_releases_list(self.class.get_name()))
        @tag = @git.get_last_tag()
        puts "Last tag detected: #{@tag.name}"
    end

    def exist(file_name)
        result = false
        @releases.each { |release|
            if release['file'] == file_name
                result = true
            end
        }
        return result
    end

    def has_to_be_update(name, phash)
        last = nil
        @releases.each { |release|
            if release['name'] == name
                last = release
            end
        }
        if last == nil
            # No release found
            return true
        end
        basic = @register.get_by_name(name)
        if basic == nil
            # Plugin is excluded from basic register (plugins.json)
            return false
        end
        puts "last['version']:: #{last['version']}"
        puts "last['basic']:: #{last['basic']}"
        if Gem::Version.new(last['version']) != Gem::Version.new(last['basic'])
            # Version of plugin is dismatch
            return true
        end
        puts "last['phash']:: #{last['phash']}"
        puts "phash:: #{phash}"
        if Gem::Version.new(last['phash']) != Gem::Version.new(phash)
            # Plugin's hash is dismatch
            return true
        end
        # No need to update plugin
        return false
    end

    def add(name, file_name, version, dependencies)
        @releases = @releases.select do |release|
            release['name'] != name
        end
        @releases.push({
            "name" => name,
            "file" => file_name,
            "version" => version,
            "dependencies" => dependencies,
            "phash" => @versions.get_dep_hash(dependencies),
            "url" => RELEASE_URL_PATTERN.sub("${tag}", @tag.name).sub("${file_name}", file_name)
        });
    end

    def write
        if !File.directory?(PLUGIN_RELEASE_FOLDER)
            Rake.mkdir_p(PLUGIN_RELEASE_FOLDER, verbose: true)
            puts "Creating release folder: #{TMP_FOLDER}"
        end
        File.open("./#{PLUGIN_RELEASE_FOLDER}/#{self.class.get_name()}","w") do |f|
            f.write(@releases.to_json)
        end
    end

    def self.validate(releases)
        result = []
        releases.each { |release|
            if !release.has_key?('phash')
                release['phash'] = release['hash']
            end
            if !release.has_key?('dependencies')
                release['dependencies'] = {
                    "electron" => true,
                    "electron-rebuild" => true,
                    "chipmunk.client.toolkit" => true,
                    "chipmunk.plugin.ipc" => true,
                    "chipmunk-client-material" => true,
                    "angular-core" => true,
                    "angular-material" => true,
                    "force" => true,
                }
            end
            result.push(release)
        }
        return result
    end

    def normalize(register)
        result = []
        @releases.each { |release|
            plugin = register.get_by_name(release['name'])
            if plugin != nil
                result.push({
                    "name" => release['name'],
                    "file" => release['file'],
                    "version" => release['version'],
                    "url" => release['url'],
                    "dependencies" => release['dependencies'],
                    "phash" => release['phash'],
                    "hash" => @versions.get_hash(),
                    "default" => plugin['default'],
                    "signed" => plugin['has_to_be_signed'],
                })
            end
        }
        @releases = result
    end

    def get_url(file_name)
        return RELEASE_URL_PATTERN.sub("${tag}", @tag.name).sub("${file_name}", file_name)
    end

    def self.get_name()
        return "#{RELEASES_FILE_NAME}-#{get_nodejs_platform()}.json"
    end
    
end

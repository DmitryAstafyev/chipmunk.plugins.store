require 'octokit'
require 'open-uri'

REPO = "DmitryAstafyev/chipmunk.plugins.store"

class Github
    
    def initialize() 
        @client = Octokit::Client.new(:access_token => ENV['CHIPMUNK_PLUGINS_STORE_GITHUB_TOKEN'])
    end

    def get_releases_list(target)
        puts "Getting latest release"
        release = @client.latest_release(REPO, {})
        puts "Getting assets latest release"
        assets = @client.release_assets(release.url, {})
        release_file_asset = nil
        assets.each { |a|
            if a.name == target
                release_file_asset = a
            end
        }
        if release_file_asset == nil
            raise "Fail to find latest release file on repo #{REPO}"
        end
        puts "Reading releases file from \"#{release_file_asset.browser_download_url}\""
        release_file_asset_contents = open(release_file_asset.browser_download_url) { |f| f.read }
        releases = JSON.parse(release_file_asset_contents)
        return releases
    end

    def get_last_tag
        tags = @client.tags(REPO, {})
        if tags.length == 0
            raise "At least one tag should be defined on #{REPO}"
        end
        tags = tags.sort { |a,b| Gem::Version.new(b.name) <=> Gem::Version.new(a.name) }
        return tags[0]
    end

end
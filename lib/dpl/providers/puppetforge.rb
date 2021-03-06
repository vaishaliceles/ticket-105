module Dpl
  module Providers
    class Puppetforge < Provider
      register :puppetforge

      status :alpha

      full_name 'Puppet Forge'

      description sq(<<-str)
        tbd
      str

      gem 'puppet', '~> 6.26.0', require: 'puppet/face'
      gem 'puppet-blacksmith', '~> 4.1.2', require: 'puppet_blacksmith'

      env :puppetforge

      opt '--username NAME', 'Puppet Forge user name', required: true, alias: :user
      opt '--password PASS', 'Puppet Forge password', required: true, secret: true
      opt '--url URL', 'Puppet Forge URL to deploy to', default: 'https://forgeapi.puppetlabs.com/'

      msgs upload: 'Uploading to Puppet Forge %s/%s'

      def validate
        file.metadata
      end

      def deploy
        build
        info :upload, forge.username, file.name
        forge.push!(file.name)
      end

      def file
        @file ||= Blacksmith::Modulefile.new
      end

      def build
        Puppet::Face['module', :current].build('./')
      end

      def forge
        @forge ||= Blacksmith::Forge.new(username, password, url)
      end
    end
  end
end

require 'monitor'

module Unpoly
  module Guide
    class Repository
      include Logger

      PROMOTED_INTERFACE_NAMES = %w[
        up.link
        up.modal
        up.popup
        up.motion
        up.feedback
        up.syntax
        up.fragment
        up.proxy
        up.form
        up.tooltip
        up.history
        up.viewport
        up.event
        up.radio
        up.browser
        up.protocol
        up.element
        up.util
        up.log
      ].freeze

      def initialize(input_path)
        @path = input_path
        extend(MonitorMixin)
        reload
      end

      attr_reader :path

      def reload
        # puts "Reloading Repository!"
        synchronize do
          log "reload()"
          @interfaces = []
          @feature_index = nil
          @changelog = nil
          @promoted_interfaces = nil
          parse()
          self
        end
      end

      def changelog
        synchronize do
          @changelog ||= Changelog.new(@path)
        end
      end

      delegate :releases, :versions, :release_for_version, to: :changelog

      def github_url
        'https://github.com/unpoly/unpoly'
      end

      def promoted_interfaces
        synchronize do
          @promoted_interfaces ||= begin
            PROMOTED_INTERFACE_NAMES.map do |interface_name|
              interface_for_name(interface_name)
            end
          end
        end
      end

      def feature_index
        synchronize do
          @feature_index
        end
      end

      def all_features
        feature_index.all
      end

      def all_feature_guide_ids
        # We have multiple selectors called [up-close]
        feature_index.guide_ids
      end

      # Since we (e.g.) have multiple selectors called [up-close],
      # we display all of them on the same guide page.
      def features_for_guide_id(guide_id)
        feature_index.find_guide_id(guide_id)
      end

      def guide_id_exists?(guide_id)
        feature_index.guide_id_exists?(guide_id) || interface_with_guide_id_exists?(guide_id)
      end

      def version
        synchronize do
          require File.join(@path, 'lib/unpoly/rails/version')
          Unpoly::Rails::VERSION
        end
      end

      def git_version_tag
        "v#{version}"
      end

      def git_revision
        synchronize do
          revision = nil
          Dir.chdir @path do
            revision = `git rev-parse HEAD`
          end
          revision
        end
      end

      def interfaces
        synchronize do
          @interfaces
        end
      end

      def interface_for_name(name)
        interfaces.detect { |interface| interface.name == name } or raise UnknownClass, "No such Interface: #{name}"
      end

      def interface_for_guide_id(guide_id)
        interfaces.detect { |interface| interface.guide_id == guide_id } or raise UnknownClass, "No such Interface: #{guide_id}"
      end

      def interface_with_guide_id_exists?(guide_id)
        !!interfaces.detect { |interface| interface.guide_id == guide_id }
      end

      def inspect
        "#<#{self.class.name} interface_names=#{interfaces.collect(&:name)}>"
      end

      private

      def parse
        log "parse()"
        parser = Parser.new(self)
        log("Source paths", source_paths)
        source_paths.each do |source_path|
          parser.parse(source_path)
        end
        @feature_index = Feature::Index.new(interfaces.collect(&:features).flatten)
      end

      def source_paths
        File.directory?(@path) or raise "Input path not found: #{@path}"
        pattern = File.join(@path, "lib/**/*{.coffee,.coffee.erb}")
        log("Input pattern", pattern)
        Dir[pattern]
      end

    end
  end
end

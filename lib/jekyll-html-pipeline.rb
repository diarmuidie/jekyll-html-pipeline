module Jekyll
  module Converters
    class Markdown::HTMLPipeline
      def initialize(config)
        require 'html/pipeline'
        @config = config
        @errors = []
      end

      def filter_key(s)
        s.to_s.downcase.to_sym
      end

      def is_filter?(f)
        f < HTML::Pipeline::Filter
      rescue LoadError, ArgumentError
        false
      end

      def symbolize_keys(hash)
        hash.inject({}) { |result, (key, value)|
          new_key = case key
                    when String then key.to_sym
                    else key
                    end
          new_value = case value
                      when Hash then symbolize_keys(value)
                      else value
                      end
          result[new_key] = new_value
          result
        }
      end

      def ensure_default_opts
        @config['html_pipeline']['filters'] ||= ['markdownfilter']
        @config['html_pipeline']['context'] ||= {'gfm' => true}
        # symbolize strings as keys, which is what HTML::Pipeline wants
        @config['html_pipeline']['context'] = symbolize_keys(@config['html_pipeline']['context'])
      end

      def setup
        unless @setup
          ensure_default_opts

          filters = @config['html_pipeline']['filters'].map do |f|
            if is_filter?(f)
              f
            else
              key = filter_key(f)
              begin
                filter = HTML::Pipeline.constants.find { |c| c.downcase == key }
                # probably a custom filter
                if filter.nil?
                  Jekyll::Converters.const_get(f)
                else
                  HTML::Pipeline.const_get(filter)
                end
              rescue StandardError => e
                raise LoadError.new(e)
              end
            end
          end

          @parser = HTML::Pipeline.new(filters, @config['html_pipeline']['context'])
          @setup = true
        end
      end

      def convert(content)
        setup
        @parser.to_html(content)
      end
    end
  end
end

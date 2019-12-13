# frozen_string_literal: true

module GraphQL
  module Tracing

    # This class uses the AppopticsAPM SDK from the appoptics_apm gem to create
    # traces for GraphQL.
    #
    # There are 4 configurations available. They can be set in the
    # appoptics_apm config file or in code. Please see:
    # {https://docs.appoptics.com/kb/apm_tracing/ruby/configure}
    #
    #     AppOpticsAPM::Config[:graphql][:enabled] = true|false
    #     AppOpticsAPM::Config[:graphql][:transaction_name]  = true|false
    #     AppOpticsAPM::Config[:graphql][:sanitize_query] = true|false
    #     AppOpticsAPM::Config[:graphql][:remove_comments] = true|false
    class AppOpticsTracing < GraphQL::Tracing::PlatformTracing
      # These GraphQL events will show up as 'graphql.prep' spans
      PREP_KEYS = ['lex', 'parse', 'validate', 'analyze_query', 'analyze_multiplex']

      # During auto-instrumentation this version of AppOpticsTracing is compared
      # with the version provided in the appoptics_apm gem, so that the newer
      # version of the class can be used
      def self.version
        Gem::Version.new('1.0.0')
      end

      self.platform_keys = {
        'lex' => 'lex',
        'parse' => 'parse',
        'validate' => 'validate',
        'analyze_query' => 'analyze_query',
        'analyze_multiplex' => 'analyze_multiplex',
        'execute_multiplex' => 'execute_multiplex',
        'execute_query' => 'execute_query',
        'execute_query_lazy' => 'execute_query_lazy',
      }

      def platform_trace(platform_key, _key, data)
        return yield if !defined?(AppOpticsAPM) || gql_config[:enabled] == false

        kvs = metadata(data)
        kvs[:Key] = platform_key if PREP_KEYS.include?(platform_key)

        maybe_set_transaction_name(kvs[:InboundQuery]) if kvs[:InboundQuery]

        ::AppOpticsAPM::SDK.trace(span_name(platform_key), kvs) do
          kvs.clear
          result = yield
          puts result
          if result.is_a?(Array)
            result.each do |res|
              if res.is_a?(GraphQL::Query::Result) && res.to_h['errors']
                require 'byebug'
                byebug
                msg = res.to_h['errors'].map { |r| r['message']}.join(", ")
               AppOpticsAPM::API.log_exception(span_name(platform_key), msg)
              end
            end
          end
          result
        end
      end

      def platform_field_key(type, field)
        "graphql.#{type.name}.#{field.name}"
      end

      private

      def gql_config
        ::AppOpticsAPM::Config[:graphql] ||= {}
      end

      def maybe_set_transaction_name(query)
        if gql_config[:transaction_name] == false ||
          ::AppOpticsAPM::SDK.get_transaction_name
          return
        end

        split_query = query.strip.split(/\W+/, 3)
        name = "graphql.#{split_query[0..1].join'_'}".downcase
        ::AppOpticsAPM::SDK.set_transaction_name(name)
      end

      def span_name(key)
        return 'graphql.prep' if PREP_KEYS.include?(key)
        return key if key[/^graphql\./]
        "graphql.#{key}"
      end

      def metadata(data)
        data.keys
          .map do |key|
            value = data[key]
            case key
            when :context
              graphql_context(value)
            when :query
              graphql_query(value)
            when :query_string
              graphql_query_string(value)
            when :multiplex
              graphql_multiplex(value)
            else
              [key, value]
            end
          end
          .flatten
          .each_slice(2)
          .to_h
          .merge({ :Spec => 'graphql' })
      end

      def graphql_context(context)
        [ [:Path, context.path.join(".")],
          [:Errors, context.errors.join("\n")] ]
      end

      def graphql_query(query)
        query_string = query.query_string
        query_string = remove_comments(query_string) if gql_config[:remove_comments] != false
        query_string = sanitize(query_string) if gql_config[:sanitize_query] != false

        [ [:InboundQuery, query_string],
          [:Operation, query.selected_operation_name] ]
      end

      def graphql_query_string(query_string)
        query_string = remove_comments(query_string) if gql_config[:remove_comments] != false
        query_string = sanitize(query_string) if gql_config[:sanitize_query] != false
        [:InboundQuery, query_string]
      end

      def graphql_multiplex(data)
        names =
          data.queries
            .map(&:selected_operation_name)
            .compact
            .join(", ")

        [:Operations, names]
      end

      def sanitize(query)
        # remove arguments
        query.gsub(/"[^"]*"/, '"?"')              # strings
          .gsub(/-?[0-9]*\.?[0-9]+e?[0-9]*/, '?') # ints + floats
          .gsub(/\[[^\]]*\]/, '[?]')              # arrays
      end

      def remove_comments(query)
        query.gsub(/#[^\n\r]*/, '')
      end
    end

  end
end

# frozen_string_literal: true
require 'net/http'
require 'uri'
require 'json'

module ZapMessage
  module Api
    class Base
      ACCESS_TOKEN = ENV['WA_BUSINESS_ACCESS_TOKEN']

      def initialize
        @http = Net::HTTP.new(uri.host, uri.port)
        @http.use_ssl = true if uri.scheme == 'https'
      end

      private

      def uri
        @uri ||= base_url
      end

      def base_url
        raise NotImplementedError
      end

      def build_path(path, query_params = {})
        u = URI.parse([uri.to_s, path.to_s].join('/'))
        u.query = URI.encode_www_form(query_params) unless query_params.empty?

        u.to_s
      end

      def get(path, query_params = {})
        request = Net::HTTP::Get.new(build_path(path, query_params))

        status, response = process(request)

        yield status, response
      end

      def post(path, params = {})
        request = Net::HTTP::Post.new(build_path(path))
        request.body = params.to_json

        status, response = process(request)

        yield status, response
      end

      def process(request)
        request['Authorization'] = "Bearer #{access_token}"
        request['Content-Type'] = 'application/json'

        response = @http.request(request)

        if response.is_a?(Net::HTTPSuccess)
          [:success, response]
        else
          [:failure, response]
        end
      rescue StandardError => e
        message = [e.class.name, e.message].join(':')
        [:error, message]
      end

      def parse(type, response)
        yield if block_given?

        case type
        when :success, :failure
          [type, JSON.parse(response.body)]
        when :error
          Rails.logger.error(response)
        end
      end

      def access_token
        ACCESS_TOKEN
      end
    end
  end
end

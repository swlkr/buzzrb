# frozen_string_literal: true

module Beeswax
  class Resource
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def list(params = {})
      Paginator.new(client, resource_path, params)
    end

    def find(id)
      response = client.get("#{resource_path}/#{id}")
      response.data
    end

    def create(attributes = {})
      response = client.post(resource_path, attributes)
      response.data
    end

    def update(id, attributes = {})
      response = client.put("#{resource_path}/#{id}", attributes)
      response.data
    end

    def delete(id)
      response = client.delete("#{resource_path}/#{id}")
      response.data
    end

    private

    def resource_path
      raise NotImplementedError, "#{self.class} must implement #resource_path"
    end
  end
end

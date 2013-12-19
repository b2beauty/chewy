require 'chewy/query/criteria'
require 'chewy/query/loading'
require 'chewy/query/pagination'

module Chewy
  class Query
    include Enumerable
    include Loading
    include Pagination

    DEFAULT_OPTIONS = {}

    delegate :each, to: :_results
    alias_method :to_ary, :to_a

    attr_reader :index, :options, :criteria

    def initialize(index, options = {})
      @index, @options = index, DEFAULT_OPTIONS.merge(options)
      @criteria = Criteria.new
      reset
    end

    def ==(other)
      if other.is_a?(self.class)
        other.criteria == criteria
      else
        to_a == other
      end
    end

    def explain(value = nil)
      chain { criteria.update_search explain: (value.nil? ? true : value) }
    end

    def limit(value)
      chain { criteria.update_search size: Integer(value) }
    end

    def offset(value)
      chain { criteria.update_search from: Integer(value) }
    end

    def facets(params)
      chain { criteria.update_facets params }
    end

    def query(params)
      chain { criteria.update_query params }
    end

    def filter(params)
      chain { criteria.update_filters params }
    end

    def order(*params)
      chain { criteria.update_sort params }
    end

    def reorder(*params)
      chain { criteria.update_sort params, purge: true }
    end

    def only(*params)
      chain { criteria.update_fields params }
    end

  protected

    def initialize_clone(other)
      @criteria = other.criteria.clone
      reset
    end

  private

    def chain &block
      clone.tap { |q| q.instance_eval(&block) }
    end

    def reset
      @_response, @_results = nil
    end

    def types
      @types ||= Array.wrap(options[:type] || options[:types])
    end

    def _filters
      if criteria.filters.many?
        {and: criteria.filters}
      else
        criteria.filters.first
      end
    end

    def _request_query
      if criteria.filters?
        {query: {
          filtered: {
            query: criteria.query? ? criteria.query : {match_all: {}},
            filter: _filters
          }
        }}
      elsif criteria.query?
        {query: criteria.query}
      else
        {}
      end
    end

    def _request_body
      body = _request_query
      body = body.merge!(facets: criteria.facets) if criteria.facets?
      body = body.merge!(sort: criteria.sort) if criteria.sort?
      body = body.merge!(fields: criteria.fields) if criteria.fields?
      {body: body}
    end

    def _request_target
      {index: index.index_name, type: types}
    end

    def _request
      [criteria.search, _request_target, _request_body].inject(:merge)
    end

    def _response
      @_response ||= index.client.search(_request)
    end

    def _results
      @_results ||= _response['hits']['hits'].map do |hit|
        attributes = hit['_source'] || hit['fields'] || {}
        attributes.reverse_merge!(id: hit['_id']).merge!(_score: hit['_score'])
        attributes.merge!(_explain: hit['_explanation']) if hit['_explanation']
        index.type_hash[hit['_type']].new attributes
      end
    end
  end
end
require 'json'
require 'rest-client'

module ElasticSearch

class Index
	def initialize handle, name, configurations
		@handle = handle
		@name = name
		@configurations = configurations
	end

	def << document
		@handle.__send__ :index_document, self, document
	end

	def search query
		@handle.__send__ :search_document, query, self
	end

	def match_atts atts, query
		@handle.__send__ :match_document_atts, atts, query, self
	end

	def settings settings_query
		@handle.__send__ :index_settings, self, settings_query
	end

	def explain args
		@handle.__send__ :explain_document, args[:word], args[:document_id], args[:field], self
	end

	attr_reader :name
end

class Handle
	def initialize options={:host => '127.0.0.1', :port => '9200'}
		@root = "http://#{options[:host]}:#{options[:port]}"
		@indices = {}
	end

	def retrieve_index name, configurations=nil
		if @indices[name].nil?
			index = Index.new self, name, configurations
			@indices[name] = index
		end
		@indices[name]
	end

	def search query
		search_document query
	end

	def match_atts atts, query
		match_document_atts atts, query
	end

	private def index_document index, document, type='document'
		id = ''
		if document.respond_to? :id
			id = "/#{document.id}"
		end

		RestClient::post "#{@root}/#{index.name}#{'/'+type}#{id}",
			JSON(document.to_hash),
			:content_type => :json
	end

	private def search_document query, index=nil, type='document'
		if query.is_a? Hash
			query_ = JSON(query)
		else
			query_ = JSON(query.to_hash)
		end

		if index.nil?
			type = nil
			index_name = ''
		else
			index_name = '/' + index.name
		end

		if type.nil?
			type_name = ''
		else
			type_name = '/' + type
		end

		JSON.parse(RestClient::post(
			"#{@root}#{index_name}#{type_name}/_search",
			query_,
			:content_type => :json
		))
	end

	private def explain_document word, document_id, field, index, type='document'
		JSON.parse(RestClient::get(
			"#{@root}/#{index.name}/#{type}/#{document_id}/_explain?q=#{field}:#{word}"
		))
	end

	private def match_document_atts atts, query, index=nil, type='document'
		found_lists = []
		
		if atts.is_a? Array
			atts.each { found_lists << [] }
		else
			atts = [atts]
		end
		
		search_document({"query" => {"match" => {"content" => query}}}, index, type)['hits']['hits'].each do |document|
			atts.each_with_index do |att, list_index|
				found_lists[list_index] << document['_source'][att.to_s]
			end
		end

		found_lists
	end

	private def index_settings index, settings_query
		RestClient::put "#{@root}/#{index.name}",
			settings_query,
			:content_type => :json
	end
end

end
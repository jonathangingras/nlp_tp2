#!/usr/bin/env ruby
require './deps'

require './information_retrieval'
require './elastic_search'

module JSON
	def self.readfile filename
		self.parse(File.new(filename).read)
	end
end

@elastic_search = ElasticSearch::Handle.new

def populate_index index_name, index_settings
	index = @elastic_search.retrieve_index index_name, index_settings

	puts "indexing #{index_name}..."
	InformationRetrieval::DocumentParser.new('corpus.txt').parse do |document|
		index << document
	end
	puts "indexed #{index_name}"
end

settings = [
	:normal,
	:no_stemming,
	:no_stop_words,
	:no_scoring,
	:kstem,
	:porter_stem,
	:no_norm,
]

settings.each do |setting|	
	populate_index setting.to_s, JSON.readfile("index_settings/#{setting.to_s}.json")
end
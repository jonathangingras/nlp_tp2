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

populate_index 'normal', JSON.readfile("index_settings/normal.json")
populate_index 'no_stemming', JSON.readfile("index_settings/no_stemming.json")
populate_index 'no_stop_words', JSON.readfile("index_settings/no_stop_words.json")
populate_index 'no_scoring', JSON.readfile("index_settings/no_scoring.json")
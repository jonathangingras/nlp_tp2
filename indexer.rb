require './information_retrieval'
require './elastic_search'

elastic_search = ElasticSearch::Handle.new

#index = elastic_search.retrieve_index 'documents'
#InformationRetrieval::DocumentParser.new('corpus.txt').parse do |document|
#	index << document
#end

nostem_index = elastic_search.retrieve_index 'withstem'

InformationRetrieval::DocumentParser.new('corpus.txt').parse do |document|
	nostem_index << document
end


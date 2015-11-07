require 'json'
require './information_retrieval'
require './elastic_search'

class Array
	def mean
		sum = 0
		each {|e| sum += e}
		sum / length.to_f
	end
end

class Estimation
	def initialize precision, recall, alpha=0.5
		@precision = precision
		@recall = recall
		@alpha = alpha
	end

	def fmeasure
		( @alpha * (1.0 / @precision) + ((1 - @alpha) * (1.0 / @recall)) ) ** -1
	end

	def to_s
		"precision: #{@precision}, recall: #{@recall}, F-measure: #{fmeasure}"
	end
end

class PrecisionRecallQueryer
	def initialize
		@elastic_search = ElasticSearch::Handle.new
		@pertinences = InformationRetrieval::PertinenceTable.new 'requests.txt', 'pertinence.txt'
	end

	def query_index index_name
		index = @elastic_search.retrieve_index index_name
		precisions, recalls = [], []
		
		@pertinences.requests.each do |id, request|
			expected_keys = @pertinences[id].pertinent_keys
			returned_keys, returned_ids = index.match_atts [:key, :id], request.string_request

			precisions << (returned_keys & expected_keys).length.to_f / returned_keys.length.to_f
			recalls << (returned_keys & expected_keys).length.to_f / expected_keys.length.to_f

			scores = []
			request.per_word do |word|
				returned_ids.each do |doc_id|
					scores << ["'#{word}' in doc_id '#{doc_id}'", index.explain(word: word, document_id: doc_id, field: 'content')['explanation']['details'][0]['value']]
				end
			end

			puts scores.to_s
		end
		
		return precisions, recalls
	end
end


queryer = PrecisionRecallQueryer.new
p, r = queryer.query_index 'withstem'

puts " #{Estimation.new p.mean, r.mean}"
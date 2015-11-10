require './estimation'

module InformationRetrieval
module PrecisionRecall

class Explaination
	def initialize word, doc_id, explaination
		@word = word
		@doc_id = doc_id
		@explaination = explaination
	end

	def weight
		@explaination['explanation']['details'][0]['value']
	end

	def to_s
		"'#{@word}' in doc_id '#{@doc_id}': #{weight}"
	end
end

class Estimator
	def initialize index_name, elastic_search, pertinences
		@elastic_search = elastic_search
		@pertinences = pertinences
		@precisions = []
		@recalls = []
		@index_name = index_name
	end

	def query_index &block
		index = @elastic_search.retrieve_index @index_name
		
		@pertinences.each_request do |request|
			expected_keys = request.pertinent_keys
			returned_keys, = index.match_atts :key, request.string_request

			precision = (returned_keys & expected_keys).length.to_f / returned_keys.length.to_f
			recall = (returned_keys & expected_keys).length.to_f / expected_keys.length.to_f
			@precisions << precision
			@recalls << recall

			unless block.nil? then block.call request, precision, recall end
		end

		nil
	end

	def explain request_id
		index = @elastic_search.retrieve_index @index_name
		scores = []
		returned_ids, = index.match_atts :id, @pertinences[request_id].string_request
		@pertinences[request_id].per_word do |word|
			returned_ids.each do |doc_id|
				scores << Explaination.new(word, doc_id, index.explain(word: word, document_id: doc_id, field: 'content'))
			end
		end
		scores
	end

	def means
		if @precisions.empty? or @recalls.empty?
			query_index
		end
		"#{@index_name} means: #{Estimation.new @precisions.mean, @recalls.mean}"
	end

	attr_reader :index_name, :pertinences, :precisions, :recalls
end

end
end
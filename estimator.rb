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

class RequestResult
	def initialize args
		@expected = args[:expected]
		@returned = args[:returned]
		@request = args[:request]
	end

	def recall
		(@returned & @expected).length.to_f / @expected.length.to_f
	end

	def precision
		(@returned & @expected).length.to_f / @returned.length.to_f
	end

	def rank
		index = @returned.find_index @expected[0]
		unless index.nil?
			return index + 1
		end
		0
	end

	def reciprocal_rank
		rank_ = rank
		unless rank_ == 0
			return rank ** -1
		end
		0
	end

	attr_reader :request
end

class Estimator
	def initialize index_name, elastic_search, pertinences
		@elastic_search = elastic_search
		@pertinences = pertinences
		@index_name = index_name
		@results = []
		@cheating = false
	end

	def cheat
		@cheating = true
	end

	def reset
		@results = []
	end

	def query_index size=50
		index = @elastic_search.retrieve_index @index_name
		
		@pertinences.each_request do |request|
			size = request.pertinent_keys.length if @cheating

			expected_keys = request.pertinent_keys
			returned_keys, = index.match_atts :key, request.string_request, size

			@results << RequestResult.new(
				request: request,
				expected: expected_keys, 
				returned: returned_keys
			)
		end

		nil
	end

	def recalls
		query_if_needed
		recalls = []
		@results.each do |result|
			recalls << result.recall
		end
		recalls
	end

	def precisions
		query_if_needed
		precisions = []
		@results.each do |result|
			precisions << result.precision
		end
		precisions
	end

	def explain request_id
		query_if_needed
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
		query_if_needed
		"index: #{@index_name}, #{Estimation.new precisions.mean, recalls.mean}, MRR: #{mean_reciprocal_rank}"
	end

	def each_result &block
		query_if_needed
		@results.each { |result| block.call result }
	end

	def query_if_needed
		if @results.empty?
			query_index
		end
	end

	def mean_reciprocal_rank
		query_if_needed
		ranks = []
		each_result do |result|
			ranks << result.reciprocal_rank
		end
		ranks.mean
	end

	attr_reader :index_name, :pertinences
	private :query_if_needed
end

end
end
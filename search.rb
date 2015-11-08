require './information_retrieval'
require './elastic_search'

require 'gruff'

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

class Hash
	def brute_push! element
		self[length] = element
	end
end

class PrecisionRecallQueryer
	def initialize index_name, elastic_search, pertinences
		@elastic_search = elastic_search
		@pertinences = pertinences
		@precisions = []
		@recalls = []
		@index_name = index_name
		query_index
	end

	def query_index
		index = @elastic_search.retrieve_index @index_name
		
		@pertinences.each_request do |request|
			expected_keys = request.pertinent_keys
			returned_keys, returned_ids = index.match_atts [:key, :id], request.string_request

			@precisions << (returned_keys & expected_keys).length.to_f / returned_keys.length.to_f
			@recalls << (returned_keys & expected_keys).length.to_f / expected_keys.length.to_f

			#scores = []
			#request.per_word do |word|
			#	returned_ids.each do |doc_id|
			#		scores << ["'#{word}' in doc_id '#{doc_id}'", index.explain(word: word, document_id: doc_id, field: 'content')['explanation']['details'][0]['value']]
			#	end
			#end
		end

		nil
	end

	def recall_graph
		g = Gruff::Bar.new
		g.theme_pastel
		g.title = "Recall of #{@index_name}"
		g.labels = x_labels
		g.data index_name.to_sym, @recalls
		
		g
	end

	def precision_graph
		g = Gruff::Bar.new
		g.theme_pastel
		g.title = "Precision of #{@index_name}"
		g.labels = x_labels
		g.data index_name.to_sym, @precisions

		g
	end

	private def x_labels
		x_s = {}
		c = 0
		@pertinences.each_request do |request|
			if c == 1 then c = 0; x_s.brute_push! " "; next end
			x_s.brute_push! request.id.to_s
			c = 1
		end
		x_s
	end

	def means
		"#{@index_name}: #{Estimation.new @precisions.mean, @recalls.mean}"
	end

	attr_reader :index_name
end

elastic_search = ElasticSearch::Handle.new
pertinences = InformationRetrieval::PertinenceTable.new 'requests.txt', 'pertinence.txt'

normal = PrecisionRecallQueryer.new 'normal', elastic_search, pertinences
no_stemming = PrecisionRecallQueryer.new 'no_stemming', elastic_search, pertinences
no_stop_words = PrecisionRecallQueryer.new 'no_stop_words', elastic_search, pertinences
no_scoring = PrecisionRecallQueryer.new 'no_scoring', elastic_search, pertinences

[normal, no_stemming, no_stop_words, no_scoring].each do |queryer|
	puts queryer.means
	queryer.precision_graph.write "pr_#{queryer.index_name}.png"
	queryer.recall_graph.write "r_#{queryer.index_name}.png"
end
module InformationRetrieval
module PrecisionRecall

class ::Array
	def mean
		sum = 0
		each {|e| sum += e}
		sum / length.to_f
	end
end

class ::Hash
	def brute_push! element
		self[length] = element
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

end
end
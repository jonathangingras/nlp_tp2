require 'gruff'
require 'nyaplot'

module InformationRetrieval
module PrecisionRecall

class GraphicWriter
	def initialize estimator
		@estimator = estimator
	end

	def recall_graph
		query_if_needed

		g = Gruff::Bar.new
		g.theme_pastel
		g.title = "Recall of #{@estimator.index_name}"
		g.labels = x_labels
		g.data @estimator.index_name.to_sym, @estimator.recalls
		
		g
	end

	def precision_graph
		query_if_needed

		g = Gruff::Bar.new
		g.theme_pastel
		g.title = "Precision of #{@estimator.index_name}"
		g.labels = x_labels
		g.data @estimator.index_name.to_sym, @estimator.precisions

		g
	end

	def precision_vs_recall
		plot = Nyaplot::Plot.new
		plot.x_label "recall"
		plot.y_label "precision"
		data = []
		@estimator.recalls.each_with_index do |d, i|
			data << [d, @estimator.precisions[i]]
		end
		data.sort!
		x, y = [], []
		data.each do |d|
			x << d[0]
			y << d[1]
		end
		plot.add :line, x, y
		plot
	end

	def recall_vs_precision
		plot = Nyaplot::Plot.new
		plot.x_label "precision"
		plot.y_label "recall"
		data = []
		@estimator.precisions.each_with_index do |d, i|
			data << [d, @estimator.recalls[i]]
		end
		data.sort!
		x, y = [], []
		data.each do |d|
			x << d[0]
			y << d[1]
		end
		plot.add :line, x, y
		plot
	end

	def x_labels
		x_s = {}
		c = 0
		@estimator.pertinences.each_request do |request|
			if c == 1 then c = 0; x_s.brute_push! " "; next end
			x_s.brute_push! request.id.to_s
			c = 1
		end
		x_s
	end

	def query_if_needed
		if @estimator.precisions.empty? or @estimator.recalls.empty?
			@estimator.query_index
		end
	end

	private :x_labels, :query_if_needed
end

end
end
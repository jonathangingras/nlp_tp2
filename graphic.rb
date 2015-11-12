require 'nyaplot'

module InformationRetrieval
module PrecisionRecall

class ::Nyaplot::Plot
	alias :dump :export_html
end

class GraphicWriter
	def initialize estimator
		@estimator = estimator
	end

	def recall_graph
		plot = Nyaplot::Plot.new
		plot.x_label "request ID"
		plot.y_label "recall"
		plot.add :bar, x_labels, @estimator.recalls
		plot.configure do
  		width 1000
		end
		plot
	end

	def precision_graph
		plot = Nyaplot::Plot.new
		plot.x_label "request ID"
		plot.y_label "precisions"
		plot.add :bar, x_labels, @estimator.precisions
		plot.configure do
  		width 1000
		end
		plot
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
		xs = (1..@estimator.precisions.length).to_a
		xs.each_with_index { |x, i| xs[i] = x.to_s }
	end

	private :x_labels
end

end
end
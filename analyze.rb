#!/usr/bin/env ruby
require './deps'

require 'optparse'
require './elastic_search'
require './information_retrieval'
require './estimator'
require './graphic'

include InformationRetrieval

@elastic_search = ElasticSearch::Handle.new
@pertinences = PertinenceTable.new 'requests.txt', 'pertinence.txt'

def estimator_for symbol
	PrecisionRecall::Estimator.new symbol.to_s, @elastic_search, @pertinences
end

def print_verbose_means estimator
	estimator.query_index do |request, precision, recall|
		puts "#{estimator.index_name}: '#{request.string_request}': precision:#{precision}, recall:#{recall}"
	end
end

def write_graphics estimator
	begin Dir.mkdir 'graphics'
	rescue
	end
	graphic_writer = PrecisionRecall::GraphicWriter.new estimator
	graphic_writer.precision_graph.write "graphics/pr_#{estimator.index_name}.html"
	graphic_writer.recall_graph.write "graphics/r_#{estimator.index_name}.html"
	graphic_writer.precision_vs_recall.export_html "graphics/pr_vs_r_#{estimator.index_name}.html"
	graphic_writer.recall_vs_precision.export_html "graphics/r_vs_pr_#{estimator.index_name}.html"
end

options = {graphics: false, means: false, verbose: false}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on('-g', '--graphics', 'Print Graphics') { options[:graphics] = true }
  opts.on('-m', '--means', 'Print Means') { options[:means] = true }
  opts.on('-v', '--verbose', 'Source port') { options[:verbose] = true }
  opts.on('-w REQUEST_ID', '--weigth REQUEST_ID', 'Detailed Weigth of each word in request #id') { |r| options[:request_id] = r }

end.parse!

estimators = [
	:normal, 
	:no_stemming, 
	:no_stop_words, 
	:no_scoring,
	:kstem,
	:porter_stem,
	:no_norm
]

estimators.each do |estimator_symbol|
	estimator = estimator_for estimator_symbol
	if options[:graphics] then write_graphics estimator end
	if options[:verbose] then print_verbose_means estimator end
	if options[:means] then puts estimator.means end
	unless options[:request_id].nil? then puts estimator.explain options[:request_id].to_i end
end
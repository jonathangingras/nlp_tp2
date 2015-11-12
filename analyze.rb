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
	estimator.each_result do |result|
		puts "#{estimator.index_name}: ID:DD15-#{result.request.id} text: '#{result.request.string_request}', precision:#{result.precision}, recall:#{result.recall}, RR:#{result.reciprocal_rank}"
	end
end

def write_graphics estimator
	begin Dir.mkdir 'graphics'
	rescue
	end
	graphic_writer = PrecisionRecall::GraphicWriter.new estimator
	graphic_writer.precision_graph.dump "graphics/pr_#{estimator.index_name}.html"
	graphic_writer.recall_graph.dump "graphics/r_#{estimator.index_name}.html"
	graphic_writer.precision_vs_recall.dump "graphics/pr_vs_r_#{estimator.index_name}.html"
	graphic_writer.recall_vs_precision.dump "graphics/r_vs_pr_#{estimator.index_name}.html"
end

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: #{__FILE__} [options]"

  opts.on('-g', '--graphics', 'Print HTML Graphics in graphics/') { options[:graphics] = true }
  opts.on('-m', '--means', 'Print means of each index (precision, recall, F-measure, MRR)') { options[:means] = true }
  opts.on('-v', '--verbose', 'Print each request with its weigth for each document') { options[:verbose] = true }
  opts.on('-w REQUEST_ID', '--weigth REQUEST_ID', 'Detailed Weigth of each word in request id REQUEST_ID') { |r| options[:request_id] = r }
  opts.on('-c', '--cheat', 'Cheat when querying index (tell elasticsearch how much pertinent documents it shoud return instead of 50)') { options[:cheat] = true }

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
	unless options[:cheat].nil? then estimator.cheat end
	unless options[:graphics].nil? then write_graphics estimator end
	unless options[:verbose].nil? then print_verbose_means estimator end
	unless options[:means].nil? then puts estimator.means end
	unless options[:request_id].nil? then puts estimator.explain options[:request_id].to_i end
end
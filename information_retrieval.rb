module InformationRetrieval

class Document
	def initialize id, key, title, content
		@id = id
		@key = key
		@title = title
		@content = content
	end

	def to_hash
		{:id => @id, :key => @key, :title => @title, :content => @content}
	end

	attr_reader :id, :key, :title, :content
end

class DocumentParser
	def initialize filename
		@filename = filename
	end

	def parse &block
		position = 0
		id = ''
		key = ''
		title = ''
		content = ''
		
		File.new(@filename).readlines.each do |line|
			position += 1

			case position
			when 1
				id = line.split[1]
			when 2
				if line.chomp("\n") != '.DocKey' then raise "#{line.chomp("\n")}" end
			when 3
				key = line.chomp! "\n"
			when 4
				if line.chomp("\n") != '.DocTitle' then raise "#{line.chomp("\n")}" end
			when 5
				title = line.chomp! "\n"
			when 6
				if line.chomp("\n") != '.DocContent' then raise "#{line.chomp("\n")}" end
			when 7
				content = line.chomp! "\n"
				position = 0
				block.call Document.new(id, key, title, content)
			end
		end
	end
end

class Request
	def initialize id, string_request
		@id = id
		@string_request = string_request
		@pertinent_keys = []
	end

	private def add_pertinent_key key
		@pertinent_keys << key
	end

	def per_word &block
		@string_request.split(' ').each { |word| if word == '-' then next end; block.call word }
	end

	def to_s
		"#{super.to_s.chomp '>'} id: #{@id}, string_request: '#{@string_request}'>"
	end

	attr_reader :id, :string_request, :pertinent_keys
end

class RequestParser
	def initialize filename
		@filename = filename
	end

	def parse &block
		File.new(@filename).readlines.each do |line|
			words = line.split(' ')
			block.call Request.new(words[0], words[1..-1].join(' '))
		end
	end
end

class PertinenceParser
	def initialize filename
		@filename = filename
	end

	def parse &block
		File.new(@filename).readlines.each do |entry|
			words = entry.split(' ')			
			block.call words[0], words[1]
		end
	end
end

class PertinenceTable
	def initialize requests_filename, pertinences_filename
		@request_parser = RequestParser.new requests_filename
		@pertinence_parser = PertinenceParser.new pertinences_filename
		@requests = {}
		
		associate
	end

	private def associate
		@request_parser.parse do |request|
			@requests[request.id] = request
		end
	
		@pertinence_parser.parse do |request_id, key|
			@requests[request_id].__send__ :add_pertinent_key, key
		end
	
		nil
	end

	def [] request
		id = request
		if request.is_a? Request
			id = request.id
		end

		@requests[id]
	end

	def to_s
		str = super.to_s.chomp!('>')
		str << " : {"
		@requests.each { |id, request| str << "#{id} => #{request.pertinent_keys}, " }
		str.chomp! ", " 
		str << "}>"
	end

	attr_reader :requests
end

end
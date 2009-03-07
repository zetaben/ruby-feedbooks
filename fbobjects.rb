require 'open-uri'
require 'hpricot'
module FeedBooks

	NAME        = 'Ruby/FeedBooks'
	VERSION     = '0.1'
	USER_AGENT  = "%s %s" % [NAME, VERSION]


	class FBobject
		def self.from_xml(txt)
			doc=Hpricot.XML(txt)
			book=doc/"/*"
			return from_xml_elm(book)
		end
		protected 
		def get_attr(name=nil)
			name=self.class.to_s.downcase.split(':').last if name.nil?
			book=nil
			raise Exception("No Id given") if @id.nil? || @id < 1
			doc = Hpricot.XML(open("http://www.feedbooks.com/"+name+"s/search.xml?query=id:#{@id}"))
			book=doc/("//"+name+"[@id='#{@id}']")
			return FBobject::from_xml_elm(book)
		end


		def self.from_xml_elm(book)
			h=Hash.new
			(book.at('.').containers).each do |el|
				 tmp=el.containers
				name=el.name
				name=name.split(':').last if name.include?(':')
				if tmp.empty?
					tmp=el.inner_text
					tmp={"id"=>el.attributes['id'].to_i,name=> tmp} unless el.attributes['id'].nil?
					if  h[name].nil?
						h[name]=tmp
					else
						h[name]=[h[name], tmp].flatten
					end
				else
					h[name]=Hash.new
					tmp.each do |elc|
						h[name][elc.name.split(':').last]=elc.inner_text
					end
				end
			end
			return h
		end

		def self.iterate(url)
			url+='?' if url.index('?').nil?
			name=self.to_s.downcase.split(':').last
			page=1
			maxpages=0
			begin
				doc=Hpricot.XML(open("http://www.feedbooks.com#{url}&page=#{page}"))
				maxpages=doc.root.attributes['total'].to_i
				book=doc.search("//"+name) do |b|
					yield(b)
				end
				page+=1
			end while page<=maxpages
		end
	end

	class Book < FBobject
		attr_reader :id
		def initialize(id=nil)
			@id=id
		end

		def title
			get_attr if @title==nil	
			@title
		end 

		def authors
			get_attr if @author==nil	
			@author
		end 

		def date
			get_attr if @date==nil	
			@date
		end 

		def cover
			get_attr if @title==nil	
			@cover
		end 

		def language
			get_attr if @title==nil	
			@language
		end 

		def rights
			get_attr if @title==nil	
			@rights
		end 

		def file(format)
			get_attr if @files==nil	
			@files[format]
		end 

		def description
			get_attr if @title==nil	
			@description
		end 

		def similar(limit=nil)
			self.class.generic_iterate("/book/#{@id}/similar.xml",limit)
		end

		def self.search(txt,limit=nil)
			return [] if txt.strip.size==0
			generic_iterate("/books/search.xml?query=#{URI.escape(txt)}",limit)
		end

		def self.top(limit=nil)
			generic_iterate("/books/top.xml",limit)
		end

		def self.recent(limit=nil)
			generic_iterate("/books/recent.xml",limit)
		end

		private 

		def self.generic_iterate(url,limit=nil)
			res=[]
			self.iterate(url) do |b|
				tmp=Book.new
				tmp.send('from_h',Book::from_xml_elm(b))
				tmp.instance_variable_set('@id',b.attributes['id'].to_i)
				res.push(tmp)
				return res[0...limit] if !limit.nil? && res.size >= limit

			end
			res
		end

		def from_h(h)
			h.each do |k,v|
				if k!="author"
					self.instance_variable_set('@'+k,v)
				else
					v=[v].flatten
					self.instance_variable_set('@'+k,v.collect{|a| FeedBooks::Author.from_h(a)})
				end
			end
		end

		def get_attr
			from_h(super)
		end
	end


	class Author < FBobject
		attr_reader :id

		def initialize(id=nil)
			@id=id
		end

		def fullname=(txt)
			@name,@firstname=txt.split(",")
		end

		def fullname
			get_attr if @name==nil	
			@name+", "+@firstname
		end

		def name
			get_attr if @name==nil	
			@name
		end

		def firstname
			get_attr if @firstname==nil	
			@firstname
		end

		def birth
			get_attr if @birth==nil	
			@birth
		end

		def death
			get_attr if @birth==nil	
			@death
		end

		def books_count
			get_attr if @books==nil	
			@books
		end

		def downloads_count
			get_attr if @downloads==nil	
			@downloads
		end

		def biography
			get_attr if @biography==nil	
			@biography
		end

		def self.from_h(h)
			r=Author.new
			r.send('id=',h['id'])
			r.fullname=h['author']
			r
		end
		
		def self.search(txt,limit=nil)
			return [] if txt.strip.size==0
			generic_iterate("/authors/search.xml?query=#{URI.escape(txt)}",limit)
		end

		def self.top(limit=nil)
			generic_iterate("/authors/top.xml",limit)
		end

		def self.recent(limit=nil)
			generic_iterate("/authors/recent.xml",limit)
		end
		
		def books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/author/#{@id}/books.xml",limit)
		end

		def top_books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/author/#{@id}/books/top.xml",limit)
		end
		
		def recent_books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/author/#{@id}/books/recent.xml",limit)
		end
		
		private 

		def id=(i)
			@id=i
		end
		
		def self.generic_iterate(url,limit=nil)
			res=[]
			self.iterate(url) do |b|
				tmp=Author.new
				tmp.send('from_h_priv',Author::from_xml_elm(b))
				tmp.instance_variable_set('@id',b.attributes['id'].to_i)
				res.push(tmp)
				return res[0...limit] if !limit.nil? && res.size >= limit

			end
			res
		end
		
		def get_attr
			from_h_priv(super)
		end

		def from_h_priv(h)
			h.each do |k,v|
				if k=='name'
					send('fullname=',v)
				else
					self.instance_variable_set('@'+k,v)
				end
			end
		end
	end
end

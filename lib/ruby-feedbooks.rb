# Access Library to FeedBooks API
# More information at : http://www.feedbooks.com/api
#
# Author:: Benoit Larroque ( firstname dot surname at feedbooks.com)
# Copyright:: Feedbooks.com
# Licence:: Public Domain

require 'open-uri'
require 'hpricot'
require 'digest/md5'

#Module for the library
#
#=Usage example
#==Search for books mathcing keyword "test"
#  Feedbooks::Book.search("test")
#==Access Recommandations
#  FeedBooks::Book.connection=FeedBooks::Connection.new('uesr','passwd')
#  FeedBooks::Book.recommended
#
module FeedBooks
	
	#User Agent Name
	NAME        = 'Ruby/FeedBooks'
	#Library Version
	VERSION     = '0.1'
	#Complete User-Agent
	USER_AGENT  = "%s %s" % [NAME, VERSION]

	#Error class when not authenticated
	class FeedBooks::UnauthenticatedError < StandardError
		 def initialize(m=nil)
			       super(m.nil? ? "You are not connected (no user/password)": m)
		 end	           
	end
	
	#Error class when password and user mismatched
	class FeedBooks::WrongCredentialsError < FeedBooks::UnauthenticatedError
		 def initialize()
			       super("User / password mismatched")
		 end	           
	end

	#Connection class used to specify credentials and proxy settings
	class Connection
		#user password
		attr_accessor :password
		#username
		attr_accessor :user
		#proxy url eg. http://user:pass@proxy:8080
		attr_writer :proxy

		def initialize(user=nil,pass=nil)
			@user=user
			@password=pass
		end
		
		#proxy getter
		def proxy
			return @proxy unless @proxy.nil?
			ENV["proxy"]
		end

		def openfb(url) #:nodoc:
			begin
			return open(url,"r",http_opts)
			rescue OpenURI::HTTPError => e 
				if e.io.status.first.to_i == 401
					raise (user.nil? ? FeedBooks::UnauthenticatedError.new  : FeedBooks::WrongCredentialsError.new )
				end
				raise e
			end
		end
		
		def http_opts #:nodoc:
			ret={}
			ret[:http_basic_authentication]=[user,Digest::MD5.hexdigest(password)] unless user.nil?
			ret[:proxy]=proxy
			ret["User-Agent"]=USER_AGENT
			return ret
		end


	end


	#Parent class for all API objects
	class FBobject
		@@connection = Connection.new
	
		#connection setter
		def self.connection=(con)
			@@connection=con
			@@connection=Connection.new if @@connection.nil?
		end

		#connection getter
		#should be a Connection
		def self.connection
			@@connection
		end

		#connection setter
		def connection=(con)
			@@connection=con
			@@connection=Connection.new if @@connection.nil?
		end

		#connection getter
		def connection
			@@connection
		end

		def self.from_xml(txt) #:nodoc:
			doc=Hpricot.XML(txt)
			book=doc/"/*"
			return from_xml_elm(book)
		end
		protected 
		
		def openfb(url) #:nodoc:
			return @@connection.openfb(url)
		end
		
		def self.openfb(url) #:nodoc:
			return @@connection.openfb(url)
		end
		
		def get_attr(name=nil) #:nodoc:
			name=self.class.to_s.downcase.split(':').last if name.nil?
			book=nil
			raise Exception("No Id given") if @id.nil? || @id < 1
			doc = Hpricot.XML(openfb("http://www.feedbooks.com/"+name+"s/search.xml?query=id:#{@id}"))
			book=doc/("//"+name+"[@id='#{@id}']")
			return FBobject::from_xml_elm(book)
		end


		def self.from_xml_elm(book) #:nodoc:
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
		
		#iterate trough results pages
		def self.iterate(url) #:nodoc:
			url+='?' if url.index('?').nil?
			name=self.to_s.downcase.split(':').last
			page=1
			maxpages=0
			begin
				doc=Hpricot.XML(openfb("http://www.feedbooks.com#{url}&page=#{page}"))
				maxpages=doc.root.attributes['total'].to_i
				book=doc.search("//"+name) do |b|
					yield(b)
				end
				page+=1
			end while page<=maxpages
		end
	end

	#Book api object
	#see http://feedbooks.com/api/books
	class Book < FBobject
		attr_reader :id
		def initialize(id=nil)
			@id=id
		end

		def title
			get_attr if @title==nil	
			@title
		end 

		#authors is an array of Author
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
		
		#give an url bases on asked format
		#using the API results (other format may be available)
		def file(format)
			get_attr if @files==nil	
			@files[format]
		end 

		def description
			get_attr if @title==nil	
			@description
		end
		

		#subjects is an array of Type elements
		def subjects
			get_attr if @title==nil
			@subject.collect{|s| FeedBooks::Type.new(s)}
		end
		
		alias :types :subjects

		#get similar books
		def similar(limit=nil)
			self.class.generic_iterate("/book/#{@id}/similar.xml",limit)
		end

		#Search in books catalog returns an Array
		def self.search(txt,limit=nil)
			return [] if txt.strip.size==0
			generic_iterate("/books/search.xml?query=#{URI.escape(txt)}",limit)
		end

		#get top books (can be limited)
		def self.top(limit=nil)
			generic_iterate("/books/top.xml",limit)
		end

		#get recent books (can be limited)
		def self.recent(limit=nil)
			generic_iterate("/books/recent.xml",limit)
		end
		
		#get recommedations based on user profile
		#the user needs to be authenticatided see Connection
		def self.recommended(limit=nil)
			generic_iterate("/recommendations.xml",limit)
		end
	
		#get an array of lists containing the book
		def lists(limit=nil)
			FeedBooks::List.send('generic_iterate',"/book/#{@id}/lists.xml",limit)
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

	#Author object
	#see http://feedbooks.com/api/authors
	class Author < FBobject
		attr_reader :id

		def initialize(id=nil)
			@id=id
		end

		def fullname=(txt) #:nodoc:
			@name,@firstname=txt.split(",")
		end

		#virtual attribute fullname based on firstname and name
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
		
		#Number of books written by this author
		def books_count
			get_attr if @books==nil	
			@books
		end

		#Count of downloaded books from author
		def downloads_count
			get_attr if @downloads==nil	
			@downloads
		end

		def biography
			get_attr if @biography==nil	
			@biography
		end

		def self.from_h(h) #:nodoc:
			r=Author.new
			r.send('id=',h['id'])
			r.fullname=h['author']
			r
		end

		#Search through author catalog
		def self.search(txt,limit=nil)
			return [] if txt.strip.size==0
			generic_iterate("/authors/search.xml?query=#{URI.escape(txt)}",limit)
		end

		#Top authors (by download)
		def self.top(limit=nil)
			generic_iterate("/authors/top.xml",limit)
		end

		#Recent authors 
		def self.recent(limit=nil)
			generic_iterate("/authors/recent.xml",limit)
		end

		#Array of books written by this author
		def books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/author/#{@id}/books.xml",limit)
		end

		#Array of top books written by this author
		def top_books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/author/#{@id}/books/top.xml",limit)
		end

		#Array of recent books written by this author
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

	#Type object 
	#see http://feedbooks.com/api/types
	class Type < FBobject
		attr_reader :name
		attr_reader :total_books

		def initialize(name=nil)
			@name=name
		end

		def total_books
			get_attr if @total_books.nil?
			@total_books.to_i
		end

		#List all types known on feedbooks
		def self.all(lim=nil)
			generic_iterate('/types.xml',lim)
		end

		#all books tagged with this type
		def books(limit=nil) 
			
			FeedBooks::Book.send('generic_iterate',"/type/#{@name}/books.xml",limit)
		end
		
		#top books tagged with this type
		def top_books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/type/#{@name}/books/top.xml",limit)
		end

		#recent books tagged with this type
		def recent_books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/type/#{@name}/books/recent.xml",limit)
		end

		private
		
		def self.generic_iterate(url,limit=nil)
			res=[]
			self.iterate(url) do |b|
				tmp=Type.new
				tmp.send('from_h',Type::from_xml_elm(b))
				tmp.instance_variable_set('@id',b.attributes['id'].to_i)
				res.push(tmp)
				return res[0...limit] if !limit.nil? && res.size >= limit

			end
			res
		end
		
		def from_h(h)
			h.each do |k,v|
				self.instance_variable_set('@'+k,v)
			end
		end

		def get_attr
			@total_books=Type.all.find{|t| t.name==@name}.total_books
		end

	end

	#List object
	#see http://feedbooks.com/api/lists.
	#A list is a collection of Book
	class List < FBobject
		include Enumerable
		attr_reader :id
		def initialize(id=nil)
			@id=id
		end

		def title
			get_attr if @title==nil	
			@title
		end 
		
		def identifier
			get_attr if @title==nil	
			@identifier
		end 
		
		def description
			get_attr if @title==nil	
			@description
		end 
		
		def favorites
			get_attr if @title==nil	
			@favorites.to_i
		end 
		
		def items
			get_attr if @title==nil	
			@items.to_i
		end 
		
		#All books in the list
		def books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/list/#{@id}.xml",limit)
		end

		#All list on feedbooks
		def self.all(lim=nil)
			generic_iterate('/lists.xml',lim)
		end

		#iterate through books in the list
		def each_books(lim=nil)
			books.each{|b| yield b}
		end

		alias :each :each_books
		
		private 

		def self.generic_iterate(url,limit=nil)
			res=[]
			self.iterate(url) do |b|
				tmp=List.new
				tmp.send('from_h',List::from_xml_elm(b))
				tmp.instance_variable_set('@id',b.attributes['id'].to_i)
				res.push(tmp)
				return res[0...limit] if !limit.nil? && res.size >= limit

			end
			res
		end

		def from_h(h)
			h.each do |k,v|
					self.instance_variable_set('@'+k,v)
			end
		end

		def get_attr
			List::iterate('/lists.xml') do  |l|
				next unless l.attributes['id'].to_i==@id
				return from_h(List::from_xml_elm(l))
			end
		end
		
	end
end

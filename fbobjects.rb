require 'open-uri'
require 'hpricot'
require 'digest/md5'
module FeedBooks

	NAME        = 'Ruby/FeedBooks'
	VERSION     = '0.1'
	USER_AGENT  = "%s %s" % [NAME, VERSION]

	class FeedBooks::UnauthenticatedError < StandardError
		 def initialize(m=nil)
			       super(m.nil? ? "You are not connected (no user/password)": m)
		 end	           
	end
	
	class FeedBooks::WrongCredentialsError < FeedBooks::UnauthenticatedError
		 def initialize()
			       super("User / password mismatched")
		 end	           
	end

	class Connection
		attr_accessor :password
		attr_accessor :user
		attr_writer :proxy

		def initialize(user=nil,pass=nil)
			@user=user
			@password=pass
		end

		def proxy
			return @proxy unless @proxy.nil?
			ENV["proxy"]
		end

		def openfb(url)
			begin
			return open(url,"r",http_opts)
			rescue OpenURI::HTTPError => e 
				if e.io.status.first.to_i == 401
					raise (user.nil? ? FeedBooks::UnauthenticatedError.new  : FeedBooks::WrongCredentialsError.new )
				end
				raise e
			end
		end

		def http_opts
			ret={}
			ret[:http_basic_authentication]=[user,Digest::MD5.hexdigest(password)] unless user.nil?
			ret[:proxy]=proxy
			ret["User-Agent"]=USER_AGENT
			return ret
		end


	end



	class FBobject
		@@connection = Connection.new
	
		def self.connection=(con)
			@@connection=con
			@@connection=Connection.new if @@connection.nil?
		end

		def self.connection
			@@connection
		end

		def connection=(con)
			@@connection=con
			@@connection=Connection.new if @@connection.nil?
		end

		def connection
			@@connection
		end

		def self.from_xml(txt)
			doc=Hpricot.XML(txt)
			book=doc/"/*"
			return from_xml_elm(book)
		end
		protected 
		
		def openfb(url)
			return @@connection.openfb(url)
		end
		
		def self.openfb(url)
			return @@connection.openfb(url)
		end
		
		def get_attr(name=nil)
			name=self.class.to_s.downcase.split(':').last if name.nil?
			book=nil
			raise Exception("No Id given") if @id.nil? || @id < 1
			doc = Hpricot.XML(openfb("http://www.feedbooks.com/"+name+"s/search.xml?query=id:#{@id}"))
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
				doc=Hpricot.XML(openfb("http://www.feedbooks.com#{url}&page=#{page}"))
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

		def subjects
			get_attr if @title==nil
			@subject.collect{|s| FeedBooks::Type.new(s)}
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
		
		def self.recommended(limit=nil)
			generic_iterate("/recommendations.xml",limit)
		end
		
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

	class Type < FBobject
		attr_reader :name

		def initialize(name=nil)
			@name=name
		end

		def total_books
			get_attr if @total_books.nil?
			@total_books.to_i
		end

		def self.all(lim=nil)
			generic_iterate('/types.xml',lim)
		end

		def books(limit=nil) 
			
			FeedBooks::Book.send('generic_iterate',"/type/#{@name}/books.xml",limit)
		end
		
		def top_books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/type/#{@name}/books/top.xml",limit)
		end

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

	class List < FBobject
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
		
		def books(limit=nil)
			FeedBooks::Book.send('generic_iterate',"/list/#{@id}.xml",limit)
		end

		def self.all(lim=nil)
			generic_iterate('/lists.xml',lim)
		end
		
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

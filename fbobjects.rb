require 'net/http'
require 'rexml/document'
module FeedBooks

	NAME        = 'Ruby/FeedBooks'
	VERSION     = '0.1'
	USER_AGENT  = "%s %s" % [NAME, VERSION]


	class Book
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

		private 
		def get_attr
			book=nil
			raise Exception("No Id given") if @id.nil? || @id < 1
			Net::HTTP.start("www.feedbooks.com"){|http|
				resp=http.get("/books/search.xml?query=id:#{@id}")
				doc=REXML::Document.new resp.body
				book=doc.root.elements["//book[@id='#{@id}']"]
			}
			h=Hash.new
			book.each_element do |el|
				tmp=el.to_a
				if tmp.size ==1 
					tmp=el.text
					tmp={"id"=>el.attributes['id'].to_i,el.name=> tmp} unless el.attributes['id'].nil?
					if  h[el.name].nil?
						h[el.name]=tmp
					else
						h[el.name]=[h[el.name], tmp].flatten
					end
				else
					h[el.name]=Hash.new
					el.each_element do |elc|
						h[el.name][elc.name]=elc.text
					end
				end
			end

			h.each do |k,v|
				if k!="author"
					self.instance_variable_set('@'+k,v)
				else
					v=[v].flatten
					self.instance_variable_set('@'+k,v.collect{|a| FeedBooks::Author.from_h(a)})
				end
			end
		end
	end


	class Author
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
		private 
		def id=(i)
			@id=i
		end
		def get_attr
			book=nil
			raise Exception("No Id given") if @id.nil? || @id < 1
			Net::HTTP.start("www.feedbooks.com"){|http|
				resp=http.get("/authors/search.xml?query=id:#{@id}")
				doc=REXML::Document.new resp.body
				book=doc.root.elements["//author[@id='#{@id}']"]
			}
			h=Hash.new
			book.each_element do |el|
				tmp=el.to_a
				if tmp.size ==1 
					tmp=el.text
					tmp={"id"=>el.attributes['id'].to_i,el.name=> tmp} unless el.attributes['id'].nil?
					if  h[el.name].nil?
						h[el.name]=tmp
					else
						h[el.name]=[h[el.name], tmp].flatten
					end
				else
					h[el.name]=Hash.new
					el.each_element do |elc|
						h[el.name][elc.name]=elc.text
					end
				end
			end

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

require 'fbobjects'

describe FeedBooks::Book do 
	before(:each) do 
		@book=FeedBooks::Book.new(1)
	end

	it "should have an id" do
		@book.should respond_to('id')
	end
	
	it "shouldn't have an id=" do
		@book.should_not respond_to('id=')
	end
	
	it "should have an author list" do
		@book.should respond_to('authors')
		@book.authors.class.should ==Array
	end

	it "should have a full author list" do
		@book.authors.size.should >0
	end
	
	it "should have *author* list" do
		@book.authors.each{|a| a.class.should ==FeedBooks::Author}
	end

	it "should have a title" do
		@book.should respond_to('title')
		@book.title.nil?.should ==false
	end
	
	it "should have a date" do
		@book.should respond_to('date')
		@book.date.nil?.should ==false
	end
	
	it "should have a cover" do
		@book.should respond_to('cover')
		@book.cover.nil?.should ==false
	end
	
	it "should have a language" do
		@book.should respond_to('language')
		@book.language.nil?.should ==false
	end

	it "should have a rights" do
		@book.should respond_to('rights')
	end
	
	it "should have a download links" do
		@book.should respond_to('file')
	end
	
	it "should have a description" do
		@book.should respond_to('description')
	end
	it "should be able to get similar books" do
		@book.should respond_to('similar')
		@book.similar(10).size.should ==10
	end
	
	it "should be able to search" do
		FeedBooks::Book.should respond_to('search')
	end

	it "should be able to get top books" do
		FeedBooks::Book.should respond_to('top')
		FeedBooks::Book.top(10).size.should ==10
	end
	
	it "should be able to get recent books" do
		FeedBooks::Book.should respond_to('recent')
		FeedBooks::Book.recent(10).size.should ==10
	end
	


end

describe FeedBooks::Connection do

	before(:each) do
		@con=FeedBooks::Connection.new()
	end

	it "should have a  nil user when new" do 
		@con.user.should be_nil
	end
	
	it "should have a  nil password when new" do
		@con.password.should be_nil
	end

	it "should have the env proxy  when new" do 
		@con.proxy.should == ENV["proxy"]
	end
	
	it "should have a option hash" do 
		@con.should respond_to(:http_opts)
		@con.http_opts.should_not be_nil
	end

	it "should have :http_basic_authentication set given a user" do
		@con.user="test"
		@con.password="test"
		a=@con.http_opts[:http_basic_authentication]
		a.first.should =="test"
		a.last.should ==Digest::MD5.hexdigest("test")
	end

	it "should have a User-agent" do 
		@con.http_opts["User-Agent"].should == FeedBooks::USER_AGENT
	end
	

end


describe "Book (authenticated_user)" do 
	before(:each) do 
		@book=FeedBooks::Book.new(1)
		FeedBooks::Book.connection=FeedBooks::Connection.new("test","test")
	end
	
	it "should respond to recommended" do 
		FeedBooks::Book.should respond_to(:recommended)
	end

	it "should get recommendations" do 
		FeedBooks::Book.connection=FeedBooks::Connection.new("test","test")
		FeedBooks::Book.recommended.should have_at_least(1).item
	end

	after(:each) do
		FeedBooks::Book.connection=nil
	end

end

describe FeedBooks::Author do 
	before(:each) do 
		@author=FeedBooks::Author.new(1)
	end

	it "should have an id" do
		@author.should respond_to('id')
	end
	
	it "shouldn't have an id=" do
		@author.should_not respond_to('id=')
	end
	
	it "should have a name" do
		@author.should respond_to('name')
		@author.name.nil?.should ==false
	end
	
	it "should have a firstname" do
		@author.should respond_to('firstname')
		@author.firstname.nil?.should ==false
	end
	
	it "should have a fullname" do
		@author.should respond_to('fullname')
		@author.fullname.nil?.should ==false
	end
	
	it "should have a birth year" do
		@author.should respond_to('birth')
		@author.birth.nil?.should ==false
	end
	
	it "should have a death year" do
		@author.should respond_to('death')
	end
	
	it "should have a book count" do
		@author.should respond_to('books_count')
	end
	
	it "should have a download count" do
		@author.should respond_to('downloads_count')
	end
	
	it "should have a biography" do
		@author.should respond_to('biography')
	end
	
	it "should be able to search" do
		FeedBooks::Author.should respond_to('search')
	end

	it "should be able to get top" do
		FeedBooks::Author.should respond_to('top')
		FeedBooks::Author.top(10).size.should ==10
	end
	
	it "should be able to get recent" do
		FeedBooks::Author.should respond_to('recent')
		FeedBooks::Author.recent(10).size.should ==10
	end
	
	it "should be able to get books" do
		@author.should respond_to('books')
	end

	it "should be able to get top books" do
		@author.should respond_to('top_books')
		@author.top_books(10).size.should ==10
	end
	
	it "should be able to get recent books" do
		@author.should respond_to('recent_books')
		@author.recent_books(10).size.should ==10
	end
end

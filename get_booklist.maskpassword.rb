#!/usr/local/bin ruby

require 'rubygems'
require 'mechanize'
require "nokogiri"
require "sqlite3"

require '/home/kooooosuke/app/scripts/simple-json.rb'
require 'kconv'
require 'open-uri'
require 'uri'

def scrape(booklist_page, db, agent, circle_name, have_stock)
booklist_page.root.css(".td_ItemBox").each do |book|
        book_info = book.children.css("a")[0]
        if book_info.nil? then
                next
        end
        book_title =  book_info.content.to_s.split("\n")[3].split("\t")[-1]
        book_price = book.content.to_s.split("\n")[8].split("\t")[-1]
        book_url = "http://www.toranoana.jp" + book_info.attributes["href"].to_s
        
	book_detail_page = agent.get(book_url)
	sleep 3

	# 未販売（予約）のケース
	if book_detail_page.root.css("form").length < 2
		next
	end

	book_publish_date = book_detail_page.root.css(".DetailData_R")[1].content.to_s
	book_size = book_detail_page.root.css(".DetailData_R")[2].content.to_s
	book_stock = 0
	if have_stock==1
		book_stock = book_detail_page.root.css("form")[1].children[1].attributes["src"].to_s.split("")[-5].to_i
	end

	db.execute("REPLACE INTO books(circle_name, book_title, publish_date, price, stock, book_size, url) VALUES(?, ?, ?, ?, ?, ?, ?)", circle_name, book_title, book_publish_date, book_price, book_stock, book_size, book_url)
end
end

agent = Mechanize.new{|a| a.user_agent_alias='Windows IE 7'}
agent.max_history = 1

#login
user, pass = '********', '********'
page = agent.get('https://www.toranoana.jp/cgi-bin/login.cgi?id=none&act=m000&bl_fg=0')
sleep 3
login_form = page.forms[0]
login_form.id = user
login_form.password = pass
page = agent.submit(login_form)

#db_path = File.expand_path "../c85.db", __FILE__
db_path = "/home/kooooosuke/app/rails_projects/first_app/db/development.sqlite3"
db = SQLite3::Database.new db_path
my_pixiv_id = "12345678"
following_user_ids = db.execute("SELECT following_user_id FROM followings WHERE follower_user_id=?", my_pixiv_id)


#i=98
following_user_ids.each do |following_user_id| 
following_circle_name = db.execute("SELECT circle_name FROM circles WHERE user_id=?", following_user_id[0])

if following_circle_name.length==0
	next
end
circle_name = following_circle_name[0][0]

#if i>0
#        i=i-1
#        next
#end

# 検索URLの作成
word = "作品リスト"
site = "site:www.toranoana.jp"
search_word = URI.encode(circle_name) + "%20" + URI.encode(word) + "%20" + site
targetUrl="http://ajax.googleapis.com/ajax/services/search/web?v=1.0&q="+search_word
sleep 5

# 検索結果の取得
response=open(targetUrl)
src=response.read
src = NKF.nkf('-wxm0', src)

# 検索結果の解析
result = JsonParser.new
j=result.parse(src)

# タイトルとURLの表示
if j["responseData"]["results"].length == 0
	print "nodata1\n"
	next
end

page_title =  j["responseData"]["results"][0]["titleNoFormatting"]
id_url =  j["responseData"]["results"][0]["url"].split("/")[-1].split("_")[-2]
base_url = ""
str = j["responseData"]["results"][0]["url"].split("/")
(str.length-1).times do |i|
	base_url = base_url + str[i] + "/"
end

book_list_page_url = "/circle/"
unless base_url.index(book_list_page_url) then
	print "nodata2"
	next
end

# 変なURLに当たることがある
begin
	url_haveimage_havestock = base_url + id_url + "_01.html"
	url_haveimage_nostock   = base_url + "ns_" + id_url + "_01.html"
rescue
	print "nodata3"
	next
end

booklist_havestock_page = agent.get(url_haveimage_havestock)
booklist_nostock_page   = agent.get(url_haveimage_nostock)

have_stock=1
scrape(booklist_havestock_page, db, agent, circle_name, have_stock)
#have_stock=0
#scrape(booklist_nostock_page  , db, agent, circle_name, have_stock)
end #times


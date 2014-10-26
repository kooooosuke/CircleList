#!/usr/local/bin ruby

require "open-uri"
require "nokogiri"
require "uri"
require "sqlite3"

#db_path = File.expand_path "../c85.db", __FILE__
db_path = "/home/kooooosuke/app/rails_projects/first_app/db/development.sqlite3"
db = SQLite3::Database.new db_path
attend_date = "20131231"

max_loop_count=100
for i in 1..max_loop_count do
  url = "http://www.pixiv.net/event_member.php?event_id=3285&s_mode=s_circle&mode=circle&type=all&p="+i.to_s+"&date="+attend_date
  pixiv_html = Nokogiri::HTML(open(url))
  sleep 1

  if pixiv_html.css('.thul').length==0
        break
  end

  pixiv_html.css('.thul').each do |circle|
	user_id     = circle.css('a')[0].attributes['href'].to_s.split('&')[0].split('=')[1].to_i
	circle_name = circle.css('a')[1].content.to_s
	space_info  = circle.content.to_s.split("\n")[3]
	space_area  = space_info.split("")[0]
	space_block = space_info.split("")[2]
	space_no    = space_info.split("-")[1].split("a")[0].split("b")[0]
	space_ab    = space_info.split("")[-1]
	#print user_id+" "+circle_name+"\n"+space_area+" "+space_block+" "+space_no+" "+space_ab+"\n\n"

	db.execute("REPLACE INTO circles(user_id, circle_name, space_area, space_block, space_no, space_ab, attend_date) VALUES(?, ?, ?, ?, ?, ?, ?)", user_id, circle_name, space_area, space_block, space_no, space_ab, attend_date)
  end
end #loop end


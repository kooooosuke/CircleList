#!/usr/local/bin ruby

require 'rubygems'
require 'mechanize'
require 'sqlite3'

agent = Mechanize.new{|a| a.user_agent_alias='Windows IE 7'}
agent.max_history = 1

#login
user, pass = '********', '********'
page = agent.get('https://www.secure.pixiv.net/login.php?ref=apps')
login_form = page.forms[1]
login_form.pixiv_id = user
login_form.pass = pass
page = agent.submit(login_form)

#connect db
#db_path = File.expand_path "../c85.db", __FILE__
db_path = "/home/kooooosuke/app/rails_projects/first_app/db/development.sqlite3"
db = SQLite3::Database.new db_path

follower_user_id = 12345678
max_loop_count=25
for i in 1..max_loop_count do
  page = agent.get('http://www.pixiv.net/bookmark.php?type=user&id='+follower_user_id.to_s+'&rest=show&p='+i.to_s)
  sleep 1

  if page.root.css('.userdata').length==0
	break
  end

  #update db
  page.root.css('.userdata').each do |user_data|
    following_user_id = user_data.css('a')[0].attributes['href'].to_s.split('=')[1].to_i
    begin
	db.execute("INSERT INTO followings(following_user_id, follower_user_id) VALUES(?, ?)", following_user_id, follower_user_id)
    rescue
	next
    end	
  end
end #loop end


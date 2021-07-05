require 'sinatra'
require 'rubygems'
require 'bundler'
require 'mysql2'
require 'sinatra/reloader'

# Encoding.default_external = 'utf-8'
client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')

class Player
  attr_accessor :name
  attr_accessor :position
  attr_accessor :birthday
  attr_accessor :salary
  attr_accessor :draftTeamName
  attr_accessor :npbTeamName
  attr_accessor :foreigner
 
  def initialize(playerNo)
    client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
    sql = "SELECT playerName, player.position, player.birthday, player.salary, player.foreigner, npb_team.name npbTeamName, draft_team.name draftTeamName FROM player, draft_team, draft_detail, npb_team WHERE player.no = ? AND player.no = draft_detail.playerNo AND draft_team.no = draft_detail.draftTeamNo AND npb_team.no = draft_detail.npbTeamNo"
    statement = client.prepare(sql)
    results = statement.execute(playerNo)

    results.each do |row|
      row.each do |key, value|
        if key == "playerName"
          self.name = value
        elsif key == "position"
          self.position = value
        elsif key == "birthday"
          self.birthday = value
        elsif key == "salary"
          self.salary = value
        elsif key == "draftTeamName"
          self.draftTeamName = value
        elsif key == "npbTeamName"
          self.npbTeamName = value
        elsif key == "foreigner"
          if value == 1
            self.foreigner = "（外）"
          end 
        end
      end    
    end


  end
end

get '/' do
  query = %q{SELECT name FROM draft_team}
  @results = client.query(query)
  erb :team
end

get '/member/:name' do
  @teamName = params['name']
  sql = "SELECT ranking, playerNo, playerName, npb_team.name, fireFlg FROM draft_team, draft_detail, npb_team WHERE draft_team.name = ? AND draft_team.no = draft_detail.draftTeamNo AND npb_team.no = draft_detail.npbTeamNo ORDER BY ranking"
  statement = client.prepare(sql)
  @results = statement.execute(@teamName)
  erb :member
end

get '/player/:no' do
  player = Player.new(params['no'])
  @playerName = player.name
  @playerPosition = player.position
  @playerBirthday = player.birthday
  @salary = player.salary
  @npbTeamName = player.npbTeamName
  @draftTeamName = player.draftTeamName
  @foreigner = player.foreigner
  erb :player
end

__END__

@@team
<!DOCTYPE html>
<html lang="ja">
    <head>
        <mata charset="utf-8">
        <title>Sinatra - paiza</title>
        <style>body {padding: 30px;}</style>
    </head>
    <body>
        <h1>ドラフトチーム一覧</h1>
        <% @results.each do |row| %>
          <% row.each do |key, value| %>
            <%= "<p><a href='/member/#{value}'>#{value}</a></p>" %>
          <% end %>    
        <% end %>
    </body>
</html>

@@member
<!DOCTYPE html>
<html lang="ja">
    <head>
        <mata charset="utf-8">
        <title>Sinatra - paiza</title>
        <style>body {padding: 30px;}</style>
    </head>
    <body>
      <p><a href='/'>ホーム</a></p>
      <h1><%= @teamName %></h1>
      <table border=1>
        <tr>
          <th>指名順</th>
          <th>名前</th>
          <th>所属球団</th>
          <th>解雇</th>
        </tr>
        <% @results.each do |row| %>
          <tr>
            <% playerNo = '' %>
            <% row.each do |key, value| %>
              <% if key == "fireFlg" && value == 1 %>
                <%= "<td>解雇</td>" %>
              <% elsif key == "fireFlg" %>
                <%= "<td></td>" %>
              <% elsif key == "playerNo" %>
                <% playerNo = value %>
              <% elsif key == "playerName" %>
                <% if playerNo == '' %>
                  <%= "<td>#{value}</td>" %>
                <% else %>
                  <%= "<td><a href='/player/#{playerNo}'>#{value}</a>" %>
                <% end %>
              <% else %>
                <%= "<td>#{value}</td>" %>
              <% end %>
            <% end %>
          </tr>
        <% end %>
      </table>
      <p><a href='/'>ホーム</a></p>
    </body>
</html>

@@player
<!DOCTYPE html>
<html lang="ja">
    <head>
        <mata charset="utf-8">
        <title>Sinatra - paiza</title>
        <style>body {padding: 30px;}</style>
    </head>
    <body>
        <p><a href='/'>ホーム</a>
        <a href='/member/<%= @draftTeamName %>'><%= @draftTeamName %></a></p>
        <h1><%= @playerName %><%= @foreigner %></h1>
        <p><%= @playerPosition %></p>
        <p>生年月日：<%= @playerBirthday %></p>
        <p>年棒：<%= @salary %> 万円</p>
        <p>所属NPBチーム：<%= @npbTeamName %></p>
        </body>
</html>
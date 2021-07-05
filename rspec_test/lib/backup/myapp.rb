require 'sinatra'
require 'rubygems'
require 'bundler'
require 'mysql2'
require 'sinatra/reloader'

# Encoding.default_external = 'utf-8'
client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')

get '/' do
  query = %q{SELECT name FROM draft_team}
  @results = client.query(query)
  erb :team
end

get '/member/:name' do
  @teamName = params['name']
  sql = "SELECT ranking, playerName, npb_team.name, fireFlg FROM draft_team, draft_detail, npb_team WHERE draft_team.name = ? AND draft_team.no = draft_detail.draftTeamNo AND npb_team.no = draft_detail.npbTeamNo ORDER BY ranking"
  statement = client.prepare(sql)
  @results = statement.execute(@teamName)
  erb :member
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
      <p><a href='/'>もどる</a></p>
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
            <% row.each do |key, value| %>
              <% if key == "fireFlg" && value == 1 %>
                <%= "<td>解雇</td>" %>
              <% elsif key == "fireFlg" %>
                <%= "<td></td>" %>
              <% else %>
                <%= "<td>#{value}</td>" %>
              <% end %>
            <% end %>
          </tr>
        <% end %>
      </table>
      <p><a href='/'>もどる</a></p>
    </body>
</html>

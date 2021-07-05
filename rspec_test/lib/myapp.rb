require 'sinatra'
require 'rubygems'
require 'bundler'
require 'mysql2'
require 'sinatra/reloader'

# Encoding.default_external = 'utf-8'
client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')

class DraftTeam
  attr_accessor :no
  attr_accessor :name
  attr_accessor :abbrName

  def initialize(no)
    @draftTeamNo = no
    client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
    sql = "SELECT no, name, abbrName FROM draft_team WHERE no = ? "
    statement = client.prepare(sql)
    results = statement.execute(no)

    results.each do |row|
      row.each do |key, value|
        if key == "name"
          self.name = value
        elsif key == "abbrName"
          self.abbrName = value
        end
      end    
    end
  end

end


class DraftDetail
  attr_accessor :no
  attr_accessor :playerNo
  attr_accessor :draftTeamNo
  attr_accessor :ranking
  attr_accessor :fireFlg
  

  def initialize(no)
    @draftNo = no
    client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
    sql = "SELECT no, playerNo, draftTeamNo, ranking, fireFlg FROM draft_detail WHERE no = ? "
    statement = client.prepare(sql)
    results = statement.execute(no)

    results.each do |row|
      row.each do |key, value|
        if key == "playerNo"
          self.playerNo = value
        elsif key == "draftTeamNo"
          self.draftTeamNo = value
        elsif key == "fireFlg"
          self.fireFlg = value
        elsif key == "ranking"
          self.ranking = value
        end
      end    
    end
  end

  def delete()
    client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
    sql = "DELETE FROM draft_detail WHERE no = ? "
    statement = client.prepare(sql)
    results = statement.execute(@draftNo)
  end
end



class Player
  attr_accessor :playerNo
  attr_accessor :name
  attr_accessor :position
  attr_accessor :birthday
  attr_accessor :salary
  attr_accessor :npbTeamNo
  attr_accessor :npbTeamName
  attr_accessor :foreigner
  attr_accessor :draftDetailNo
  attr_accessor :draftTeamNo
  attr_accessor :draftTeamName
  attr_accessor :ranking
  attr_accessor :fireFlg
 
  def initialize(playerNo)
    @playerNo = playerNo
    client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
    sql  = "SELECT player.name playerName, player.position, player.birthday, player.salary, player.foreigner, player.npbTeamNo, npb_team.name npbTeamName "
    sql += "FROM player, npb_team "
    sql += "WHERE player.no = ? AND npb_team.no = player.npbTeamNo"
    statement = client.prepare(sql)
    results = statement.execute(playerNo)

    results.each do |row|
      row.each do |key, value|
        if key == "playerName"
          self.name = value
          @playerName = value
        elsif key == "position"
          self.position = value
        elsif key == "birthday"
          self.birthday = value
        elsif key == "salary"
          self.salary = value
        elsif key == "npbTeamNo"
          self.npbTeamNo = value
          @npbTeamNo = value
        elsif key == "npbTeamName"
          self.npbTeamName = value
        elsif key == "foreigner"
          if value == 1
            self.foreigner = "（外）"
          end 
        end
      end    
    end

    sql  = "SELECT draft_detail.no draftDetailNo, draft_detail.draftTeamNo, draft_team.name draftTeamName, ranking, fireFlg "
    sql += "FROM draft_detail, draft_team "
    sql += "WHERE draft_detail.playerNo = ? AND draft_team.no = draft_detail.draftTeamNo"
    statement = client.prepare(sql)
    results = statement.execute(@playerNo)

    results.each do |row|
      row.each do |key, value|
        if key == "draftDetailNo"
          self.draftDetailNo = value
        elsif key == "draftTeamNo"
          self.draftTeamNo = value
        elsif key == "draftTeamName"
          self.draftTeamName = value
        elsif key == "ranking"
          self.ranking = value
        elsif key == "fireFlg"
          self.fireFlg = value
        end
      end    
    end


  end

  # 解雇登録
  def fire()
    client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
    sql = "UPDATE draft_detail SET fireFlg = 1 WHERE playerNo = ? "
    statement = client.prepare(sql)
    results = statement.execute(@playerNo)
  end

  # ドラフト指名
  def draft(draftTeamNo)

    # 指名順位の最大値を取得
    client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
    sql = "SELECT MAX(ranking) maxRanking FROM draft_detail WHERE draftTeamNo = ?"
    statement = client.prepare(sql)
    results = statement.execute(draftTeamNo)

    results.each do |row|
      row.each do |key, value|
        if key == "maxRanking"
          @maxRanking = value + 1
      
        end
      end    
    end

    # ドラフト指名データの登録
    sql = "INSERT INTO draft_detail(playerNo, playerName, npbTeamNo, draftTeamNo, ranking) VALUES (?, ?, ?, ?, ?)"
    statement = client.prepare(sql)
    results = statement.execute(@playerNo, @playerName, @npbTeamNo, draftTeamNo, @maxRanking )
  end

end

get '/' do
  query = %q{SELECT no, name FROM draft_team}
  @results = client.query(query)
  erb :team
end

get '/member/:draftTeamNo' do
  @draftTeamNo = params['draftTeamNo']
  sql  = "SELECT name FROM draft_team WHERE no = ?"
  statement = client.prepare(sql)
  results = statement.execute(@draftTeamNo)
  results.each do |row|
    row.each do |key, value|
      @draftTeamName = value
    end    
  end
  
  sql  = "SELECT ranking, playerNo, playerName, npb_team.name, fireFlg, draft_detail.no draftNo "
  sql += "FROM draft_team, draft_detail, npb_team "
  sql += "WHERE draft_team.no = ? AND draft_team.no = draft_detail.draftTeamNo AND npb_team.no = draft_detail.npbTeamNo "
  sql += "ORDER BY ranking"
  statement = client.prepare(sql)
  @results = statement.execute(@draftTeamNo)
  erb :member
end


get '/draft/:draftTeamNo/:playerNo' do
  draftTeamNo = params['draftTeamNo']
  
  playerNo = params['playerNo']
  player = Player.new(playerNo)
  player.draft(draftTeamNo)
  redirect "/member/#{draftTeamNo}"
  
end


get '/draft/:draftTeamNo' do
  @draftTeamNo = params['draftTeamNo']
  draftTeam = DraftTeam.new(@draftTeamNo)
  @teamName = draftTeam.name
  sql  = "SELECT npb_team.name npbTeamName, player.no playerNo, uniformNumber, player.name playerName, pitchHand, hitHand, foreigner, player.position, draft_detail1.draftTeamName draftTeamName, fireFlg "
  sql += "FROM player LEFT JOIN "
  sql += "  (SELECT playerNo, draft_team.no draftTeamNo, draft_team.name draftTeamName, fireFlg FROM draft_detail JOIN draft_team ON draft_detail.draftTeamNo = draft_team.no )draft_detail1 "
  sql += "ON player.no =  draft_detail1.playerNo, npb_team "
  sql += "WHERE player.npbTeamNo = npb_team.no  "
  sql += "ORDER BY npb_team.no, length(player.uniformNumber), player.uniformNumber"
  statement = client.prepare(sql)
  @results = statement.execute()
  erb :draft
end



get '/player/:playerNo' do
  player = Player.new(params['playerNo'])
  @playerName = player.name
  @playerPosition = player.position
  @playerBirthday = player.birthday
  @salary = player.salary
  @npbTeamNo = player.npbTeamNo
  @npbTeamName = player.npbTeamName
  @draftTeamNo = player.draftTeamNo
  @draftTeamName = player.draftTeamName
  @foreigner = player.foreigner
  erb :player
end

get '/fire/:draftTeamNo/:playerNo' do
  player = Player.new(params['playerNo'])
  player.fire() 
  redirect "/member/#{params['draftTeamNo']}"
end

get '/deleteDraft/:draftTeamNo/:draftNo' do
  draftdetail = DraftDetail.new(params['draftNo'])
  draftdetail.delete() 
  redirect "/member/#{params['draftTeamNo']}"
end



__END__

@@team
<!DOCTYPE html>
<html lang="ja">
    <head>
        <meta charset="utf-8">
        <title>ドラフトチーム一覧</title>
        <style>body {padding: 30px;}</style>
    </head>
    <body>
        <h1>ドラフトチーム一覧</h1>
        <% @results.each do |row| %>
          <% draftTeamNo = 0 %>
          <% row.each do |key, value| %>
            <% if key == "no" %>
              <% draftTeamNo = value %>
            <% elsif key == "name"%>
              <%= "<p><a href='/member/#{draftTeamNo}'>#{value}</a></p>" %>
            <% end %>
          <% end %>    
        <% end %>
    </body>
</html>

@@member
<!DOCTYPE html>
<html lang="ja">
    <head>
        <meta charset="utf-8">
        <title>指名選手一覧</title>
        <style>body {padding: 30px;}</style>
    </head>
    <body>
      <p><a href='/'>ホーム</a></p>
      <h1><%= @draftTeamName %></h1>
      <table border=1>
        <tr>
          <th>指名順</th>
          <th>名前</th>
          <th>所属球団</th>
          <th>解雇</th>
          <th>解雇／取消</th>
          <th>データ削除</th>
        </tr>
        <% @results.each do |row| %>
          <tr>
            <% playerNo = '' %>
            <% fireFlg = '' %>
            <% draftTeamNo = '' %>
            <% draftNo = '' %>

            <% row.each do |key, value| %>
              <% if key == "fireFlg" && value == 1 %>
                <%= "<td>解雇済み</td>" %>
                <% fireFlg = '1' %>
              <% elsif key == "fireFlg" %>
                <%= "<td></td>" %>
                <% fireFlg = '0' %>
              <% elsif key == "playerNo" %>
                <% playerNo = value %>
              <% elsif key == "playerName" %>
                <% if playerNo == '' %>
                  <%= "<td>#{value}</td>" %>
                <% else %>
                  <%= "<td><a href='/player/#{playerNo}'>#{value}</a>" %>
                <% end %>
              <% elsif key == "draftNo" %>
                <% draftNo = value %>
              <% else %>
                <%= "<td>#{value}</td>" %>
              <% end %>
            <% end %>
            <% if fireFlg == '0' %>
              <%= "<td><a href='/fire/#{@draftTeamNo}/#{playerNo}'>解雇する</a></td>" %>
            <% else %>
              <%= "<td></td>" %>
            <% end %>
            <%= "<td><a href='/deleteDraft/#{@draftTeamNo}/#{draftNo}'>削除する</a></td>" %>
          </tr>
        <% end %>
      </table>
      <%= "<p><a href='/draft/#{@draftTeamNo}'>追加指名</a></p>" %>
      <p><a href='/'>ホーム</a></p>
    </body>
</html>

@@player
<!DOCTYPE html>
<html lang="ja">
    <head>
        <meta charset="utf-8">
        <title>選手詳細情報</title>
        <style>body {padding: 30px;}</style>
    </head>
    <body>
        <p><a href='/'>ホーム</a>
        <a href='/member/<%= @draftTeamNo %>'><%= @draftTeamName %></a></p>
        <h1><%= @playerName %><%= @foreigner %></h1>
        <p><%= @playerPosition %></p>
        <p>生年月日：<%= @playerBirthday %></p>
        <p>年棒：<%= @salary %> 万円</p>
        <p>所属NPBチーム：<%= @npbTeamName %></p>
    </body>
</html>


@@draft
<!DOCTYPE html>
<html lang="ja">
    <head>
        <meta charset="utf-8">
        <title>追加指名登録</title>
        <style>body {padding: 30px;}</style>
    </head>
    <body>
      <p><a href='/'>ホーム</a></p>
      <h1><%= @teamName %></h1>
      <table border=1>
        <tr>
          <th>所属NPB球団</th>
          <th>背番号</th>
          <th>名前</th>
          <th>投</th>
          <th>打</th>
          <th>国籍</th>
          <th>守備位置</th>
          <th>指名ドラフトチーム</th>
          <th>解雇</th>
          <th>指名する</th>
        </tr>
        <% @results.each do |row| %>
          <tr>
            <% playerNo = '' %>
            <% row.each do |key, value| %>
              <% if key == "fireFlg" && value == 1 %>
                <%= "<td>解雇済み</td>" %>
              <% elsif key == "fireFlg" %>
                <%= "<td></td>" %>
              <% elsif key == "playerNo" %>
                <% playerNo = value %>
              <% elsif key == "playerName" %>
                <% if playerNo == '' %>
                  <%= "<td>#{value}</td>" %>
                <% else %>
                  <%= "<td><a href='/player/#{playerNo}'>#{value}</a></td>" %>
                <% end %>
              <% elsif key == "foreigner" %>
                <% if value == 1 %>
                  <%= "<td>外国人</td>" %>
                <% else %>
                  <%= "<td></td>" %>
                <% end %>
              <% else %>
                <%= "<td>#{value}</td>" %>
              <% end %>
            <% end %>
            <%= "<td><a href='/draft/#{@draftTeamNo}/#{playerNo}'>指名する</a></td>" %>
          </tr>
        <% end %>
      </table>
      <p><a href='/'>ホーム</a></p>
    </body>
</html>

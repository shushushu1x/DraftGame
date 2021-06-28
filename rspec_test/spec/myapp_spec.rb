# spec/app_spec.rb
require_relative '../lib/myapp'
require "date"
require File.expand_path '../spec_helper.rb', __FILE__

RSpec.describe "ドラフト支援" do
  it "ホームのページ" do
    get '/'
    expect(last_response).to be_ok
  end
  it "チームのページ" do
    get '/member/:draftTeamNo'
    expect(last_response).to be_ok
  end
  it "選手のページ" do
    get '/player/:playerNo'
    expect(last_response).to be_ok
  end
  it "ドラフト指名のページ" do
    get '/draft/:draftTeamNo'
    expect(last_response).to be_ok
  end
end


RSpec.describe Player do
  describe '#initialize' do
    it '菊池涼介「外国人登録」がヌルであること' do
      player = Player.new(199003111)
      expect(player.name).to eq '菊池　涼介'
      expect(player.position).to eq '内野手'
      birth = Date.new(1990,3,11)
      expect(player.birthday).to eq birth
      expect(player.salary).to eq 30000
      expect(player.draftTeamNo).to eq 1
      expect(player.draftTeamName).to eq 'レッドカピバラーズ'
      expect(player.npbTeamNo).to eq 11
      expect(player.npbTeamName).to eq '広島東洋カープ'
      expect(player.foreigner).to eq nil
    end
    it 'ベラルタ「外国人登録」が（外）であること' do
      player = Player.new(200108101)
      expect(player.name).to eq 'ホルヘ　ペラルタ'
      expect(player.position).to eq '外野手'
      birth = Date.new(2001,8,10)
      expect(player.birthday).to eq birth
      expect(player.salary).to eq 240
      expect(player.draftTeamNo).to eq nil
      expect(player.draftTeamName).to eq nil
      expect(player.npbTeamNo).to eq 2
      expect(player.npbTeamName).to eq '千葉ロッテマリーンズ'
      expect(player.foreigner).to eq '（外）'
    end
  end
  describe '#draft' do
    it 'ドラフト指名の新規登録' do
      draftTeamNo = 3
      client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
      sql = "SELECT MAX(ranking) maxRanking FROM draft_detail WHERE draftTeamNo = ?"
      statement = client.prepare(sql)
      results = statement.execute(draftTeamNo)
  
      results.each do |row|
        row.each do |key, value|
          if key == "maxRanking"
            @maxRanking = value
          end
        end    
      end
  
      player = Player.new(200108101)
      player.draft(3)
      player1 = Player.new(200108101)
      expect(player1.draftTeamNo).to eq 3
      expect(player1.draftTeamName).to eq '神戸ブライアント'
      expect(player1.ranking).to eq @maxRanking + 1 
      expect(player1.fireFlg).to eq 0 
    end
    it 'ドラフト指名の解雇登録' do
      player1 = Player.new(200108101)
      player1.fire()
      player2 = Player.new(200108101)
      expect(player2.fireFlg).to eq 1 
    end
    it 'ドラフト指名の削除' do
      player1 = Player.new(200108101)
      draftDetail1 = DraftDetail.new(player1.draftDetailNo)
      draftDetail1.delete()

      client = Mysql2::Client.new(host: "localhost", username: "root", password: '', database: 'bcup')
      sql = "SELECT no, playerNo, draftTeamNo, ranking, fireFlg FROM draft_detail WHERE no = ? "
      statement = client.prepare(sql)
      results = statement.execute(player1.draftDetailNo)
      expect(results.count).to eq 0
    end
  end
end


RSpec.describe DraftTeam do
  describe '#initialize' do
    it 'Noが1のデータは「レッドカピバラズ」であること' do
      draftTeam1 = DraftTeam.new(1)
      expect(draftTeam1.name).to eq 'レッドカピバラーズ'
      expect(draftTeam1.abbrName).to eq 'カピ'
    end
    it '存在しないデータの場合' do
      draftTeam2 = DraftTeam.new(111)
      expect(draftTeam2.name).to eq nil
      expect(draftTeam2.abbrName).to eq nil
    end
  end
end

RSpec.describe DraftDetail do
  describe '#initialize' do
    it 'Noが1のデータは佐野　恵太' do
      draftDetail1 = DraftDetail.new(1)
      expect(draftDetail1.playerNo).to eq '199411281'
      expect(draftDetail1.draftTeamNo).to eq 1
      expect(draftDetail1.ranking).to eq 4
      expect(draftDetail1.fireFlg).to eq 1
    end
    it '存在しないデータの場合' do
      draftDetail1 = DraftDetail.new(999)
      expect(draftDetail1.playerNo).to eq nil
      expect(draftDetail1.draftTeamNo).to eq nil
      expect(draftDetail1.ranking).to eq nil
      expect(draftDetail1.fireFlg).to eq nil
    end
  end
end
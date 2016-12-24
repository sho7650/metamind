#!/usr/bin/env ruby
# coding: utf-8
require 'json/jwt'
require 'rest-client'

Audience = 'https://api.metamind.io/v1/oauth2/token'

# 秘密鍵の読み込み: 事前に "CERT" 環境変数へファイル名を指定すること
private_file = File.open(ENV['CERT']).read
private_key  = OpenSSL::PKey::RSA.new(private_file)

# metamind を利用するための定義とtokenの有効期限
# "SUBJECT" 環境変数には、sign in した時のメールアドレスを指定すること
claim = {
  iss: 'developer.force.com',
  sub: ENV['SUBJECT'],
  aud: Audience,
  exp: 1.week.from_now,
  nbf: Time.now
}

# 秘密鍵から Json Web Sign を作成する
jws = JSON::JWT.new(claim).sign(private_key, :RS256).to_s

# metamind へログイン
begin
  res = RestClient.post(Audience, {grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion: jws})
rescue RestClient::ExceptionWithResponse => err
  err.response
end

# token 取得: token_type と access_token を組み合わせて認証済みTokenを構成
token         = JSON.parse(res.body)
expires_in    = token['expires_in']
authorization = token['token_type'] + " " + token['access_token']

# すべてのデータセットを取得
begin
  res = RestClient.get("https://api.metamind.io/v1/vision/datasets", {Authorization: authorization})
rescue RestClient::ExceptionWithResponse => err
  err.response
end

puts res

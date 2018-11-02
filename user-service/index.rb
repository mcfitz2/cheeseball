require 'rubygems'
require 'sinatra'
require 'mongo'
require 'json/ext' # required for .to_json
require 'bcrypt'
require 'jwt'
$stdout.sync = true
configure do
  db = Mongo::Client.new(ENV['MONGO_URL'])  
  set :bind, '0.0.0.0'

  set :mongo_db, db[:users]
  puts 'hello'
end
def hash_password(password)
  BCrypt::Password.create(password).to_s
end

def test_password(password, hash)
  BCrypt::Password.new(hash) == password
end
def token username
  JWT.encode payload(username), ENV['JWT_SECRET'], 'HS256'
end
helpers do
  def scope_check!
    puts env[:scopes]
    puts env[:user]
  def protected!
    begin
      options = { algorithm: 'HS256', iss: ENV['JWT_ISSUER'] }
      bearer = env.fetch('HTTP_AUTHORIZATION', '').slice(7..-1)
      payload, header = JWT.decode bearer, ENV['JWT_SECRET'], true, options
      puts "PAYLOAD", payload
      env[:scopes] = payload['scopes']
      env[:user] = payload['user']

    rescue JWT::DecodeError
      puts "need token"
      halt 401, { 'Content-Type' => 'text/plain' }, ['A token must be passed.']
    rescue JWT::ExpiredSignature
      puts "expired"
      halt 403, { 'Content-Type' => 'text/plain' }, ['The token has expired.']
    rescue JWT::InvalidIssuerError
      puts "bad issuer"
      halt 403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid issuer.']
    rescue JWT::InvalidIatError
      puts "bad issued time"
      halt 403, { 'Content-Type' => 'text/plain' }, ['The token does not have a valid "issued at" time.']
    end
  end
end

def payload user
  {
    exp: Time.now.to_i + 60 * 60,
    iat: Time.now.to_i,
    iss: ENV['JWT_ISSUER'],
    user: {
      username: user.username
      id: user._id
    }
  }
end

get '/users' do
  protected!
  scope_check!
  user = request.env.values_at :user
  puts user
  content_type :json
  settings.mongo_db.find(params).to_a.to_json
end

post '/users' do
  protected!
  content_type :json
  db = settings.mongo_db
  payload = JSON.parse(request.body.read).symbolize_keys
  result = db.insert_one payload
  db.find(:_id => result.inserted_id).to_a.first.to_json
end
get '/users/:user_id'  do
  protected! 
  content_type :json
  db = settings.mongo_db
  db.find(:id => params[:user_id]).to_a.to_json
end
patch '/users/:user_id' do
  protected!
  content_type :json
  id = BSON::ObjectId.from_string(params[:user_id])
  payload = JSON.parse(request.body.read).symbolize_keys
  settings.mongo_db.find(:_id => id).
  find_one_and_update('$set' => payload)
  200
end
delete '/users/:user_id' do
  protected!
  content_type :json
  id = BSON::ObjectId.from_string(params[:user_id])
  documents = db.find(:_id => id)
  if !documents.to_a.first.nil?
    documents.find_one_and_delete
    {:success => true}.to_json
  else
    {:success => false}.to_json
  end
end

post '/users/:user_id/password' do
  protected!
  content_type :json
  new_password = hash_password(params[:password])
  id = BSON::ObjectId.from_string(params[:user_id])
  settings.mongo_db.find_one_and_update({:_id => id}, {'$set' => { :password => new_password }}, :return_document => :after).to_json  
end
post '/authenticate' do 
	username = params[:username]
	password = params[:password]
	user = settings.mongo_db.find(:username => username).limit(1).first
	if test_password(password, user[:password])
		{ token: token(user) }.to_json
	else
		halt 401
	end
end

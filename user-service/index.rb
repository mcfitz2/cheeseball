require 'rubygems'
require 'sinatra'
require 'mongo'
require 'json/ext' # required for .to_json
require 'bcrypt'

configure do
  db = Mongo::Client.new(ENV['MONGO_URL'])  
  set :mongo_db, db[:users]
#  enable :logging
  puts 'hello'
end
def hash_password(password)
  BCrypt::Password.create(password).to_s
end

def test_password(password, hash)
  BCrypt::Password.new(hash) == password
end


get '/users' do
  content_type :json
  settings.mongo_db.find.to_a.to_json
end

post '/users' do
  content_type :json
  db = settings.mongo_db
  payload = JSON.parse(request.body.read).symbolize_keys
  result = db.insert_one payload
  db.find(:_id => result.inserted_id).to_a.first.to_json
end
get '/users/:user_id'  do 
  content_type :json
  db = settings.mongo_db
  db.find(:id => params[:user_id]).to_a.to_json
end
patch '/users/:user_id' do
  content_type :json
  id = BSON::ObjectId.from_string(params[:user_id])
  payload = JSON.parse(request.body.read).symbolize_keys
  settings.mongo_db.find(:_id => id).
  find_one_and_update('$set' => payload)
  200
end
get '/users/search' do 
  content_type :json
  db = settings.mongo_db
  db.find(params).to_a.to_json
  'HELP'
end
delete '/users/:user_id' do
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
  content_type :json
  new_password = hash_password(params[:password])
  id = BSON::ObjectId.from_string(params[:user_id])
  settings.mongo_db.find_one_and_update({:_id => id}, {'$set' => { :password => new_password }}, :return_document => :after).to_json
  200  
end
post '/authenticate' do 
	username = params[:username]
	password = params[:password]
	user = settings.mongo_db.find(:username => username).limit(1).first
	puts username, password, user
	if test_password(password, user[:password])
		user.to_json
	else
		400
	end
end

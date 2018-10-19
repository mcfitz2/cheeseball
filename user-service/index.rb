require 'rubygems'
require 'sinatra'
require 'mongo'
require 'json/ext' # required for .to_json
configure do
  db = Mongo::Client.new(ENV['MONGO_URL'])  
  set :mongo_db, db[:users]
  puts 'hello'
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

patch '/users/:user_id' do
  content_type :json
  id = object_id(params[:user_id])
  payload = JSON.parse(request.body.read).symbolize_keys
  settings.mongo_db.find(:_id => id).
    find_one_and_update('$set' => payload)
  document_by_id(id)
end

delete '/users/:user_id' do
  content_type :json
  id = object_id(params[:user_id])
  documents = db.find(:_id => id)
  if !documents.to_a.first.nil?
    documents.find_one_and_delete
    {:success => true}.to_json
  else
    {:success => false}.to_json
  end
end

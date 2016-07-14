require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'super secret'
end

helpers do
  def calc_total(money)
    total_income = 0

    unless money == nil
      money.each_value do |dollars|
        total_income += dollars.to_i
      end
    end 
    total_income
  end
end

def user_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data", __FILE__)
  else
    File.expand_path("../users.yml", __FILE__)
  end
end

def users_database
  YAML.load_file(user_path) || {}
end

def valid_credentials?(username, password)
  credentials = load_user_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == password
  else
    false
  end
end

def signed_in?
  session.key?(:username)
end

def signin_required
  unless signed_in?
    session[:message] = "You must sign in first." 
    redirect "/"
  end
end

def valid_password?(password, verify_password)
  password == verify_password
end

def add_user(new_user)
  File.open(user_path, 'a+') { |file| file.write new_user.to_yaml }
end

def user_signup(username, password, verify_password)
  new_user = users_database

  if valid_credentials(username, password)
    session[:message] = "That username is already taken."
  elsif !valid_password(password, verify_password)
    session[:message] = "Passwords do not match"
  else
    new_user[params[:username]] = BCrypt::Password.create(params[:password])
    add_user(new_user)
  end
end

get '/' do    
  erb :home
end

get '/expendable' do
  erb :expendable
end

post '/expendable' do
  @income = calc_total(params[:income])
  @expenses = calc_total(params[:bills])
  @expendable_income = @income - @expenses 
  erb :expendable, layout: :layout
end

get '/mortgage' do
  erb :mortgage
end

post '/mortgage' do
  @income = calc_total(params[:income])
  @expenses = calc_total(params[:bills])
  @mortgage = (((@income * 0.44) - @expenses) * 360).to_i
  erb :mortgage
end

get '/users/login' do
  erb :login
end

post '/users/login' do
  username = params[:username]

  if valid_credentials?(username, params[:password])
    session[:username] = username
    session[:message] = "Welcome #{username}!"
    redirect "/"
  else
    session[:message] = "Invalid Username/Password"
    status 422
    erb :login
  end
end

get '/users/signup' do
  erb :signup
end

post '/users/signup' do
  new_user = users_database
  username = params[:username]
  password = params[:password]
  verify_password = params[:verify_password]
  
  if valid_credentials?(username, password)
    session[:message] = "That username is already taken."
    erb :signup
  elsif !valid_password?(password, verify_password)
    session[:message] = "Passwords do not match."
    erb :signup
  else
    new_password = BCrypt::Password.create(password)
    new_user[params[:username]] = new_password
    add_user(new_user)
    session[:message] = "Congrats #{username}!"
    redirect '/'
  end
end

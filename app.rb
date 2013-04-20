require_relative './models/Users.rb'

require 'rubygems'
require 'sinatra'
require 'data_mapper'


require 'active_support/all'



enable :sessions

 if ENV['VCAP_SERVICES'].nil?
     DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/database.db")
   else
     require 'json'
     svcs = JSON.parse ENV['VCAP_SERVICES']
     mysql = svcs.detect { |k,v| k =~ /^mysql/ }.last.first
     creds = mysql['credentials']
     user, pass, host, name = %w(user password host name).map { |key| creds[key] }
     DataMapper.setup(:default, "mysql://#{user}:#{pass}@#{host}/#{name}")
   end

DataMapper::Property.required(true)


helpers do
	def logged_in?
		if session[:user]
			true
		else
			false
		end
	end

	def generate_salt
		rng = Random.new
		Array.new(User.salt.length){ rng.rand(33...126).chr }.join
	end

	#Flash helper based on the one from here:
	#https://github.com/daddz/sinatra-dm-login/blob/master/helpers/sinatra.rb
	def show_flash(key)
		if session[key]
			flash = session[key]
			session[key] = false
			flash
		end
	end
end



get "/" do
	if logged_in?
		@user = User.first(:hashed_password => session[:user])
    redirect "/home"
	end
	erb :index
    
end

get "/login" do
    erb :login
end

get "/home" do
    @name = User.first(:name)
    puts @name
    
    if logged_in?
		@user = User.first(:hashed_password => session[:user])
        erb :home
	else
    
    halt 404, "ERROR, YOUR NOT LOGGED IN"
    end
end

get "/chat/:user" do
    @user = params[:user]
    erb :chat
    
end

post "/email" do
    to_mail = params[:to]
    message = params[:message]
    time = params[:time]
    type = params[:type]
    
    puts to_mail
    time = time.to_i
    
    case type
        when "Seconds"
           Resque.enqueue_in(time.seconds, Email, to_mail, message)
        when "Minutes"
          #type = "m"
           Resque.enqueue_in(time.minutes, Email,to_mail, message)
        when "Hours"
          #type = "h"
           Resque.enqueue_in(time.hours, Email,to_mail, message)
        when "Days"
          #type = "d"
           Resque.enqueue_in(time.days, Email,to_mail, message)
        when "Years"
          #type = "yr"
           Resque.enqueue_in(time.years, Email,to_mail, message)
        else
          puts "You gave me #{type} -- I have no idea what to do with that."
    end

    redirect "/home"
    
end



post "/login" do
	user = User.first(:email => params[:email])

	if !user
		session[:flash] = "User doesn't exist"
		redirect "/login"
	end

	authenticated = user.authenticate(params[:password])

	if authenticated
		user.last_login_time = user.current_login_time
		user.last_login_ip = user.current_login_ip
		user.current_login_time = DateTime.now
		user.current_login_ip = request.ip
		if user.save
			session[:user] = user.hashed_password
		else
			session[:flash] = "There was an error logging in, please try again"
		end
	else
		session[:flash] = "Incorrect Password"
	end

	redirect "/home"
end




post "/user/logout" do
	session[:user] = nil
	session[:flash] = "You have logged out successfully"
	redirect "/"
end





get "/signup" do
	erb :signup
end



post "/user/create" do
	user = User.first(:email => params[:email])
    
    
	if user
		session[:flash] = "That username has been taken"
		redirect "/signup"
	end

	if !params[:password].eql?(params[:password2])
		session[:flash] = "You entered two different passwords"
		redirect "/signup"
	end

	salt = generate_salt
	hashed_password = hash_password(params[:password], salt)
	user = User.new(
		:name => params[:name],
        :email => params[:email],
		:salt => salt,
		:hashed_password => hashed_password,
		:current_login_time => Time.now,
		:current_login_ip => request.ip
	)

	if user.save
		session[:flash] = "Signed up successfully"
		session[:user] = user.hashed_password
		redirect "/"
	else
		session[:flash] = "Signup failed, please try again"
		redirect "/"
	end

	#also check to make sure password is a certain length, contains an uppercase character, number, lowercase letter etc.
end

DataMapper.auto_upgrade!



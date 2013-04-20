require 'data_mapper'


#hack - this has to be above the model definition to work
#if this isn't in a module then the User class can't use the helper method
module PasswordHasher
	def hash_password(password, salt)
		Digest::SHA2.hexdigest(password+salt)
	end
end

include PasswordHasher

class User
	include DataMapper::Resource
	include PasswordHasher

	property :id, Serial
	property :name, String
    property :email, String
	property :salt, String, :length => 32
	property :hashed_password, String, :length => 64
	property :last_login_time, DateTime, :required => false
	property :last_login_ip, String, :required => false
	property :current_login_time, DateTime
	property :current_login_ip, String

	#require dm/validations
	#validates_uniqueness_of :name, :message => "That username has already been taken"
	#validates_length_of :name, :min => 1, :max => 16, :message => "Username must be between 1 and 16 characters"
	#validates

	def authenticate(password)
		if (hash_password(password, salt)).eql?(hashed_password)
			true
		else
			false
		end
	end

    
end

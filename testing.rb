require 'sinatra/base'
require 'json'

class MyApp < Sinatra::Base
    
    get "/" do
        
        file = open("./images.json")
        json = file.read
    
        @parsed = JSON.parse(json)

        erb :roar
        
        #@parsed.each do |shop|
        #  p shop["url"]
        #end
        
    end
end

MyApp.run!

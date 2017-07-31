require 'sinatra'
require 'sinatra/reloader'
require 'yaml'
require 'date'

configure do
  enable :sessions
end

helpers do
  def status(arrival_time)
    parsed_time = DateTime.strptime(arrival_time, "%M:%S")
    if DateTime.now > parsed_time
      "Arrived"
    else
      "On the way"
    end
  end
end

def flights
  path = File.expand_path("../flights.yml", __FILE__)
  YAML.load_file(path)
end

get "/" do
  @flights = flights
  erb :index
end

get "/:flight_number" do
  @flight_number = params[:flight_number]
  if flights.key?(@flight_number)
    @flight_info = flights[@flight_number]
  else
    session[:message] = "Please enter a valid flight number"
    redirect "/"
  end
  erb :view
end
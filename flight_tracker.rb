require 'sinatra'
require 'sinatra/reloader'
require 'yaml'
require 'date'

configure do
  enable :sessions
end

helpers do
  def arrival_status(arrival_time)
    if Time.parse(arrival_time) < Time.now
      "On the air"
    else
      "Arrived"
    end
  end

  def main_info(flight_info)
    flight_info.select{|key, value| main_fields.include? key}
  end
end

def main_fields
  ['Airline', 'From', 'Schedule', 'Gate']
end

def flights
  path = File.expand_path("../flights.yml", __FILE__)
  YAML.load_file(path)
end

get "/" do
  if params[:search]
    if flights.key? params[:search]
      @flights = flights.select{|key, value|key == params[:search]}
    else
      session[:message] = "Please enter a valid flight number."
      redirect "/"
    end
  else
    @flights = flights
  end
  erb :index
end

get "/:flight_number" do
  @flight_number = params[:flight_number]
  if flights.key?(@flight_number)
    @flight_info = flights[@flight_number]
    erb :view
  else
    session[:message] = "Please enter a valid flight number."
    redirect "/"
  end
end
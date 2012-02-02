require 'sinatra'
require 'sequel'
require 'json'
require 'logger'
require 'nokogiri'
require 'yaml'

CONFIG = YAML::load_file 'config.yml'
DB = Sequel.connect CONFIG['database']

class BostonRubyists < Sinatra::Base
  set :static, true
  set :root, File.dirname(__FILE__)

  helpers {
    def prep(p)
      p[:date_string] = p[:date].strftime("%b %d %I:%M %p")
      if p[:content] 
        # strip Github dates because they are redundant
        p[:content] = p[:content].sub(/\w+ \d+, \d{4}/, '')
      end
      p
    end

    def prep_tweet t
    end

    def page_title
      CONFIG['page_title']
    end

    def org
      CONFIG['org']
    end

    def poll_interval
      CONFIG['poll_interval'] * 1000
    end
  }

  get('/') {
    @hackers = DB[:hackers].order(:followers.desc).to_a
    @updates = DB[:updates].order(:date.desc).limit(110).map {|u| prep u}
    @tweets = DB[:tweets].order(:created_at.desc).limit(200).map {|t| prep_tweet t}
    @blog_posts = DB[:blog_posts].order(:date.desc).limit(90).map {|p| prep p}
    erb :index 
  }

  get('/updates') {
    ds = DB[:updates].order(:date.desc).filter("date > ?", params[:from_time])
    puts "returning #{ds.count} results"
    @updates = ds.map {|u| prep u}
    @updates.to_json
  }
  get('/blog_posts') {
    ds = DB[:blog_posts].order(:date.desc).filter("date > ?", params[:from_time])
    puts "returning #{ds.count} results"
    @blog_posts = ds.map {|p| prep p}
    @blog_posts.to_json
  }

  run! if app_file == $0
end

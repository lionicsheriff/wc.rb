#!/usr/bin/env ruby
require 'sqlite3'
require 'date'

DB_NAME = 'wc.db'
db = SQLite3::Database.new(DB_NAME)

db.execute_batch <<-SQL

  CREATE TABLE IF NOT EXISTS word_count (
    id integer primary key,
    path string,
    words integer,
    timestamp integer,
    UNIQUE (path, timestamp)
  );

SQL

today = {} # used to store the changes for today (path => {today => int, total => int})

Dir.glob('**') do | file |
  path = File.absolute_path(file)
  next if path == File.absolute_path(DB_NAME) || path == File.absolute_path(__FILE__)
  words = `wc -w #{file}`.split(' ')[0]
  timestamp = Time.now.getutc.to_i

  last_word_count = db.execute <<-SQL

    SELECT words
    FROM word_count
    WHERE path = '#{path}'
    ORDER BY timestamp DESC
    LIMIT 1,1

  SQL

  if last_word_count.size == 0 or last_word_count[0][0].to_i != words.to_i then

    db.execute_batch <<-SQL

      INSERT  INTO word_count (path, words, timestamp) 
      VALUES ('#{path}', '#{words}', '#{timestamp}');

    SQL

  end



  prev_day = db.execute <<-SQL

    SELECT max(words)
    FROM word_count
    WHERE path = '#{path}'
    AND timestamp < '#{Date.today.to_time.getutc.to_i}'
    GROUP BY path,date(timestamp, 'unixepoch')
    ORDER BY timestamp desc
    LIMIT 1

  SQL


  prev_day_words = prev_day.size > 0 ? prev_day[0][0].to_i : 0
  todays_words = words.to_i - prev_day_words.to_i

  if todays_words > 0 then
    today[path] = {:today => todays_words, :total => words.to_i}
  end
  
end

total = today.values.map { |f| f[:today] }.reduce(0, :+)

puts "Today: #{total}"
puts
today.each do |path, words|
  puts "#{path}: #{words[:today]} (#{words[:total]})"
end


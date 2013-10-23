#!/usr/bin/env ruby
require 'sqlite3'
require 'date'
require 'optparse'

CONFIG = {
  :summary_format => "%{today}",
  :header_format => "Today: %{today}",
  :item_format => "%{path}: %{today} (%{total})",
  :remaining_summary_format => "(%{remaining})",
  :remaining_full_format => ", %{remaining} words left"
}

OptionParser.new do |o|
  o.separator ""
  
  o.on('-s') { CONFIG[:summary] = true }
  o.on('-b PATH') { |path| CONFIG[:base] = path }
  o.on('-d NAME') { |name| CONFIG[:dbname] = name }
  o.on('-g GOAL') { |goal| CONFIG[:goal] = goal }

  o.separator ""
  o.on('--summary-format FORMAT') {|format| CONFIG[:summary_format] = format }
  o.on('--header-format FORMAT') {|format| CONFIG[:header_format] = format }
  o.on('--item-format FORMAT') {|format| CONFIG[:item_format] = format }
  o.on('--remaining_summary_format FORMAT') {|format| CONFIG[:remaining_summary_format] = format }
  o.on('--remaining_full_format FORMAT') {|format| CONFIG[:remaining_full_format] = format }

  o.separator ""
  o.on('--on-update SCRIPT') { |script| CONFIG[:update_hook] = script}
  o.on('-h') { puts o; exit }
  
  o.parse!
end

BASE = CONFIG[:base] || "."
DB_NAME = "#{BASE}/" + ( CONFIG[:dbname] || 'wc.db' )

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

Dir.glob("#{BASE}/**") do | file |
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

  prev_day = db.execute <<-SQL

    SELECT words
    FROM word_count
    WHERE path = '#{path}'
    AND timestamp < '#{Date.today.to_time.getutc.to_i}'
    ORDER BY timestamp desc
    LIMIT 1

  SQL

  prev_day_words = prev_day.size > 0 ? prev_day[0][0].to_i : 0
  todays_words = words.to_i - prev_day_words.to_i

  if last_word_count.size == 0 or last_word_count[0][0].to_i != words.to_i then

    db.execute_batch <<-SQL

      INSERT  INTO word_count (path, words, timestamp) 
      VALUES ('#{path}', '#{words}', '#{timestamp}');

    SQL
    
    if CONFIG[:update_hook]
      `"#{CONFIG[:update_hook]}" "#{path}" "#{words}" "#{prev_day_words}"`
    end

  end

  if todays_words > 0 then
    today[path] = {:today => todays_words, :total => words.to_i}
  end
  
end

total = today.values.map { |f| f[:today] }.reduce(0, :+)
remaining = if CONFIG[:goal]
              CONFIG[:goal] - today
            end
  

if CONFIG[:summary]
  goal_message = remaining ? CONFIG[:remaining_summary_format] % {:remaining => remaining}: ""
  puts (CONFIG[:summary_format] % {:today => total}) + goal_message
else
  goal_message = remaining ? CONFIG[:remaining_summary_format] % {:remaining => remaining}: ""
  puts (CONFIG[:header_format] % {:today => total}) + goal_message
  puts
  today.each do |path, words|
    puts CONFIG[:item_format] % {:path => path, :today => today, :total => total}
  end
end

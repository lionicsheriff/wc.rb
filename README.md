What
====

wc-db monitors a directory (and its children) and records the number of words i
n each file.

Why
===

As a part of my daily writing goal, I thought it would be amusing to track my activity.

How
===

wc-db opens every file in a directory and counts the words. If it gets a different number than the previous time,
it stores the new count into a database. I personally run it ever second either with "watch -n 1" or in xmobar.


Usage
=====

    -s, --summary

Only show the totals for the directory, not the individual files. 
Suitable for using as a widget (e.g. in xmobar or a shell prompt)

    -b, --base PATH

The directory to monitor
    
    -d, --database NAME
    
The name of the database. Defaults to wc.db
    
    -g, --goal GOAL
    
An optional daily goal. Based of the total words across all documents
    
    -i, --ignore-regexp PATTERN
    
Lines that match the ignore-regexp pattern are not included in the word count. This allows you to comment out lines
and not have them count towards your word count. Defaults to /^\s*(#|\*)/ aka lines that start with # or *. 

DEPRECATION NOTICE: Will be left blank in later releases (i.e. include all lines in the word cound by default)

Formatting output
-----------------

        --summary-format FORMAT
        
Format string to use in summary mode.

Variables:

 * today: total number of words added today
        
        --goal-summary-format FORMAT
        
Format string used to show the progress towards the daily goal. Appended to the end of the summary.

Variables:

 * remaining: the number of words you have left for the day
  
        
        --header-format FORMAT
        
Format string to use for the heading in full output.

Variables:

 * today: total number of words added today
 
        --goal-full-format FORMAT

Format string used to show the progress towards the daily goal. Appended to the end of the header

Variables:

 * remaining: the number of words you have left for the day
        
        --item-format FORMAT
        
Format string for the individual document

Variables:

 * path: path to the document
 * today: total number of words added today
 * total: total number of words in the document



Hooks
-----

        --on-update SCRIPT

Path to a shell script/command to run whenever a document has been updated. Passes three arguments: path, word count,
and the previous days word count.

This runs individually for each document as its word count changes, so if you only care about one document you will
want to test the path.

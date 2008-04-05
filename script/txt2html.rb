#!/usr/bin/env ruby

require 'rubygems'
require 'redcloth'
require 'syntax/convertors/html'
require 'erb'

class Fixnum
  def ordinal
    # teens
    return 'th' if (10..19).include?(self % 100)
    # others
    case self % 10
    when 1: return 'st'
    when 2: return 'nd'
    when 3: return 'rd'
    else    return 'th'
    end
  end
end

class Time
  def pretty
    return "#{mday}#{mday.ordinal} #{strftime('%B')} #{year}"
  end
end

module Txt2Html
  def convert_syntax(syntax, source)
    return Syntax::Convertors::HTML.for_syntax(syntax).convert(source).gsub(%r!^<pre>|</pre>$!,'')
  end

  require File.dirname(__FILE__) + '/../lib/newgem/version.rb'

  version  = Newgem::VERSION::STRING
  download = ENV['HOMEPAGE']

  if ARGV.length >= 1
    src, template = ARGV
    template ||= File.dirname(__FILE__) + '/../website/template.html.erb'

  else
    puts("Usage: #{File.split($0).last} source.txt [template.html.erb] > output.html")
    exit!
  end

  template = ERB.new(File.open(template).read)

  title = nil
  body = nil
  File.open(src) do |fsrc|
    title_text = fsrc.readline
    body_text = fsrc.read
    syntax_items = []
    body_text.gsub!(%r!<(pre|code)[^>]*?syntax=['"]([^'"]+)[^>]*>(.*?)</\1>!m){
      ident = syntax_items.length
      element, syntax, source = $1, $2, $3
      syntax_items << "<#{element} class=\"syntax\">#{convert_syntax(syntax, source)}</#{element}>"
      "syntax-temp-#{ident}"
    }
    title = RedCloth.new(title_text).to_html.gsub(%r!<.*?>!,'').strip
    body = RedCloth.new(body_text).to_html
    body.gsub!(%r!(?:<pre><code>)?syntax-temp-(\d+)(?:</code></pre>)?!){ syntax_items[$1.to_i] }
  end
  stat = File.stat(src)
  created = stat.ctime
  modified = stat.mtime

  $stdout << template.result(binding)
end
$:.unshift './'
require 'logger'
require 'rubygems'
require 'active_support/all'

module Parser

#  def self.log
#    l ||= Logger.new('./log/parser.log')
#  end

  def from_api(str)
    hs = {}
    ip_check = false
    if is_xml?
      hs = Hash.from_xml(str.gsub(/type="datetime"/,'type="text"').gsub(/type="symbol"/,'type="text"'))
#      str.split("\n").each do |x|
#        ip_check = true if x.include?("<ip_addresses")
#        if x[/<\w/] && (ip_check ^ !x.include?("<address>"))
#          hs[(x.gsub(/^.*<\/|^.*</, "").gsub(/>.*$/, "")).to_sym] = x.gsub(/<\/.*$/, "").gsub(/^.*>/, "") if hs[(x.gsub(/^.*<\/|^.*</, "").gsub(/>.*$/, "")).to_sym].nil?
#        end
#        ip_check = false if x.include?("</ip_addresses")
#      end
    elsif is_json?
      hs = ActiveSupport::JSON.decode(str.split("\n").last)
#      str.split("\n").last.split(",").each do |x|
#        ip_check = true if x.include?("ip_addresses")
#        if ip_check ^ !x.include?("address")
#          hs[(x.gsub(/^.*\{/,"").gsub(/:.*$/,"").gsub(/\"/,"")).to_sym] = x.gsub(/^.*:/,"").gsub(/\}.*$/,"").gsub(/\"/,"") if hs[(x.gsub(/^.*\{/,"").gsub(/:.*$/,"")).to_sym].nil?
#        end
#        ip_check = false if x.include?("}}]")
#      end
    else
      raise("Wrong API type (xml/json)")
    end

    if hs.kind_of?(Hash)
      hs.symbolize_keys!
      if (hs.keys.count == 1)
        hs = hs[hs.keys.first]
        hs.symbolize_keys! if hs.kind_of?(Hash)
      end
    else
      if (hs.index.count == 1)
        hs = hs.first unless hs.kind_of?(String)
        hs.symbolize_keys! if hs.kind_of?(Hash)
      end
    end
#    hs.each_key { |x| hs.delete(x) if hs[x].empty? }
#    Parser::log.info(hs)
    hs
  end

  def to_api(hs)
    str = ""
    if is_xml?
      hs.each_key do |x|
        str += "<"+x.to_s+">"+hs[x]+"<\/"+x.to_s+">"
      end
    elsif is_json?
      str += "{"
      hs.each_key do |x|
        if hs[x].class == String and hs[x].include?("{") or hs[x].class == Array
          str += "\"#{x.to_s}\":#{hs[x]},"
        else
          str += "\"#{x.to_s}\":\"#{hs[x]}\","
        end
      end
      str.sub!(/\,$/,"}")
    else
      raise("Wrong API type (xml/json)")
    end
#    Parser::log.info(str)
    str
  end

  def to_split(str)
    if is_xml?
      str="<#{str}>"
    elsif is_json?
      str="{\"#{str}\":"
    else
      raise("Wrong API type (xml/json)")
    end
#    Parser::log.info(str)
    str
  end

  def is_xml?
    !!($cp.api_type == "xml")
  end

  def is_json?
    !!($cp.api_type == "json")
  end

  def get_hash_with_split(result, splitting_value)
    result = result.split(to_split(splitting_value))
    required_hash = {}
    result.shift
    unless result.empty?
      result.last.gsub!(/\]$/, "") if is_json?
      result.last.sub!(/\<\/#{splitting_value}\>\n.*$/, to_split(splitting_value).sub(/</,"</")) if is_xml?
      result.each do |rs|
        rs.sub!(/,$/, "") if is_json?
        rs.sub!(/^/, to_split(splitting_value))
        hash = from_api(rs)
        required_hash[hash[:id]] = hash
      end
    end
    required_hash
  end
  
  def stamp
    Array.new(12){rand(36).to_s(36)}.join
  end
end


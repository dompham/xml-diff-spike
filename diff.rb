# frozen_string_literal: true
# require 'rubygems'
require 'byebug'
require 'hashdiff'
require 'nori'
require 'deepsort'
require 'colorize'

class CompareXml
  IMPORT_PATH = 'lib/import.xml'
  EXPORT_PATH = 'lib/export.xml'

  attr_accessor :import_doc, :export_doc, :res, :nori
  def initialize
    @nori = Nori.new
    @unequal_children_info = []
    @import_doc = File.read(IMPORT_PATH)
    @export_doc = File.read(EXPORT_PATH)
  end

  def self.compare
    new().compare
  end

  def compare
    # This can be xml partials, if needed
    imp_hsh = xml_str_to_map(@import_doc)
    exp_hsh = xml_str_to_map(@export_doc)
    diff = ::Hashdiff.diff(imp_hsh, exp_hsh) do |path, imp_obj, exp_obj|
      # Add custom diff conditions here
      if imp_obj.class == Array && exp_obj.class == Array
        if imp_obj.length != exp_obj.length
          puts path
          # Uncomment psuedo short circuiting when we handle unequal children
          # see readme
          @unequal_children_info << {
            path: path,
            import_obj: imp_obj,
            export_obj: exp_obj
          }
          # true
        end
      end
    end
    process_output(diff)
  end

  def xml_str_to_map(xml_s)
    # deep sort to ignore order on children
    nori.parse(xml_s).deep_sort
  end

  def process_output(diffs)
    # diff is a list of logged diffs
    # logged diff syntax = [sym, path, val]
    # The path can allow us to pass in a verbose flag
    # ex registryDocument.patient.followup[0].section.section[12].element[1].value.@value
    # becomes imp_hsh['registryDocument']['patient']['followup'][0]['section']['section'][12]['element'][1]['value']
    diffs.each do |diff|
      flag, path, expected, got = diff
      puts '------------------------------------------------'
      puts "Path: #{path}"
      case flag
      when '~'
        puts "Diff occurence - Expected:"
        puts "#{expected}".yellow
        puts "Got:"
        puts "#{got}".yellow
      when '+'
        puts "Extra element in export:"
        puts "#{expected}".green
      when '-'
        puts "Missing from export:"
        puts "#{expected}".red
      else
        puts "Serious issues have occurred"
      end
    puts '------------------------------------------------'
    end
    puts 'All gucci' if diffs.empty?
  end
end

puts 'Trying to compare XML'
CompareXml.compare

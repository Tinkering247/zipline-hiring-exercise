#!/usr/bin/env ruby
# frozen_string_literal: true

require 'csv'
require 'set'

# Union-Find data structure for efficient grouping
class UnionFind
  def initialize
    @parent = {}
    @rank = {}
  end

  def find(x)
    @parent[x] ||= x
    return x if @parent[x] == x

    @parent[x] = find(@parent[x]) # Path compression
  end

  def union(x, y)
    root_x = find(x)
    root_y = find(y)
    return if root_x == root_y

    # Union by rank
    @rank[root_x] ||= 0
    @rank[root_y] ||= 0

    if @rank[root_x] < @rank[root_y]
      @parent[root_x] = root_y
    elsif @rank[root_x] > @rank[root_y]
      @parent[root_y] = root_x
    else
      @parent[root_y] = root_x
      @rank[root_x] += 1
    end
  end

  def groups
    @parent.keys.group_by { |x| find(x) }
  end
end

# Base class for matching strategies
class MatchingStrategy
  def initialize(headers)
    @headers = headers
  end

  def extract_keys(row)
    raise NotImplementedError, 'Subclasses must implement extract_keys'
  end

  def normalize_phone(phone)
    return nil if phone.nil? || phone.strip.empty?

    # Extract only digits from phone number
    digits = phone.gsub(/\D/, '')
    digits.empty? ? nil : digits
  end

  def normalize_email(email)
    return nil if email.nil? || email.strip.empty?

    email.strip.downcase
  end
end

# Strategy: Match by same email address
class EmailMatchingStrategy < MatchingStrategy
  def extract_keys(row)
    keys = []

    @headers.each_with_index do |header, idx|
      if header =~ /email/i
        email = normalize_email(row[idx])
        keys << "email:#{email}" if email
      end
    end

    keys
  end
end

# Strategy: Match by same phone number
class PhoneMatchingStrategy < MatchingStrategy
  def extract_keys(row)
    keys = []

    @headers.each_with_index do |header, idx|
      if header =~ /phone/i
        phone = normalize_phone(row[idx])
        keys << "phone:#{phone}" if phone
      end
    end

    keys
  end
end

# Strategy: Match by same email OR same phone
class EmailOrPhoneMatchingStrategy < MatchingStrategy
  def extract_keys(row)
    keys = []

    @headers.each_with_index do |header, idx|
      if header =~ /email/i
        email = normalize_email(row[idx])
        keys << "email:#{email}" if email
      elsif header =~ /phone/i
        phone = normalize_phone(row[idx])
        keys << "phone:#{phone}" if phone
      end
    end

    keys
  end
end

# Main grouper class
class CSVGrouper
  STRATEGIES = {
    'email' => EmailMatchingStrategy,
    'phone' => PhoneMatchingStrategy,
    'email_or_phone' => EmailOrPhoneMatchingStrategy
  }.freeze

  def initialize(input_file, matching_type)
    @input_file = input_file
    @matching_type = matching_type
    validate_inputs!
  end

  def process
    csv_data = CSV.read(@input_file, headers: false)
    return [] if csv_data.empty?

    headers = csv_data[0]
    rows = csv_data[1..-1] || []

    strategy = create_strategy(headers)
    groups = build_groups(rows, strategy)
    assign_group_ids(rows, groups, headers)
  end

  private

  def validate_inputs!
    raise ArgumentError, "File not found: #{@input_file}" unless File.exist?(@input_file)
    raise ArgumentError, "Invalid matching type: #{@matching_type}" unless STRATEGIES.key?(@matching_type)
  end

  def create_strategy(headers)
    STRATEGIES[@matching_type].new(headers)
  end

  def build_groups(rows, strategy)
    uf = UnionFind.new
    key_to_rows = Hash.new { |h, k| h[k] = [] }

    # Map each identifying key to rows
    rows.each_with_index do |row, idx|
      keys = strategy.extract_keys(row)
      keys.each do |key|
        key_to_rows[key] << idx
      end
    end

    # Union rows that share any key
    key_to_rows.each_value do |row_indices|
      next if row_indices.size < 2

      first = row_indices.first
      row_indices[1..-1].each do |idx|
        uf.union(first, idx)
      end
    end

    # Ensure all rows have a group (even singles)
    rows.each_index { |idx| uf.find(idx) }

    uf.groups
  end

  def assign_group_ids(rows, groups, headers)
    row_to_group_id = {}

    groups.each_with_index do |(_, indices), group_num|
      indices.each do |idx|
        row_to_group_id[idx] = group_num + 1
      end
    end

    # Build output with PersonID prepended
    output = []
    output << ['PersonID'] + headers

    rows.each_with_index do |row, idx|
      group_id = row_to_group_id[idx]
      output << [group_id] + row
    end

    output
  end
end

# CLI Interface
if __FILE__ == $PROGRAM_NAME
  if ARGV.length != 2
    puts "Usage: #{$PROGRAM_NAME} <input_file> <matching_type>"
    puts "\nMatching types:"
    puts "  email           - Match records with the same email address"
    puts "  phone           - Match records with the same phone number"
    puts "  email_or_phone  - Match records with the same email OR phone"
    exit 1
  end

  input_file, matching_type = ARGV

  begin
    grouper = CSVGrouper.new(input_file, matching_type)
    result = grouper.process

    # Output to STDOUT
    result.each do |row|
      puts row.to_csv
    end
  rescue StandardError => e
    warn "Error: #{e.message}"
    exit 1
  end
end

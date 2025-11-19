#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'tempfile'
require 'csv'
require_relative 'grouper'

class TestUnionFind < Minitest::Test
  def setup
    @uf = UnionFind.new
  end

  def test_find_returns_self_for_new_element
    assert_equal 1, @uf.find(1)
  end

  def test_union_connects_two_elements
    @uf.union(1, 2)
    assert_equal @uf.find(1), @uf.find(2)
  end

  def test_transitive_union
    @uf.union(1, 2)
    @uf.union(2, 3)
    assert_equal @uf.find(1), @uf.find(3)
  end

  def test_groups_returns_correct_structure
    @uf.union(1, 2)
    @uf.union(3, 4)
    @uf.find(5) # Ensure 5 is tracked

    groups = @uf.groups
    assert_equal 3, groups.size

    # Find which groups contain which elements
    group_with_1 = groups.values.find { |g| g.include?(1) }
    group_with_3 = groups.values.find { |g| g.include?(3) }
    group_with_5 = groups.values.find { |g| g.include?(5) }

    assert_includes group_with_1, 2
    assert_includes group_with_3, 4
    assert_equal [5], group_with_5
  end
end

class TestMatchingStrategies < Minitest::Test
  def test_email_strategy_extracts_email_keys
    headers = %w[FirstName LastName Email Phone]
    strategy = EmailMatchingStrategy.new(headers)
    row = ['John', 'Doe', 'john@example.com', '555-1234']

    keys = strategy.extract_keys(row)
    assert_equal ['email:john@example.com'], keys
  end

  def test_email_strategy_normalizes_case
    headers = %w[Email]
    strategy = EmailMatchingStrategy.new(headers)
    row = ['JOHN@EXAMPLE.COM']

    keys = strategy.extract_keys(row)
    assert_equal ['email:john@example.com'], keys
  end

  def test_email_strategy_ignores_empty_emails
    headers = %w[Email1 Email2]
    strategy = EmailMatchingStrategy.new(headers)
    row = ['john@example.com', '']

    keys = strategy.extract_keys(row)
    assert_equal ['email:john@example.com'], keys
  end

  def test_phone_strategy_extracts_phone_keys
    headers = %w[FirstName Phone]
    strategy = PhoneMatchingStrategy.new(headers)
    row = ['John', '(555) 123-4567']

    keys = strategy.extract_keys(row)
    assert_equal ['phone:5551234567'], keys
  end

  def test_phone_strategy_normalizes_formats
    headers = %w[Phone]
    strategy = PhoneMatchingStrategy.new(headers)

    assert_equal ['phone:5551234567'], strategy.extract_keys(['(555) 123-4567'])
    assert_equal ['phone:5551234567'], strategy.extract_keys(['555-123-4567'])
    assert_equal ['phone:5551234567'], strategy.extract_keys(['555.123.4567'])
    assert_equal ['phone:5551234567'], strategy.extract_keys(['5551234567'])
  end

  def test_phone_strategy_handles_multiple_phone_columns
    headers = %w[Phone1 Phone2]
    strategy = PhoneMatchingStrategy.new(headers)
    row = ['555-1234', '555-5678']

    keys = strategy.extract_keys(row)
    assert_equal ['phone:5551234', 'phone:5555678'], keys
  end

  def test_email_or_phone_strategy_extracts_both
    headers = %w[Email Phone]
    strategy = EmailOrPhoneMatchingStrategy.new(headers)
    row = ['john@example.com', '555-1234']

    keys = strategy.extract_keys(row)
    assert_includes keys, 'email:john@example.com'
    assert_includes keys, 'phone:5551234'
  end
end

class TestCSVGrouper < Minitest::Test
  def create_temp_csv(content)
    file = Tempfile.new(['test', '.csv'])
    file.write(content)
    file.close
    file.path
  end

  def test_validates_file_existence
    assert_raises(ArgumentError, /File not found/) do
      CSVGrouper.new('nonexistent.csv', 'email')
    end
  end

  def test_validates_matching_type
    file = create_temp_csv("FirstName\nJohn")
    assert_raises(ArgumentError, /Invalid matching type/) do
      CSVGrouper.new(file, 'invalid_type')
    end
  end

  def test_groups_by_email
    csv_content = <<~CSV
      FirstName,LastName,Email,Phone
      John,Doe,john@example.com,555-1234
      Jane,Doe,jane@example.com,555-5678
      Jack,Doe,john@example.com,555-9999
    CSV

    file = create_temp_csv(csv_content)
    grouper = CSVGrouper.new(file, 'email')
    result = grouper.process

    # result[0] is the header row
    assert_equal ['PersonID', 'FirstName', 'LastName', 'Email', 'Phone'], result[0]

    # John and Jack should have the same PersonID (they share an email)
    john_id = result[1][0]
    jack_id = result[3][0]
    jane_id = result[2][0]

    assert_equal john_id, jack_id
    refute_equal john_id, jane_id
  end

  def test_groups_by_phone
    csv_content = <<~CSV
      FirstName,LastName,Email,Phone
      John,Doe,john@example.com,555-1234
      Jane,Doe,jane@example.com,555-1234
      Jack,Doe,jack@example.com,555-9999
    CSV

    file = create_temp_csv(csv_content)
    grouper = CSVGrouper.new(file, 'phone')
    result = grouper.process

    # John and Jane share the same phone
    john_id = result[1][0]
    jane_id = result[2][0]
    jack_id = result[3][0]

    assert_equal john_id, jane_id
    refute_equal john_id, jack_id
  end

  def test_groups_by_email_or_phone
    csv_content = <<~CSV
      FirstName,LastName,Email,Phone
      John,Doe,john@example.com,555-1234
      Jane,Doe,jane@example.com,555-1234
      Jack,Doe,john@example.com,555-9999
      Jill,Doe,jill@example.com,555-8888
    CSV

    file = create_temp_csv(csv_content)
    grouper = CSVGrouper.new(file, 'email_or_phone')
    result = grouper.process

    # John shares email with Jack
    # John shares phone with Jane
    # Therefore, John, Jane, and Jack should all be in the same group (transitive)
    john_id = result[1][0]
    jane_id = result[2][0]
    jack_id = result[3][0]
    jill_id = result[4][0]

    assert_equal john_id, jane_id
    assert_equal john_id, jack_id
    refute_equal john_id, jill_id
  end

  def test_handles_empty_fields
    csv_content = <<~CSV
      FirstName,LastName,Email,Phone
      John,Doe,,555-1234
      Jane,Doe,jane@example.com,
      Jack,Doe,,
    CSV

    file = create_temp_csv(csv_content)
    grouper = CSVGrouper.new(file, 'email_or_phone')
    result = grouper.process

    # Each should be in their own group (no matching data)
    ids = [result[1][0], result[2][0], result[3][0]]
    assert_equal 3, ids.uniq.size
  end

  def test_handles_case_insensitive_emails
    csv_content = <<~CSV
      FirstName,Email
      John,JOHN@EXAMPLE.COM
      Jane,john@example.com
    CSV

    file = create_temp_csv(csv_content)
    grouper = CSVGrouper.new(file, 'email')
    result = grouper.process

    # Should be grouped together (case-insensitive email matching)
    john_id = result[1][0]
    jane_id = result[2][0]

    assert_equal john_id, jane_id
  end

  def test_handles_different_phone_formats
    csv_content = <<~CSV
      FirstName,Phone
      John,(555) 123-4567
      Jane,555.123.4567
      Jack,5551234567
    CSV

    file = create_temp_csv(csv_content)
    grouper = CSVGrouper.new(file, 'phone')
    result = grouper.process

    # All should be grouped together (same phone, different formats)
    ids = [result[1][0], result[2][0], result[3][0]]
    assert_equal 1, ids.uniq.size
  end
end

class TestIntegration < Minitest::Test
  def test_input1_csv_exists
    assert File.exist?('data/input1.csv'), 'data/input1.csv should exist'
  end

  def test_input2_csv_exists
    assert File.exist?('data/input2.csv'), 'data/input2.csv should exist'
  end

  def test_input3_csv_exists
    assert File.exist?('data/input3.csv'), 'data/input3.csv should exist'
  end

  def test_can_process_input1_with_email
    grouper = CSVGrouper.new('data/input1.csv', 'email')
    result = grouper.process
    assert result.size > 1, 'Should have processed rows'
    assert_equal 'PersonID', result[0][0], 'First column should be PersonID'
  end

  def test_can_process_input2_with_phone
    grouper = CSVGrouper.new('data/input2.csv', 'phone')
    result = grouper.process
    assert result.size > 1, 'Should have processed rows'
    assert_equal 'PersonID', result[0][0], 'First column should be PersonID'
  end

  def test_can_process_input3_with_email_or_phone
    grouper = CSVGrouper.new('data/input3.csv', 'email_or_phone')
    result = grouper.process
    assert result.size > 1, 'Should have processed rows'
    assert_equal 'PersonID', result[0][0], 'First column should be PersonID'
  end
end

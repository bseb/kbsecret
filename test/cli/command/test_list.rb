# frozen_string_literal: true

require "helpers"

# Tests for KBSecret::CLI::Command::List
class KBSecretCommandListTest < Minitest::Test
  include Helpers
  include Helpers::CLI

  def test_list_help
    list_helps = [
      %w[list --help],
      %w[list -h],
      %w[help list],
    ]

    list_helps.each do |list_help|
      stdout, = kbsecret(*list_help)
      assert_match(/Usage:/, stdout)
    end
  end

  def test_list_contains_record
    kbsecret "new", "login", "test-list", input: "foo\nbar\n"

    stdout, = kbsecret "list"

    assert_includes stdout.split, "test-list"
  ensure
    kbsecret "rm", "test-list"
  end

  def test_list_filters_by_type
    kbsecret "new", "login", "test-list-filter-type1", input: "foo\nbar\n"
    kbsecret "new", "environment", "test-list-filter-type2", input: "baz\nquux\n"

    stdout, = kbsecret "list", "-t", "environment"

    refute_includes stdout.split, "test-list-filter-type1"
    assert_includes stdout.split, "test-list-filter-type2"
  ensure
    kbsecret "rm", "test-list-filter-type1", "test-list-filter-type2"
  end

  def test_list_filters_by_type_alias
    kbsecret "new", "login", "test-list-filter-type-alias1", input: "foo\nbar\n"
    kbsecret "new", "environment", "test-list-filter-type-alias2", input: "baz\nquux\n"

    stdout, = kbsecret "list", "-t", "env"

    refute_includes stdout.split, "test-list-filter-type-alias1"
    assert_includes stdout.split, "test-list-filter-type-alias2"
  ensure
    kbsecret "rm", "test-list-filter-type-alias1", "test-list-filter-type-alias2"
  end

  def test_list_shows_all
    kbsecret "new", "login", "test-list", input: "foo\nbar\n"

    stdout, = kbsecret "list", "-a"
    assert_match(/Raw data:.*foo.*bar/, stdout)
  ensure
    kbsecret "rm", "test-list"
  end

  def test_list_accepts_session
    session_label = "list-test-session"

    kbsecret "session", "new", session_label, "-r", session_label

    kbsecret "new", "-s", session_label, "login", "test-list", input: "foo\nbar\n"

    stdout, = kbsecret "list", "-s", session_label
    assert_includes stdout.split, "test-list"
  ensure
    kbsecret "session", "rm", "-d", session_label
  end

  def test_list_fails_on_multiple_sort_flags
    _, stderr = kbsecret "list", "-A", "-D"
    assert_match "Only one sort flag may be used at once", stderr
  end

  def test_list_sorts_date
    kbsecret "new", "login", "test-list-date1", input: "foo\nbar\n"
    # sleep a bit, to make sure we get different timestamps
    sleep 2
    kbsecret "new", "login", "test-list-date2", input: "baz\nquux\n"

    stdout, = kbsecret "list", "-D"
    lines = stdout.split

    assert_operator lines.index("test-list-date1"), :<, lines.index("test-list-date2")
  ensure
    kbsecret "rm", "test-list-date1"
    kbsecret "rm", "test-list-date2"
  end

  def test_list_sorts_alphabetically
    kbsecret "new", "login", "test-list-aardvark", input: "foo\nbar\n"
    kbsecret "new", "login", "test-list-zebra", input: "baz\nquux\n"

    stdout, = kbsecret "list", "-A"
    lines = stdout.split

    assert_operator lines.index("test-list-aardvark"), :<, lines.index("test-list-zebra")
  ensure
    kbsecret "rm", "test-list-aardvark"
    kbsecret "rm", "test-list-zebra"
  end
end

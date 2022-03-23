require "spec_helper"
using HTMLAttributesUtils

HTMLMergeableAttributesExample = Struct.new(
  :description,
  :original,
  :overrides,
  :expected,
  :mergeable_attributes,
  keyword_init: true
) do
  def mergeable
    mergeable_attributes || []
  end
end

HTMLTidyableAttributesExample = Struct.new(:description, :input, :expected, :mergeable_attributes, keyword_init: true)

mergeable_example_groups = {
  "simple examples" => [
    HTMLMergeableAttributesExample.new(
      {
        description: "regular hash into regular hash",
        original: { a: 1, b: 2 },
        overrides: { b: 3, c: 4 },
        expected: { a: 1, b: 3, c: 4 },
      }
    ),
    HTMLMergeableAttributesExample.new(
      {
        description: "strings into symbols",
        original: { a: 1, b: 2 },
        overrides: { "b" => 3, "c" => 4 },
        expected: { a: 1, b: 3, c: 4 },
      }
    ),
    HTMLMergeableAttributesExample.new(
      {
        description: "symbols into strings",
        original: { "a" => 1, "b" => 2 },
        overrides: { b: 3, c: 4 },
        expected: { a: 1, b: 3, c: 4 },
      }
    ),
  ],

  "nested examples" => [
    HTMLMergeableAttributesExample.new(
      {
        description: "regular hash into nested hash",
        original: { a: 1, b: { c: 1 } },
        overrides: { b: 3, c: 4 },
        expected: { a: 1, b: 3, c: 4 },
      }
    ),
    HTMLMergeableAttributesExample.new(
      {
        description: "nested hash into regular hash",
        original: { a: 1, b: 2 },
        overrides: { b: { d: 5 }, c: 4 },
        expected: { a: 1, b: { d: 5 }, c: 4 },
      }
    ),
    HTMLMergeableAttributesExample.new(
      {
        description: "nested strings into symbols",
        original: { a: 1, b: 2 },
        overrides: { "b" => { "d" => 5 }, "c" => 4 },
        expected: { a: 1, b: { d: 5 }, c: 4 },
      }
    ),
    HTMLMergeableAttributesExample.new(
      {
        description: "nested symbols into strings",
        original: { "a" => 1, "b" => 2 },
        overrides: { b: { d: 5 }, c: 4 },
        expected: { a: 1, b: { d: 5 }, c: 4 },
      }
    ),
  ],

  "mergeable examples with string lists and arrays" => [
    HTMLMergeableAttributesExample.new(
      {
        description: "replacing values with string lists",
        mergeable_attributes: [%i(b)],
        original: { a: 1, b: 2 },
        overrides: { b: "x y z" },
        expected: { a: 1, b: %w(x y z) },
      }
    ),
    HTMLMergeableAttributesExample.new(
      {
        description: "combining string lists with arrays",
        mergeable_attributes: [%i(b)],
        original: { a: 1, b: "v w x" },
        overrides: { b: %w(x y z) },
        expected: { a: 1, b: %w(v w x y z) },
      }
    ),
    HTMLMergeableAttributesExample.new(
      {
        description: "combining arrays with string lists",
        mergeable_attributes: [%i(b)],
        original: { a: 1, b: %w(v w x) },
        overrides: { b: "x y z" },
        expected: { a: 1, b: %w(v w x y z) },
      }
    ),
    HTMLMergeableAttributesExample.new(
      {
        description: "combining string lists with string lists",
        mergeable_attributes: [%i(b)],
        original: { a: 1, b: "v w x" },
        overrides: { b: "x y z" },
        expected: { a: 1, b: %w(v w x y z) },
      }
    ),
    HTMLMergeableAttributesExample.new(
      description: "combining arrays with arrays",
      mergeable_attributes: [%i(b)],
      original: { a: 1, b: "v w x" },
      overrides: { b: "x y z" },
      expected: { a: 1, b: %w(v w x y z) }
    ),
  ],
  "unmergeable examples with string lists and arrays" => [
    HTMLMergeableAttributesExample.new(
      description: "overriding values overwrite original values",
      original: { a: 1, b: 2 },
      overrides: { b: "x y z" },
      expected: { a: 1, b: "x y z" }
    ),
    HTMLMergeableAttributesExample.new(
      description: "overriding arrays overwrite original arrays",
      original: { a: 1, b: %w(v w x) },
      overrides: { b: %w(x y z) },
      expected: { a: 1, b: %w(x y z) }
    ),
  ],
  "mergeable examples with string boolean values" => [
    HTMLMergeableAttributesExample.new(
      description: "omg",
      original: { a: true, b: false },
      overrides: { c: true, d: false },
      expected: { a: true, b: false, c: true, d: false }
    ),
  ],
}

describe "#deep_merge_html_attributes" do
  mergeable_example_groups.each do |group, examples|
    describe group do
      examples.each do |e|
        describe "#{e.description} (#{e.original} <-- #{e.overrides})" do
          specify e.expected do
            expect(
              e.original.deep_merge_html_attributes(
                e.overrides, mergeable_attributes: e.mergeable
              )
            ).to eql(e.expected)
          end
        end
      end
    end
  end
end

tidyable_example_groups = {
  "stripping out keys with empty values" => [
    HTMLTidyableAttributesExample.new(
      description: "empty strings, arrays and hashes are removed from originals",
      input: { a: "b", c: [], d: {}, e: { f: "", g: [], h: {}, i: "j" } },
      expected: { a: "b", e: { i: "j" } }
    ),
    HTMLTidyableAttributesExample.new(
      description: "empty strings, arrays and hashes are removed from overrides",
      input: { a: "b", c: [], d: {}, e: { f: "", g: [], h: {}, i: "j" } },
      expected: { a: "b", e: { i: "j" } }
    ),
    HTMLTidyableAttributesExample.new(
      description: "arrays with empty values are removed",
      input: { a: [[], "one", nil, "two", "", {}] },
      expected: { a: %w(one two) }
    ),
    HTMLTidyableAttributesExample.new(
      description: "non-empty but blank strings are removed",
      input: { a: "b", c: " ", d: "   ", e: ["f", " "], h: { i: " ", j: "k" } },
      expected: { a: "b", e: %w(f), h: { j: "k" } }
    ),
  ],
}

describe "#deep_tidy_html_attributes" do
  tidyable_example_groups.each do |group, examples|
    describe group do
      examples.each do |e|
        describe "#{e.description} (#{e.input})" do
          specify e.expected do
            expect(e.input.deep_tidy_html_attributes).to eql(e.expected)
          end
        end
      end
    end
  end
end

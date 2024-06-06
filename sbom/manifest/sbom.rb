# frozen_string_literal: true

require "sbom_on_rails"

client = ENV["CLIENT"] || "UNKNOWN_CLIENT"
sha = ENV["COMMIT_SHA"] || "UNKNOWN_SHA"
project_name = "enroll_#{client}"

component_def = SbomOnRails::Sbom::ComponentDefinition.new(
  project_name,
  sha,
  nil,
  { github: "https://github.com/ideacrew/enroll" }
)

manifest = SbomOnRails::Manifest::ManifestFile.new(
  File.join(
    File.dirname(__FILE__),
    "manifest.yaml"
  )
)

File.open(
  File.join(
    File.dirname(__FILE__),
    "../sbom.json"
  ),
  "wb"
) do |f|
  f.puts manifest.execute(component_def)
end

# frozen_string_literal: true
require 'aca_entities/ffe/operations/mcr_to/enrollment'
require 'aca_entities/ffe/transformers/mcr_to/enrollment'
# RAILS_ENV=production bundle exec rails db:migrate:up dir="directory_path" VERSION="20210521151722"
class MigrateMcrEnrollment < Mongoid::Migration
  include Acapi::Notifiers

  def self.up
    @directory_name = ENV['dir'].to_s || nil
    start
  end

  def self.down; end

  class << self
    def migrate_mcr_enrollment
      AcaEntities::FFE::Transformers::McrTo::Enrollment.call(@filepath, { transform_mode: :batch }) do |payload|
        if Rails.env.development?
          Operations::Ffe::MigrateEnrollment.new.call(payload)
        else
          notify("acapi.info.events.migration.mcr_enrollment_payload", {:body => JSON.dump(payload)})
        end
      rescue StandardError => e
        puts "Error: #{payload[:policyTrackingNumber]}"
      end
    end

    def start
      read_directory do
        migrate_mcr_enrollment
      end
    end

    def read_directory(&block)
      Dir.foreach(@directory_name) do |filename|
        if File.extname(filename) == ".json"
          @filepath = "#{@directory_name}/#{filename}"
          instance_eval(&block) if block_given?
        end
      end
    end
  end
end

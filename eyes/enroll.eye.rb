BUS_DIRECTORY = File.join(File.dirname(__FILE__), "..")
LOG_DIRECTORY = File.join(BUS_DIRECTORY, "log")
PID_DIRECTORY = File.join(BUS_DIRECTORY, "pids")

BLUEPILL_LOG = File.join(LOG_DIRECTORY, "eye_enroll.log")

Eye.config do
  logger BLUEPILL_LOG

  mail :host => "smtp4.dc.gov", :port => 25, :from_mail => "no-reply@dchbx.info"
  contact :tevans, :mail, 'trey.evans@dc.gov'
  contact :dthomas, :mail, 'dan.thomas@dc.gov'
end

Eye.application 'eye_enroll' do
  notify :tevans, :info
  notify :dthomas, :info

  process("unicorn") do
    working_dir BUS_DIRECTORY
    pid_file "pids/unicorn.pid"
    start_command "bundle exec unicorn -c #{BUS_DIRECTORY}/config/unicorn.rb -E production -D"
    stdall "log/unicorn.log"

    # stop signals:
    #     # http://unicorn.bogomips.org/SIGNALS.html
    stop_signals [:TERM, 10.seconds]
    #
    #             # soft restart
    #    restart_command "kill -USR2 {PID}"
    #
    # check :cpu, :every => 30, :below => 80, :times => 3
    # check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    #
    start_timeout 30.seconds
    restart_grace 30.seconds
    stop_timeout 10.seconds
    #
    monitor_children do
      stop_command "kill -QUIT {PID}"
      check :cpu, :every => 30, :below => 80, :times => 3
      check :memory, :every => 30, :below => 400.megabytes, :times => [4,7]
    end
  end

  process("enroll_remote_event_listener") do
    working_dir BUS_DIRECTORY
    pid_file "pids/enroll_remote_event_listener.pid"
    start_command "bundle exec rails runner -e production script/remote_event_listener.rb"
    stdall "log/enroll_remote_event_listener.log"
    daemonize true

    # stop signals:
    #     # http://unicorn.bogomips.org/SIGNALS.html
    stop_signals [:TERM, 10.seconds]
    #
    #             # soft restart
    #    restart_command "kill -USR2 {PID}"
    #
    # check :cpu, :every => 30, :below => 80, :times => 3
    # check :memory, :every => 30, :below => 150.megabytes, :times => [3,5]
    #
    start_timeout 30.seconds
    restart_grace 30.seconds
    stop_timeout 10.seconds
  end
end

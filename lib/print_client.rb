require "print_client/version"
require 'serialport'
require 'nokogiri'
require 'logger'
require 'benchmark'
require 'virtusprinter'

module PrintClient
  ACK  = 6
  XOFF = 19

  class DefaultPrinter
    def initialize
      config = YAML::load_file("./virtusprinter.yml")
      @vp_port = config['virtusprinter']['port']
    end
    def default
      port = SerialPort.new(@vp_port, 9600, 8, 1)
      port.write "^default\n"
      port.close
    end
  end

  class ConfigPrinter
    def initialize
      config = YAML::load_file("./virtusprinter.yml")
      @vp_port = config['virtusprinter']['port']
    end
    def config
      port = SerialPort.new(@vp_port, 9600, 8, 1)
      port.write "xa\nI8,A,003\n"
      port.close
    end
  end

  class PrintLabels
    def initialize
      config = YAML::load_file("./virtusprinter.yml")
      @vp_computer = config['virtusprinter']['computer']
    end
    def start
      virtus_printer = VirtusPrinter.new
      log = Logger.new('log.txt', shift_age = 5, shift_size = 6048576)
      log.level = Logger::DEBUG
      log.debug 'Started logging'
      while true
        begin
          sleep 1
          result = false
          data = {}
          time = Benchmark.realtime do
            result, data = virtus_printer.get_labels(@vp_computer)
          end
          log.debug "Time spent in virtusprinter: #{time}"
          unless result
            print " #{virtus_printer.error} "
            next
          end
          print '.'

          xml_doc = Nokogiri::XML(data)
          labels = xml_doc.css("labels label")
          next if labels.count == 0

          # Open all required ports
          ports = {}
          labels.each do |l|
            port = l.at_css('port').content
            unless ports.include?(port)
              ports[port] = SerialPort.new(port, 9600, 8, 1)
              # Wait forever to receive printer response
              ports[port].read_timeout = 0
              # Enable error reporting
              ports[port].write "US"
            end
          end

          # Print labels
          labels.each do |l|
            label_id = l.at_css('id').content
            port = l.at_css('port').content
            epl = l.at_css('epl').content
            print 'p'
            if epl.nil? || epl == ''
              next
            else
              epl.encode!('ISO-8859-1')
              ports[port].write(epl)
              while true
                byte = ports[port].getbyte
                # The label was printed successfully
                break if byte == ACK
                # There was an error, read all error bytes
                break if byte == XOFF
              end
            end
          end

          # Update labels
          labels.each do |l|
            label_id = l.at_css('id').content
            print 'u'
            result = virtus_printer.update_label label_id, 'PRINTED'
            puts virtus_printer.error if result == false
          end

          # Close all ports
          ports.each_value{ |port| port.close}

        rescue Interrupt => e
          log.error e
          exit
        rescue SystemCallError => e
          log.error e
          puts e
        rescue SocketError => e
          log.error e
          print ' SocketError '
        rescue Exception => e
          log.error e
          puts e.class
          puts e
        end
      end
    end
  end

  class TestTemplate
    def initialize
      config = YAML::load_file("./virtusprinter.yml")
      @vp_template = config['virtusprinter']['template']
      @vp_port = config['virtusprinter']['port']
    end

    def start
      template_name = @vp_template
      port = @vp_port

      puts "#{template_name} => #{port}"

      virtus_printer = VirtusPrinter.new
      result, data = virtus_printer.test_template(template_name, port)

      xml_doc = Nokogiri::XML(data)
      labels = xml_doc.css("labels label")

      labels.each do |l|
        port = l.at_css('port').content
        epl = l.at_css('epl').content
        epl.encode!('ISO-8859-1')
        puts port
        puts epl
        sp = SerialPort.new(port, 9600, 8, 1)
        sp.write epl
      end
    end
  end
end

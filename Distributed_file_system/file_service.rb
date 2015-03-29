require 'socket'      # Sockets are in standard library
require_relative 'server'

class File_Service < Server
  def initialize
    $port = 4444
  end

  def connectToDs
    hostname = 'localhost'
    port = 3001
    s = TCPSocket.open(hostname, port)
    s.puts "NEW FileService on " + $port.to_s
    s.puts "\r\n"
  end

  def newMessage(msg)

  end

  def open (file_name)
    file = File.open(file_name, 'r')
    file.readline
    file.close

  end

  def close

  end

  def write

  end

  def read

  end
end

fs = File_Service.new
fs.connectToDs
fs.startServer

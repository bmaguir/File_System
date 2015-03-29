require 'socket'                # Get sockets from stdlib
require_relative 'server'

class Dir_Server < Server

  class Fs
    attr_accessor :port
  end

  def initialize
    $port = 3001
    $FileServers = Array.new

  end

  def newMessage(msg)
    if msg[0].include? "FileService:"
      $FileServers.push(Fs.new)
    end
  end

end

dir_server = Dir_Server.new
dir_server.startServer
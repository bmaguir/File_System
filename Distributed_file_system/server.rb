require 'socket'                # Get sockets from stdlib
class Server

  def initialize
    $port = 1
  end

  def startServer
    thread_pool = Array.new
    server = TCPServer.open($port)   # Socket to listen on port 20007
    puts "Listenting on port " + $port.to_s
    while(true)                          # Servers run forever

      client = server.accept;
      puts "Accepted message starting Thread"
      thread_pool.push(Thread.new{thread_fun(client)})
      thread_pool.each do |thread|
        if thread.status == "false"
          puts "joining Thread"
          thread.join
          thread.delete
        end
      end
    end
  end

  def newMessage(msg)

  end

  def thread_fun(client)
    lines = Array.new
    puts "new connection"
    disconnect = false
    while disconnect == false
      lines.clear
      line = client.gets   # Read lines from the socket
      #puts line
      while line != "\r\n"
        #puts line.chop      # And print with platform line terminator
        exit if line.include? "KILL_SERVICE"
        lines.push(line)
        line = client.gets
      end

      if lines[0].include? "DISCONNECT:"
        puts "disconnecting socket"
        client.puts "Closing the connection. Bye!\n\r\n"
        client.close                # Disconnect from the client
        disconnect = true
      end

      newMessage(lines)

    end
    puts "closing thread"
  end
end
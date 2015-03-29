require 'socket'
class Test_Client

  hostname = 'localhost'
  port = 4444
  $s = TCPSocket.open(hostname, port)

  puts "connected to " + hostname + " , " + port.to_s

  while(true)
    msg  = gets.chomp
    if(msg == "kill")
      puts "killing service"
      $s.puts 'KILL_SERVICE'
      break
    elsif(msg == "dis")
      puts "Disconnecting"
      $s.puts 'DISCONNECT'
      break
    else
      $s.puts msg + "\r\n"
      puts msg
    end
  end

end

tc = Test_Client.new

require 'socket'      # Sockets are in standard library
require_relative 'server'
require 'date'

class File_Service < Server

  def initialize(p, serverName)
    $port = p
    $serverName = serverName
    Dir.mkdir serverName unless File.exists?(serverName)
    $files = Dir.entries(serverName)
    $FileServers = Array.new
    $openFiles = Array.new
  end

  def connectToDs
    hostname = 'localhost'
    port = 4444
    s = TCPSocket.open(hostname, port)
    s.puts '{"type":"NewServer", "port":' + $port.to_s + '}' + "\n\r\n"
    s.close
    #register all files with the Directory Server
    for file in $files
      registerFile(file)
    end
  end

  def registerFile(filename)
    #tells the ds that this fs has a copy of this file
    hostname = 'localhost'
    port = 4444
    s = TCPSocket.open(hostname, port)
    s.puts '{"type":"NewFile", "port":"' + $port.to_s + '", "filename":"' + filename + '"}' + "\n\r\n"
    s.close
  end

  def findFile(name)
    for file in $files
      if file == name
        return true
      end
    end
    return false
  end

  def newMessage(msg, client)
    case msg["type"]
      when "Read"
        if checkTimeStamp(msg["lockTS"])
          if findFile(msg["name"])
            content = read(msg["name"])
            client.puts formReadResponse(content, msg["name"])
          else
            #file doesn't exist, return error
          end
        else
          sendTimeOut(client)
        end
      when "Write"
        if checkTimeStamp(msg["lockTS"])
          $openFiles.push(UpdatedFiles.new(msg["lockTS"].to_int, msg["name"], msg["content"]))
          client.puts formWriteResponse(msg["name"], true)
        else
          sendTimeOut(client)
        end
      when "Close"
        if checkTimeStamp(msg["lockTS"])
          for file in $openFiles
            if file.name == msg["name"] && file.lockTs == msg["lockTS"].to_int
              write(file.name, file.updatedContent)
            end
          end
          #write  updates to file
          #clear lock on DS
          if findFile(msg["name"])
            clearLock(msg["name"])
          else
            $files.push(msg["name"])
            replicateFile(msg["name"])
          end
          client.puts formWriteResponse(msg["name"], true)
        else
          sendTimeOut(client)
          #remove entries from update array
        end
      when "FSAddr"
        stringFS = msg["file_servers"]
        tempArray = Array.new
        for sft in stringFS.each
          tempArray.push(stringFS.to_int)
        end
        $FileServers = tempArray
      else
        #undefined message
    end
  end

  def replicateFile(fn)
    registerFile(fn)
    #send file to two other Servers
  end

  def clearLock(fn)
    hostname = 'localhost'
    port = 4444
    s = TCPSocket.open(hostname, port)
    s.puts '{"type":"ClearLock", "port":"' + $port.to_s + '", "filename":"' + fn + '"}' + "\n\r\n"
    s.close
  end

  def checkTimeStamp(ts)
    timeNow = p DateTime.now.strftime('%s')
    if timeNow - ts > 100000 #lock has timed out
      return false
    else
      return true
    end
  end

  def sendTimeOut (socket)
    response = '{"type":"TimeOut", "success":"false"}' + "\n\r\n"
    socket.puts response
  end

  def close

  end

  def write(file_name, content)
    file = File.open($serverName + "/" + file_name, 'w')
    file.puts(content)
  end

  def read(file_name)
    file = File.open($serverName + "/" + file_name, 'r')
    file.readline
    file.close
  end

  def formReadResponse(content, fn)
    request = '{"type":"ReadResponse","success":"true", "name":"' + fn + '", "content":"' + content + '"}' + "\r\n"
    return request
  end

  def formWriteResponse(fn, success)
    request = '{"type":"WriteResponse","success":"true", "name":"' + fn + '"}' + "\r\n"
    return request
  end
end

class UpdatedFiles
  attr_accessor :lockTS, :name, :updatedContent
end

#class FileClassFS < FileClass
#  attr_accessor :content, :contentBuffer
#end

fs = File_Service.new(4253, 'server1')
fs.connectToDs
#fs.startServer

require 'socket'                # Get sockets from stdlib
require_relative 'server'
require_relative 'file_class'
require 'date'

class Dir_Server < Server

  def initialize (p)
    $port = p
    $FileServers = Array.new
    #$FileSevers = [1234, 2345, 3456] #static list of file servers
    $Directory = Array.new
  end

  def newMessage(msg, client)
    #puts msg["type"]
    case msg["type"]
      when "Open"
        file = lookUpDirectory(msg[name])
        if file == nil
          #file not found, make new file?
          randomFileServer = $FileSevers[0]
          tempFile = FileClass.new(msg["name"], true, randomFileServer)
          tempFile.setLock
          client.puts formResponse(false, tempFile.fs[0], tempFile.lockTs, false)
        else
          if file.checkLock #returns true is can be locked
            file.setLock
            #file found and locked, send address of fs to client
            client.puts formResponse(true, file.fs[0], file.lockTs, false)
          else
            #file locked by another client, try again later
            client.puts formResponse(false, 0, 0, true)
          end
        end

      when "NewServer"
        $FileSevers.push(msg["port"].to_int)
        puts "added new File Server " + msg["port"].to_s
        #once fs added, broadcast all available fs for replication
        broadcastFS()
      when "NewFile"
        addFile(msg["port"], msg["filename"])
        #puts "added new file " + msg["filename"]
      when "ClearLock"
        fs = clearLock(msg["filename"])
        client.puts '{"type":"Replicate", "Addr":' + fs +'}'
      else
        puts "undefined message"
    end
  end

  def addFile(port, fn)
    #if file already exists, add replica fs addr, create if not exist
    for file in $Directory
      if file.name == fn
        file.fs.push(port)
      end
    end
    tempFile = FileClass.new(fn, false, port)
    $Directory.push(tempFile)
  end

  def formResponse(success, fs, lTs, locked)
    if success == true
      response = '{"type":"OpenResponse", "success":"true", "fs":"' + fs.to_s + '", "lockTimeStamp":"' + lTs.to_s + '"}' + "\n\r\n"
    else
      if locked
        response = '{"type":"OpenResponse", "success":"false", "errorcode":"locked"}' + "\n\r\n"
      else
        response = '{"type":"OpenResponse", "success":"false", "errorcode":"notfound", "fs":"' + fs.to_s + '", "lockTimeStamp":"' + lTs.to_s + '"}' + "\n\r\n"
      end
    end
    return response
  end

  def clearLock(filename)
    for file in $Directory
      if file.name = filename
        file.lock =  false
        return file.fs
      end
    end
  end

  def lookUpDirectory(filename)
    for file in $Directory
      if file.name = filename
        return file
      end
    end
    return nil
  end

  def broadcastFS
    hostname = 'localhost'
    msg  = '"type":"FSAddr","file_servers":"' + $FileServers.to_s + '"}'
    for fs in $FileServers
      s = TCPSocket.open(hostname, fs)
    end
  end

end


dir_server = Dir_Server.new(4444)
dir_server.startServer
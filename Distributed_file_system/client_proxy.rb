require 'socket'
require "rubygems"
require "json"
require_relative 'file_class'

class Client_proxy
  def initialize
    $hostname = 'localhost'
    $DSport = 4444
    $openFile = nil
  end

  def open(filename)
    s = TCPSocket.open($hostname, $DSport)
    s.puts formOpenRequest(filename)
    response = readFromSocket(s)
    s.close
    if response["success"] == "true"
      #lock is established and can fetch file from returned fs
      puts "file " + filename + " is now open"
      $openFile = FileClass.new(filename, true, response["fs"])
      $openFile.lockTs = response["lTs"]
    else
      #file either already in use, or does not exist
      if response["errorcode"] == 'notfound'
        puts "file not found, would you like to create it? y/n"
        #if user responds yes
        input = gets.chomp
        if input == 'y'
          puts "file " + filename + " is now open"
          $openFile = FileClass.new(filename, true, response["fs"])
          $openFile.lockTs = response["lTs"]
        end
      else
        puts "file is locked by another user, please try again later"
      end
    end
  end

  def readFromSocket(socket)
    lines = Array.new
    line = s.gets   # Read lines from the socket
    while line != "\r\n"
      lines.push(line)
      line = s.gets
    end
    parsed = JSON.parse(lines[0])
    return parsed
  end

  def formOpenRequest(fm)
    request = '{"type":"Open", "name":"' + fm + '"}' + "\r\n"
    return request
  end

  def formReadRequest(fm, lockTS)
    request = '{"type":"Read", "name":"' + fm + '", "lockTS":"' + lockTS + '"}' + "\r\n"
    return request
  end

  def formWriteRequest(fm, ts, nf)
    request = '{"type":"Write", "name":"' + fm + '", "lockTS":"' + ts + '", "update":"' + nf + '"}' + "\r\n"
    return request
  end

  def formCloseRequest(fm, ts)
    request = '{"type":"Close", "name":"' + fm + '", "lockTS":"' + ts + '"}' + "\r\n"
    return request
  end

  def close
    if $openFile.checkTimeStamp
      s = TCPSocket.open($hostname, $openFile.fs[0])
      s.puts formCloseRequest(filename, $openFile.lockTs)
      response = readFromSocket(s)
      s.close
      if response["success"] == 'true'
        #file closed successfully
        $openFile = nil
      else
        #file not found on the fs or lock timed out
      end
    else
      #lock has timed out, need to reopen file
      puts 'Service has timed out, please reopen file'
    end
  end

  def write(newFile)
    if $openFile.checkTimeStamp
      s = TCPSocket.open($hostname, $openFile.fs[0])
      s.puts formWriteRequest(filename, $openFile.lockTs, newFile)
      response = readFromSocket(s)
      s.close
      if response["success"] == 'true'
        #update cache with new file
        puts response["content"]
      else
        #file not found on the fs or lock timed out
      end
    else
      #lock has timed out, need to reopen file
      puts 'Service has timed out, please reopen file'
    end
  end

  def read
    if $openFile.checkTimeStamp
      readingFile = readFromCache
      if readingFile != nil
        return readingFile
      end
      s = TCPSocket.open($hostname, $openFile.fs)
      s.puts formReadRequest(filename, $openFile.lockTs)
      response = readFromSocket(s)
      s.close
      if response["success"] == 'true'
        #update cache with response
        readingFile = response["content"]
        puts response["content"]
        return readingFile
      else
        #file not found on the fs or lock timed out
        return nil
      end
    else
      #lock has timed out, need to reopen file
      puts 'Service has timed out, please reopen file'
      return nil
    end
  end

  def readFromCache
    #check cache for file, return nil if not found
    return nil
  end

  end

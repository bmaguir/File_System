require 'date'
class FileClass
  attr_accessor :lock, :lockTs, :fs, :name
  def initialize (n, l, fs)
    $name = n
    $lock = l
    $fs = Array.new
    $fs.push(fs)
  end

  def checkLock
    if $lock == true
      timeNow = p DateTime.now.strftime('%s')
      if timeNow - $lockTs > 100000 #lock has timed out
        $lock = false
        return true
      else
        return false #file is locked by another client
      end
    else
      return true #lock is not taken
    end
  end

  def setLock
    $lock = true
    $lockTs = p DateTime.now.strftime('%s')
  end
end
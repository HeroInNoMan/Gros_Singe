
class KillTime
  def initialize(tps, &blk)
    @last = Time.now
    @thread = Thread.new do
      while true do
        sleep(1)
        if Time.now - @last > tps
          blk.call
          @last = Time.now
        end
      end
    end
    @thread.run
  end

  def reset
    @last = Time.now
  end

  def stop
    @thread.stop
  end

  def run
    @thread.run
  end
end

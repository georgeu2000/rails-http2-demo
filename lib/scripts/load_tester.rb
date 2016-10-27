require 'benchmark'

threads = []

time = Benchmark.realtime do
  ( 1..40 ).each do | i |
    puts i

    threads << Thread .new do | thr |
      %x{curl -ks --http2 https://localhost:8080/ > /dev/null}
    end
  end

  threads.each { |thr| thr.join }
end


# z = %x{curl -k --http2 https://localhost:8080/ > /dev/null}

puts "\nElapsed: #{time.round( 2 )}"
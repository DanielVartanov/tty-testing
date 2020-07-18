# frozen_string_literal: true

require "io/wait"

# TODO: Submit it to Ruby stdlib for consideration

class IO
  module ReadAvailable
    # Reads all information available in the stream at the moment
    def read_available
      read(nread)
    end
  end
end

IO.class_eval { include IO::ReadAvailable }

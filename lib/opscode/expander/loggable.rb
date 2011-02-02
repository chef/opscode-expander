#
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Seth Falcon (<seth@opscode.com>)
# Author:: Chris Walters (<cw@opscode.com>)
# Copyright:: Copyright (c) 2010-2011 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'mixlib/log'

module Opscode
  module Expander
    module Loggable
      class Logger
        include Mixlib::Log

        def init(*args)
          @logger = nil
          super
        end

        [:debug,:info,:warn,:error, :fatal].each do |level|
          class_eval(<<-LOG_METHOD, __FILE__, __LINE__)
            def #{level}(message=nil, &block)
              @logger.#{level}(message, &block)
            end
          LOG_METHOD
        end
      end

      # TODO: it's admittedly janky to set up the default logging this way.
      STDOUT.sync = true
      LOGGER = Logger.new
      LOGGER.init
      LOGGER.level = :debug

      def log
        LOGGER
      end

    end
  end
end


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

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

require 'opscode/expander/vnode_supervisor'
require 'opscode/expander/vnode'

describe Expander::VNode do
  before do
    @supervisor = Expander::VNodeSupervisor.new
    @vnode = Expander::VNode.new("2342", @supervisor, :supervise_interval => 0.1)
    @log_stream = StringIO.new
    @vnode.log.init(@log_stream)
  end

  it "has the vnode number it was created with" do
    @vnode.vnode_number.should == 2342
  end

  it "has a queue named after its vnode number" do
    @vnode.queue_name.should == "vnode-2342"
  end

  it "has a control queue name" do
    @vnode.control_queue_name.should == "vnode-2342-control"
  end

  describe "when connecting to rabbitmq" do
    it "disconnects if there is another subscriber" do
      begin
        q = nil
        b = Bunny.new(OPSCODE_EXPANDER_MQ_CONFIG)
        b.start
        q = b.queue(@vnode.queue_name, :passive => false, :durable => true, :exclusive => false, :auto_delete => false)
        t = Thread.new { q.subscribe { |message| nil }}

        AMQP.start(OPSCODE_EXPANDER_MQ_CONFIG) do
          EM.add_timer(0.5) do
            AMQP.stop
            EM.stop
          end
          @vnode.start
        end
        t.kill

        @vnode.should be_stopped
        @log_stream.string.should match(/Detected extra consumers/)
      ensure
        q && q.delete
        b.stop
      end
    end

    it "calls back to the supervisor when it subscribes to the queue" do
      AMQP.start(OPSCODE_EXPANDER_MQ_CONFIG) do
        MQ.topic('foo')
        EM.add_timer(0.1) do
          AMQP.stop
          EM.stop
        end
        @vnode.start
      end
      @supervisor.vnodes.should == [2342]
    end

    it "calls back to the supervisor when it stops subscribing" do
      @supervisor.vnode_added(@vnode)
      AMQP.start(OPSCODE_EXPANDER_MQ_CONFIG) do
        MQ.topic('foo')
        EM.add_timer(0.1) do
          @vnode.stop
          AMQP.stop
          EM.stop
        end
      end
      @supervisor.vnodes.should be_empty
    end

  end

end

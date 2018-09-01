# frozen_string_literal: true

# Copyright (c) 2018 by Jiang Jinyang <jjyruby@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.


require 'spec_helper'
require 'ciri/actor'
require 'ciri/eth/protocol_manage'
require 'ciri/devp2p/server'
require 'ciri/devp2p/protocol'
require 'ciri/devp2p/rlpx/node'
require 'ciri/devp2p/rlpx/protocol_handshake'
require 'concurrent'

RSpec.describe Ciri::DevP2P::Server do
  before {Ciri::Actor.default_executor = Concurrent::CachedThreadPool.new}
  after do
    Ciri::Actor.default_executor.kill
    Ciri::Actor.default_executor = nil
  end

  let(:key) do
    Ciri::Key.random
  end

  let (:eth_protocol) do
    Ciri::DevP2P::Protocol.new(name: 'eth', version: 63, length: 17)
  end

  let(:protocol_manage) do
    Ciri::Eth::ProtocolManage.new(protocols: [eth_protocol], chain: nil)
  end

  it 'connecting to bootstrap_nodes after started' do
    boot_node = Ciri::DevP2P::RLPX::Node.new(
        node_id: Ciri::DevP2P::RLPX::NodeID.new(key),
        ip: "localhost",
        udp_port: 42,
        tcp_port: 42,
    )
    server = Ciri::DevP2P::Server.new(private_key: key, protocol_manage: protocol_manage, bootstrap_nodes: [boot_node])
    allow(server).to receive(:setup_connection) {|node| raise StandardError.new("setup connection error ip:#{node.ip}, tcp_port:#{node.tcp_port}")}
    server.start
    expect do
      server.scheduler.wait
    end.to raise_error(StandardError, "setup connection error ip:#{boot_node.ip}, tcp_port:#{boot_node.tcp_port}")
  end
end
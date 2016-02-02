#!/usr/bin/env ruby
#/ Usage:  client.rb -c cert.pem -h localhost -p 6697
#/
#/ Launch chat client on given host / port (defaults to localhost / 9953) with given SSL X509 certificate

require 'socket'
require 'openssl'
require 'thread'
require 'readline'
require 'optparse'

# default options
cert_file_name = 'cert.pem'
host = 'localhost'
port = 9953

# parse arguments
file = __FILE__
ARGV.options do |opts|
  opts.on("-c", "--cert=val", String)  { |val| cert_file_name = val }
  opts.on("-h", "--host=val", String)  { |val| host = val }
  opts.on("-p", "--port=val", Integer)  { |val| port = val }
  opts.on_tail("-h", "--help")         { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end

# assume given paths are relative to calling path
pwd = Dir.pwd
public_cert_path = File.join(pwd, cert_file_name)

# verifiable public cert
cert_store = OpenSSL::X509::Store.new
cert_store.add_file public_cert_path

puts 'creating ssl session'
ssl_context = OpenSSL::SSL::SSLContext.new()
ssl_context.ssl_version = :TLSv1_2_client
ssl_context.verify_mode = OpenSSL::SSL::VERIFY_PEER
ssl_context.cert_store = cert_store

def log(msg)
  puts msg
end

puts 'creating socket'
socket = TCPSocket.new(host, port)
ssl_socket = OpenSSL::SSL::SSLSocket.new(socket, ssl_context)
ssl_socket.sync_close = true
ssl_socket.connect

# # show information about the session
# log "SOCKET PEER_CERT: #{ ssl_socket.peer_cert }"
# log "SOCKET CIPHER: #{ ssl_socket.cipher.inspect }"
# log "SOCKET STATE: #{ ssl_socket.state }"

def chat_with_socket(sock)
  log 'connected! Send `quit` to quit.'

  reader = Thread.new do
    while line = sock.gets
      log "[message] #{ line }"
      print "> "
    end
  end

  # writer
  print "> "
  while line = Readline.readline("", true)
    if /^q(uit)?$/ =~ line
      log "BYE!"
      break
    end

    sock.puts line
  end

  Thread.kill(reader)

  sock.close
end

chat_with_socket(ssl_socket)

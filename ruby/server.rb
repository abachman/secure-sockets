#!/usr/bin/env ruby
#/ Usage:  server.rb -k key.pem -c cert.pem -p 6697
#/
#/ Launch chat server on given port (defaults to 9953) with given SSL X509 certificate and private key

require 'socket'
require 'openssl'
require 'thread'
require 'securerandom'
require 'optparse'

def log(message)
  puts "[server #{Time.now}] #{message}"
end

# default options
key_file_name = 'key.pem'
key_file_passphrase = nil
cert_file_name = 'cert.pem'
port = 9953

# parse arguments
file = __FILE__
ARGV.options do |opts|
  opts.on("-k", "--key=val", String) { |val| key_file_name = val }
  opts.on("-p", "--passphrase=val", String)   { |val| key_file_passphrase = val }
  opts.on("-c", "--cert=val", String)  { |val| cert_file_name = val }
  opts.on("-p", "--port=val", Integer)  { |val| port = val }
  opts.on_tail("-h", "--help")         { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end

# assume given paths are relative to calling path
pwd = Dir.pwd
cert_path = File.join(pwd, cert_file_name)
key_path = File.join(pwd, key_file_name)
key = key_file_passphrase ?
  OpenSSL::PKey::RSA.new(File.read(key_path), key_file_passphrase) :
  OpenSSL::PKey::RSA.new(File.read(key_path))

# socket = TCPSocket.open(host, port)
log 'preparing context'
ssl_context             = OpenSSL::SSL::SSLContext.new()
ssl_context.cert        = OpenSSL::X509::Certificate.new(File.read(cert_path))
ssl_context.key         = key
ssl_context.ssl_version = :TLSv1_2_server

# prepare server
log 'starting server'
server = TCPServer.new port
ssl_server = OpenSSL::SSL::SSLServer.new(server, ssl_context)

sessions = {}

log "ready! listening on port #{port}"
loop do
  begin
    Thread.start(ssl_server.accept) do |client|
      client_id = SecureRandom.uuid
      short_id = client_id.split('-')[0]

      log "client #{ short_id } has joined"
      sessions[client_id] = client

      begin
        while line = client.gets
          log "#{short_id} #{line}"

          sessions.each_pair do |cid, other_client|
            begin
              other_client.puts "#{ short_id } #{line}"
            rescue => ex
              log "ERROR writing to #{ cid }, dropping"
              sessions.delete(cid)
            end
          end
        end
      rescue => ex
        log "ERROR #{ ex.class.to_s }: #{ ex.message }"
        begin
          client.puts "ERROR exiting"
        rescue => ex2
          log "ERROR2: #{ ex2.message }"
        end
      end

      log "#{ short_id } has left the room"
      sessions.delete(client_id)
    end
  rescue OpenSSL::SSL::SSLError => ex
    log "OpenSSL::SSL::SSLError in ssl_server.accept: #{ ex.message }"
  rescue => ex
    log "#{ex.class.to_s} in ssl_server.accept: #{ ex.message }"
  end
end

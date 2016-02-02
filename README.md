Playing with TLS 1.2 connections over raw TCP sockets.

Should work out of the box with Ruby >= 2.2 and Go >= 1.5.

## Running

Run `./create-cert.sh`, get the paths for the cert and key files:
`cert/cert_*.pem` and `cert/key_*.pem`.

Start the Ruby server:

    $ ruby ruby/server.rb -c cert/cert.pem -k cert/key.pem
    [server 2019-02-02 10:00:00 -0000] preparing context
    [server 2019-02-02 10:00:00 -0000] starting server
    [server 2019-02-02 10:00:00 -0000] ready! listening on port 9953

The server is running.

Start the client (Ruby does send / receive, go is send-only right now):

    $ ruby ruby/client.rb -c cert/cert_2019-02-02.pem
    creating ssl session
    creating socket
    connected! Send `quit` to quit.
    >

Start a bunch of clients. They can chat! It's TLS!

## Why?

Just playing with these tools. I rely on them to keep working without
intervention, it's probably a good idea for me to figure out how they work.

For now it's building something that works and then changing pieces of it to
see how it breaks.

- Adam Bachman, 2016-Feb

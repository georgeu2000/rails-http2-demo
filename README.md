###Demo app for Rails using HTTP/2

###Supports all major features of HTTP/2 including
* Server Push
* Multiplexing
* Stream Prioritization
* Flow Control

###How to use
1. Generate `server.crt` and `server.key`. Put them in lib/keys
2. `rake server:start`
3. In a second window, `ruby lib/scripts/client.rb https://localhost:8080`

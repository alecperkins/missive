#!/usr/bin/env node

http    = require 'http'
url     = require 'url'
fs      = require 'fs'
path    = require 'path'

    # path = require("path"),
    # fs = require("fs")

BASE_FOLDER = '/Users/alecperkins/BTSync/bitmessage/'

contactFolder = (contact) -> path.join(BASE_FOLDER, contact)
loadContactData = (contact) ->
    folder = contactFolder(contact)
    info = fs.readFileSync(path.join(folder, 'info.json')).toString()
    return JSON.parse(info)

getMessagesWith = (contact, cb) ->
    contact_data = loadContactData(contact)
    console.log 'contact_data', contact_data
    if contact_data
        return [{
                'date': '2013-07-12T18:13:31Z'
                'body': 'Asdf!'
            }]
    else
        cb(null)
createNewMessageWith = (contact) ->




 
server = http.createServer (request, response) ->
    uri = url.parse(request.url, true)
    console.log request.url, uri
    switch uri.pathname
        when '/'
            response.writeHead(200)
            response.write(index_file)
        when '/api/messages/'
            switch request.method
                when 'GET'
                    messages = getMessagesWith(uri.query.contact)
                    console.log 'messages', messages
                    if messages?
                        response.writeHead(200)
                        response.write(JSON.stringify(messages))
                    else
                        response.writeHead(404)
                when 'POST'
                    createNewMessageWith(uri.query.contact)
                    response.writeHead(201)
                    response.write('ok')
                else
                    response.writeHead(405)

        else
            response.writeHead(404)
            response.write("Not found: #{ uri }")
    response.end()



index_file = """
    contacts
    all messages
"""

  # var uri = url.parse(request.url).pathname
  #   , filename = path.join(process.cwd(), uri);
  
  # path.exists(filename, function(exists) {
  #   if(!exists) {
  #     response.writeHead(404, {"Content-Type": "text/plain"});
  #     response.write("404 Not Found\n");
  #     response.end();
  #     return;
  #   }
 
  #   if (fs.statSync(filename).isDirectory()) filename += '/index.html';
 
  #   fs.readFile(filename, "binary", function(err, file) {
  #     if(err) {        
  #       response.writeHead(500, {"Content-Type": "text/plain"});
  #       response.write(err + "\n");
  #       response.end();
  #       return;
  #     }
 
  #     response.writeHead(200);
  #     response.write(file, "binary");
  #     response.end();
  #   });
  # });

port = process.argv[2] or 8888
server.listen(parseInt(port, 10))
console.log "Server listening at localhost:#{ port }"

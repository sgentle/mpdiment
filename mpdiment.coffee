express = require 'express'
mpd_rest  = require 'mpd-rest'

app = express.createServer()

app.use require('connect-assets')()
app.use express.static __dirname + '/public'
app.use mpd_rest('achilles.local')

app.listen 3000

express = require('express')
logger = require('morgan')
bodyParser = require('body-parser')
_ = require('underscore')

app = express()

# setup templating
app.set 'view engine', 'html'    # use .html extension for templates
app.set 'layout', 'layout'       # use layout.html as the default layout
# define partials available to all pages
app.set 'partials',
  header: 'partials/header'
  footer: 'partials/footer'

# app.enable 'view cache'
app.engine 'html', require('hogan-express')

app.use(express.static(__dirname + '/public'))
app.use logger("dev")
app.use bodyParser.urlencoded({ extended: true })


leaderboard = []

app.get '/', (req, res) ->
  res.render 'index'

app.get '/display', (req, res) ->
  res.render 'display'

app.get '/leaderboard', (req, res) ->
  res.render 'leaderboard', { leaderboard: leaderboard }

app.post '/leaderboard', (req, res) ->
  leaderboard.push(req.body)
  leaderboard = _.sortBy leaderboard, (i) -> return -i.score
  res.send "OK"

server = app.listen(8080)

io = require('socket.io')(server)

colors = ["#e41a1c","#377eb8","#4daf4a","#984ea3","#ff7f00","#ffff33","#a65628","#f781bf","#999999"]
players = {}

io.on 'connection', (socket) ->

  socket.color = players.length

  socket.on 'register', (username) ->
    socket.username = username
    availableColors = _.difference(_.values(players), colors)
    players[socket.id] = availableColors[0]
    socket.color = availableColors[0]

  socket.on 'orientation', (data) ->
    data.color = socket.color
    socket.broadcast.emit 'orientation', data

  socket.on 'fire', (username) ->
    socket.broadcast.emit 'fire', username

  socket.on 'disconnect', () ->
    delete players[socket.id]


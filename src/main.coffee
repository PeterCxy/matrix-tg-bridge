import 'babel-polyfill'
import { Matrix } from './matrix'
import { Telegram } from './telegram'
config = require '../config.json'

main = ->
  # Build routes
  matrixRooms = []
  tgChats = []
  m2t = {}
  t2m = {}

  for k in config.route
    matrixRooms.push k.matrix
    tgChats.push parseInt k.telegram
    m2t[k.matrix] = parseInt k.telegram
    t2m[k.telegram] = k.matrix

  matrix = new Matrix config.matrix.server + "/_matrix", config.matrix.username, config.matrix.password
  telegram = new Telegram config.telegram.token, tgChats

  # Start listeners
  await matrix.start matrixRooms
  telegram.listen()

main()

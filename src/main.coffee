import 'babel-polyfill'
import { Matrix } from './matrix'
config = require '../config.json'

main = ->
  matrix = new Matrix config.matrix.server + "/_matrix", config.matrix.username, config.matrix.password

  # Build routes
  matrixRooms = []
  tgChats = []
  m2t = {}
  t2m = {}

  for k in config.route
    matrixRooms.push k.matrix
    tgChats.push k.telegram
    m2t[k.matrix] = k.telegram
    t2m[k.telegram] = k.matrix

  # Start listeners
  await matrix.start matrixRooms

main()

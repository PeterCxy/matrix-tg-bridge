import 'babel-polyfill'
import { Matrix } from './matrix'
import { Telegram } from './telegram'
config = require '../config.json'

main = ->
  # Build routes
  matrixRooms = []
  tgChats = []

  for k in config.route
    matrixRooms.push k.matrix
    tgChats.push parseInt k.telegram

  matrix = new Matrix config.matrix.server + "/_matrix", config.matrix.username, config.matrix.password
  telegram = new Telegram config.telegram.token, tgChats

  # Start listeners
  await matrix.start matrixRooms
  telegram.listen()

  # Forward messages
  for k in config.route
    matrix.on "msg_#{k.matrix}", (user, msg) ->
      try
        await telegram.sendMessage k.telegram, formatMsg user, msg
      catch err
        console.log err
    matrix.on "img_#{k.matrix}", (user, img) ->
      try
        await telegram.sendMessage k.telegram, formatImg user, img
      catch err
        console.log err
    telegram.on "msg_#{k.telegram}", (user, msg) ->
      try
        await matrix.sendMessage k.matrix, formatMsg user, msg
      catch err
        console.log err
    telegram.on "img_#{k.telegram}", (user, img) ->
      try
        await matrix.sendMessage k.matrix, formatImg user, img
      catch err
        console.log err

formatMsg = (user, msg) -> "[#{user}] #{msg}"
formatImg = (user, img) -> "[#{user}] <image> #{img}"

main()

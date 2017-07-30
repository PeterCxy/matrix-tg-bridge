import { EventEmitter } from "events"
import request from "request-promise"
config = require '../config.json'

export class Matrix extends EventEmitter
  constructor: (@baseURL, @username, @password) ->
    super()
    @roomMap = {}
    @roomMapR = {}
    @next_batch = null

  sendMessage: (room, text) =>
    options =
      method: 'POST'
      uri: "#{@baseURL}/client/r0/rooms/#{encodeURIComponent @roomMapR[room]}/send/m.room.message?access_token=#{@access_token}",
      json: yes
      body:
        msgtype: 'm.text'
        body: text
    return await request options

  start: (rooms) =>
    # Login
    console.log '[Matrix] logging in....'
    options =
      method: 'POST'
      uri: "#{@baseURL}/client/r0/login"
      json: yes
      body:
        type: "m.login.password"
        user: @username
        password: @password
    {access_token} = await request options
    @access_token = access_token
    for r in rooms
      console.log "[Matrix] Joining #{r}"
      options =
        method: 'POST'
        json: yes
        uri: "#{@baseURL}/client/r0/join/#{encodeURIComponent r}?access_token=#{@access_token}"
      {room_id} = await request options
      console.log "[Matrix] " + r + " --> " + room_id
      # Build a map between ID and alias
      # We will expose the alias for outgoing events
      @roomMap[room_id] = r
      @roomMapR[r] = room_id
    @listen()
    return null

  listen: =>
    while true
      try
        await @update()
      catch err
        console.log err

  update: =>
    next_batch = @next_batch
    options =
      method: 'GET'
      uri: "#{@baseURL}/client/r0/sync"
      json: yes
      qs:
        access_token: @access_token
        timeout: 30000
    if next_batch?
      options.qs.since = next_batch
    if !next_batch?
      # Ignore the first sync event
      # If we forward these, chances are that there might be duplicated messages
      {next_batch} = await request options
      @next_batch = next_batch if next_batch? # It might be possible that we got no message
      return
    {next_batch, rooms} = await request options
    @next_batch = next_batch if next_batch? # It might be possible that we got no message
    for k, v of rooms.join
      alias = @roomMap[k]
      continue if !alias? # Only accept routed rooms.
      for ev in v.timeline.events
        #console.log ev
        sender = ev.sender.split(':')[0].replace '@', ''
        continue if sender is @username # Matrix does not filter our own messages by default
        if ev.type is 'm.room.message'
          if ev.content.msgtype is 'm.text'
            console.log "[Matrix] Text message #{ev.event_id} from #{sender}"
            @emit "msg_#{alias}", sender, ev.content.body
          if ev.content.msgtype is 'm.image'
            console.log "[Matrix] Image message #{ev.event_id} from #{sender}"
            url = "#{@baseURL.replace config.matrix.server, config.matrix.server_url}/media/r0/download/#{ev.content.url.replace 'mxc://', ''}"
            console.log "[Matrix] Image URL #{url}"
            @emit "img_#{alias}", sender, url

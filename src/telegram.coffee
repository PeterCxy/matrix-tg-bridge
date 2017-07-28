import { EventEmitter } from "events"
import request from "request-promise"

export class Telegram extends EventEmitter
  constructor: (token, @chats) ->
    super()
    @baseURL = "https://api.telegram.org/bot#{token}"
    @offset = null

  sendMessage: (chat, text) =>
    options =
      uri: "#{@baseURL}/sendMessage"
      method: 'POST'
      json: yes
      body:
        chat_id: chat
        text: text
    return await request options

  listen: =>
    while true
      try
        await @update()
      catch error
        console.log error

  update: =>
    offset = @offset
    options =
      uri: "#{@baseURL}/getUpdates"
      method: 'GET'
      json: yes
      qs:
        timeout: 300
    if offset?
      options.qs.offset = offset
    updates = (await request options).result
    #console.log updates
    for u in updates
      offset = u.update_id
      if !@offset?
        continue
      if u.message?
        continue if !(u.message.chat.id in @chats)
        if u.message.text? and !u.message.reply_to_message?
          # A text message: not a reply
          console.log "[Telegram] Message #{u.message.message_id} from #{u.message.from.username}"
          @emit "msg_#{u.message.chat.id}", u.message.from.username, u.message.text
    if offset? # It might be possible that we got no message
      @offset = offset + 1

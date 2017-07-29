import { EventEmitter } from "events"
import request from "request-promise"
import { promisify } from "util"
import { exists, createWriteStream } from "fs"
{data_domain} = require '../config.json'
existsAsync = promisify exists

export class Telegram extends EventEmitter
  constructor: (token, @chats) ->
    super()
    @baseURL = "https://api.telegram.org/bot#{token}"
    @fileURL = "https://api.telegram.org/file/bot#{token}/"
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

  downloadFile: (type, id, suffix) =>
    path = "./data/#{type}/#{id}.#{suffix}"
    if await existsAsync path
      return path.replace './', ''
    options =
      uri: "#{@baseURL}/getFile"
      method: 'GET'
      json: yes
      qs:
        file_id: id
    {result} = await request options
    url = @fileURL + result.file_path
    return new Promise (resolve, reject) ->
      reader = request(url)
      stream = reader.pipe(createWriteStream(path))
      reader.on 'end', ->
        resolve path.replace './', ''
      reader.on 'error', (err) ->
        reject err

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
        if u.message.text? and u.message.reply_to_message?
          # A text message: a reply
          console.log "[Telegram] Message #{u.message.message_id} from #{u.message.from.username} replying to #{u.message.reply_to_message.from.username}"
          @emit "msg_#{u.message.chat.id}", u.message.from.username, u.message.reply_to_message.from.username + ": " + u.message.text
          # TODO: If replying to a forwarded message, use the original username instead of the bot.
        if u.message.photo?
          # A photo message
          id = u.message.photo[u.message.photo.length - 1].file_id
          console.log "[Telegram] Photo #{id} from #{u.message.from.username}"
          path = await @downloadFile 'pictures', id, 'jpg'
          console.log "[Telegram] Photo downloaded to #{path}"
          @emit "img_#{u.message.chat.id}", u.message.from.username, data_domain + path.replace 'data/', ''
        if u.message.sticker?
          # A sticker message
          id = u.message.sticker.file_id
          console.log "[Telegram] Sticker #{id} from #{u.message.from.username}"
          path = await @downloadFile 'stickers', id, 'webp'
          console.log "[Telegram] Sticker downloaded to #{path}"
          @emit "img_#{u.message.chat.id}", u.message.from.username, data_domain + path.replace 'data/', ''
    if offset? # It might be possible that we got no message
      @offset = offset + 1

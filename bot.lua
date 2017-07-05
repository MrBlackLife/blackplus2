package.path = package.path .. ';.luarocks/share/lua/5.2/?.lua'
.. ';.luarocks/share/lua/5.2/?/init.lua'
package.cpath = package.cpath .. ';.luarocks/lib/lua/5.2/?.so'

redis = (loadfile "redis.lua")()
serpent = require('serpent')
tdcli = dofile('tdcli.lua')
serp = require 'serpent'.block
redis2 = require 'redis'
JSON = require('dkjson')
clr = require 'term.colors'
HTTP = require('socket.http')
HTTPS = require('ssl.https')
URL = require('socket.url')
clr = require 'term.colors'
db = redis2.connect('127.0.0.1', 6379)
sudo_users = {
1220999838
}

--info_username
local function info_username(extra, result, success)
  vardump(result)
  chat_id = db:get('chatid')
  local function dl_photo(arg,data)
    tdcli.sendPhoto(chat_id, 0, 0, 1, nil, data.photos_[0].sizes_[1].photo_.persistent_id_,result.id_..'\n'..result.type_.user_.first_name_)
  end
  tdcli_function ({ID = "GetUserProfilePhotos",user_id_ = result.id_,offset_ = 0,limit_ = 100000}, dl_photo, nil)
  db:del('chatid')
end
--info_user
local function info_user(username)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, info_username, extra)
end

--get_info
function get_info(user_id)
  if db:hget('bot:username',user_id) then
    text = ' @'..(string.gsub(db:hget('bot:username',user_id), 'false', '') or '')..' | <code>'..user_id..'</code> '
  end
  get_user(user_id)
  return text
end
--get_username
function get_username(user_id)
  if db:hget('bot:username',user_id) then
    text = '@'..(string.gsub(db:hget('bot:username',user_id), 'false', '') or '')
  end
  get_user(user_id)
  return text
end
--get_user
function get_user(user_id)
  function dl_username(arg, data)
    username = data.username or ''

    --vardump(data)
    db:hset('bot:username',data.id_,data.username_)
  end
  tdcli_function ({
    ID = "GetUser",
    user_id_ = user_id
  }, dl_username, nil)
end
--getmessage
local function getMessage(chat_id, message_id,cb)
  tdcli_function ({
    ID = "GetMessage",
    chat_id_ = chat_id,
    message_id_ = message_id
  }, cb, nil)
end
--sendphoto
function sendPhoto(chat_id, reply_to_message_id, disable_notification, from_background, reply_markup, photo, caption)
  tdcli_function ({
    ID = "SendMessage",
    chat_id_ = chat_id,
    reply_to_message_id_ = reply_to_message_id,
    disable_notification_ = disable_notification,
    from_background_ = from_background,
    reply_markup_ = reply_markup,
    input_message_content_ = {
      ID = "InputMessagePhoto",
      photo_ = getInputFile(photo),
      added_sticker_file_ids_ = {},
      width_ = 0,
      height_ = 0,
      caption_ = caption
    },
  }, dl_cb, nil)
end
--serachpublicchat
local function searchPublicChat(username, cb, cmd)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb or dl_cb, cmd)
end
--addlist
function addlist(msg)
  if msg.content_.contact_.ID == "Contact" then
    tdcli.importContacts(msg.content_.contact_.phone_number_, (msg.content_.contact_.first_name_ or '--'), '#bot', msg.content_.contact_.user_id_)--@Showeye
    tdcli.sendMessage(msg.chat_id_, msg.id_, 0, 1, nil, '☘️<b>شما به لیست اضافه شدید!</b>\n', 1, 'html')
  end
end
--gbanned
function is_gbanned(msg)
  local msg = data.message_
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  local var = false
  local hash = 'bot:gbanned:Araz'
  local banned = redis:sismember(hash, user_id)
  if banned then
    var = true
  end
  return var
end
--resolve_username
function resolve_username(username,cb)
  tdcli_function ({
    ID = "SearchPublicChat",
    username_ = username
  }, cb, nil)
end
--changememberstatus
function changeChatMemberStatus(chat_id, user_id, status)
  tdcli_function ({
    ID = "ChangeChatMemberStatus",
    chat_id_ = chat_id,
    user_id_ = user_id,
    status_ = {
      ID = "ChatMemberStatus" .. status
    },
  }, dl_cb, nil)
end
--chat_kick
function chat_kick(chat_id, user_id)
  changeChatMemberStatus(chat_id, user_id, "Kicked")
end
--addedgp
function is_added(msg)
  local var = false
  if redis:sismember('groups:Araz',msg.chat_id_) then
    var = true
  end
  return var
end
--sudo
function is_sudo(msg)
  local var = false
  for v,user in pairs(sudo_users) do
    if user == msg.sender_user_id_ then
      var = true
    end
  end
  return var
end

--admin
function is_admin(msg)
  local user_id = msg.sender_user_id_
  local var = false
  local hashs =  'botadmins:Araz'
  local admin = redis:sismember(hashs, user_id)
  if admin then
    var = true
  end
  for k,v in pairs(sudo_users) do
    if user_id == v then
      var = true
    end
  end
  return var
end
--rializetofile
function serialize_to_file(data, file, uglify)
  file = io.open(file, 'w+')
  local serialized
  if not uglify then
    serialized = serpent.block(data, {
      comment = false,
      name = '_'
    })
  else
    serialized = serpent.dump(data)
  end
  file:write(serialized)
  file:close()
end

--normal
function is_normal(msg)
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  local mutel = redis:sismember('muteusers:Araz'..chat_id,user_id)
  if mutel then
    return true
  end
  if not mutel then
    return false
  end
end


--owner
function is_owner(msg)
  local var = false
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  local group_owners = redis:get('owners:Araz'..chat_id)
  if group_owners == tostring(user_id) then
    var = true
  end
  if redis:sismember('botadmins:Araz',user_id) then
    var = true
  end
  for v, user in pairs(sudo_users) do
    if user == user_id then
      var = true
    end
  end
  return var
end
---mod
function is_mod(msg)
  local var = false
  local chat_id = msg.chat_id_
  local user_id = msg.sender_user_id_
  if redis:sismember('promotes:Araz'..chat_id,user_id) then
    var = true
  end
  if redis:sismember('botadmins:Araz',user_id) then
    var = true
  end

  if  redis:get('owners:Araz'..chat_id) == tostring(user_id) then
    var = true
  end
  for v, user in pairs(sudo_users) do
    if user == user_id then
      var = true
    end
  end
  return var
end
-- Print message format. Use serpent for prettier result.
function vardump(value, depth, key)
  local linePrefix = ''
  local spaces = ''

  if key ~= nil then
    linePrefix = key .. ' = '
  end

  if depth == nil then
    depth = 0
  else
    depth = depth + 1
    for i=1, depth do
      spaces = spaces .. '  '
    end
  end

  if type(value) == 'table' then
    mTable = getmetatable(value)
    if mTable == nil then
      print(spaces .. linePrefix .. '(table) ')
    else
      print(spaces .. '(metatable) ')
      value = mTable
    end
    for tableKey, tableValue in pairs(value) do
      vardump(tableValue, depth, tableKey)
    end
  elseif type(value)  == 'function' or
    type(value) == 'thread' or
    type(value) == 'userdata' or
    value == nil then
      print(spaces .. tostring(value))
    elseif type(value)  == 'string' then
      print(spaces .. linePrefix .. '"' .. tostring(value) .. '",')
    else
      print(spaces .. linePrefix .. tostring(value) .. ',')
    end
  end

  -- Print callback
  function dl_cb(arg, data)

  end
  local function setowner_reply(extra, result, success)
    t = vardump(result)
    local msg_id = result.id_
    local user = result.sender_user_id_
    local ch = result.chat_id_
    redis:del('owners:Araz'..ch)
    redis:srem('owners:Araz'..user,ch)
    redis:set('owners:Araz'..ch,user)
    redis:sadd('owners:Araz'..user,ch)
    if redis:hget(result.chat_id_, "lang:Araz") == "en" then
      text = '☘️User : '..get_info(user)..' Promoted As Owner !'
    else
      text = '☘️کاربر : '..get_info(user)..' ناظم شد!'
    end
    tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'html')
    print(user)
  end
--demoteowner_reply
  local function deowner_reply(extra, result, success)
    t = vardump(result)
    local msg_id = result.id_
    local user = result.sender_user_id_
    local ch = result.chat_id_
    redis:del('owners:Araz'..ch)
    redis:srem('owners:Araz'..msg.sender_user_id_,msg.chat_id_)
    if redis:hget(result.chat_id_, "lang:Araz") == "en" then
      text = '☘️User : '..get_info(user)..' Demoted!'
    else
      text = '☘️کاربر : '..get_info(user)..' از ناظم بودن برکنار شد!'
    end
    tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'html')
    print(user)
  end

--kick_reply
  function kick_reply(extra, result, success)
    if redis:sismember('promotes:Araz'..result.chat_id_, result.sender_user_id_) then
      if redis:hget(result.chat_id_, "lang:Araz") == "en" then
        text = '*You Can not kick admins!*'
      else
        text = '☘️_شما نمیتوانید مقامات بالاتر را حذف کنید_!'
      end
      tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'md')
    else
      b = vardump(result)
      tdcli.changeChatMemberStatus(result.chat_id_, result.sender_user_id_, 'Kicked')
      if redis:hget(result.chat_id_, "lang:Araz") == "en" then
        text = '☘️<b>Done!</b>\n User : '..get_info(result.sender_user_id_)..' Kicked!'
      else
        text = '☘️انجام شد!\nکاربر: '..get_info(result.sender_user_id_)..' از گروه حذف شد!'
      end
      tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'md')
    end
  end

--deletemessagesfromuser
  local function deleteMessagesFromUser(chat_id, user_id, cb, cmd)
    tdcli_function ({
      ID = "DeleteMessagesFromUser",
      chat_id_ = chat_id,
      user_id_ = user_id
    },cb or dl_cb, cmd)
  end

--promote_reply
  local function setmod_reply(extra, result, success)

    local msg = result.id_
    local user = result.sender_user_id_
    local chat = result.chat_id_
    redis:sadd('promotes:Araz'..result.chat_id_, user)
    if redis:hget(result.chat_id_, "lang:Araz") == "en" then
      text = '☘️User : '..get_info(user)..' Promoted!'
    else
      text = '☘️کاربر : '..get_info(user)..' ناظم شد!'
    end
    tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'html')
  end
--demote_reply
  local function remmod_reply(extra, result, success)

    local msg = result.id_
    local user = result.sender_user_id_
    local chat = result.chat_id_
    redis:srem('promotes:Araz'..chat,user)
    if redis:hget(result.chat_id_, "lang:Araz") == "en" then
      text = '☘️User : '..get_info(user)..' Demoted!'
    else
      text = '☘️کاربر : '..get_info(user)..' از ناظم بودن عزل شد!'
    end

    tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'html')
  end

--ban_reply
  function ban_reply(extra, result, success)
    if redis:sismember('promotes:Araz'..result.chat_id_, result.sender_user_id_) then
      if redis:hget(result.chat_id_, "lang:Araz") == "en" then
        text = '☘️*You Can,t Ban Moderators !*'
      else
        text = '☘️*شما نميتوانيد مدير و ناظم ها را بن کنيد !*'
      end
      tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'md')
    else
      if redis:hget(result.chat_id_, "lang:Araz") == "en" then
        text = '☘️User : <code>'..result.sender_user_id_..'</code> Banned!'
      else
        text = '☘️کاربر : <code>'..get_info(result.sender_user_id_)..'</code> بن شد!'
      end
      tdcli.changeChatMemberStatus(result.chat_id_, result.sender_user_id_, 'Kicked')
      tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'html')
    end
  end
  --mute_reply
  local function setmute_reply(extra, result, success)
    vardump(result)
    if not redis:sismember('promotes:Araz'..result.chat_id_, result.sender_user_id_) then
      redis:sadd('muteusers:Araz'..result.chat_id_,result.sender_user_id_)
      if redis:hget(result.chat_id_, "lang:Araz") == "en" then
        text = "☘️<b>Done!</b>\nUser : <code>"..get_info(result.sender_user_id_).."</code> Muted and can't Speak"
      else
        text = '☘️باموفقیت انجام شد!\nکاربر : <code>'..get_info(result.sender_user_id_)..'</code> به لیست ساکت شدگان افزوده شد و قادر به حرف زدن نمیباشد!'
      end
      tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'html')
    else
      if redis:hget(result.chat_id_, "lang:Araz") == "en" then
        text = '☘️<b>Refused!</b>\n<b>You Can not mute mods!</b>'
      else
        text = '☘️<b>رد شد!</b>\n<b>شما نميتوانيد مدير يا ناظم هارا ساکت بکنيد!</b>'
      end
      tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'html')
    end
  end
--demote_reply
  local function demute_reply(extra, result, success)
    --vardump(result)
    redis:srem('muteusers:Araz'..result.chat_id_,result.sender_user_id_)
    if redis:hget(result.chat_id_, "lang:Araz") == "en" then
      text = '☘️<b>Done!</b>\nUser : <code>('..result.sender_user_id_..')</code> unmuted and can speak now'
    else
      text = '☘️<b>باموفقیت انجام شد!</b>\nکاربر : <code>'..get_info(result.sender_user_id_)..'</code>از لیست ساکت شده ها حذف شد و اکنون میتواند حرف بزند!'
    end
    tdcli.sendText(result.chat_id_, 0, 0, 1, nil, text, 1, 'html')
  end
--user_info
  function user_info(extra,result)
    if result.user_.username_  then
      username = '☘️*Username :* @'..result.user_.username_..''
    else
      username = ''
    end
    local text = '☘️<b>Firstname :</b> <code>'..(result.user_.first_name_ or 'none')..'</code>\n<b>☘️Group ID : </b><code>'..extra.gid..'</code>\n<b>☘️Your ID  :</b> <code>'..result.user_.id_..'</code>\n<b>☘️Your Phone : </b><code>'..(result.user_.phone_number_ or  '<b>--</b>')..'</code>\n'..username
    tdcli.sendText(extra.gid,extra.msgid, 0, 1,  text, 1, 'html')
  end

--idphoto
  function idby_photo(extra,data)
    --vardump(extra)
    --vardump(data)
    if redis:hget(extra.gid, "lang:Araz") == "en" then
      text = '☘️SuperGroup ID : '..string.sub(extra.gid, 5,14)..'\n☘️User ID : '..extra.uid..''
    else
      text = '☘️آيدي گروه : '..string.sub(extra.gid, 5,14)..'\n☘️آيدي کاربر : '..extra.uid..''
    end
    tdcli.sendPhoto(extra.gid, 0, extra.id, 1, nil, data.photos_[0].sizes_[1].photo_.persistent_id_, text)
  end
--getmessages
  function get_msg(msgid,chatid,cb1,cb2)
    return tdcli_function({ID = "GetMessage",chat_id_ = chatid,message_id_ = msgid}, cb1, cb2)
  end
--getpro
  function get_pro(uid,cb1,cb2)
    tdcli_function ({ID = "GetUserProfilePhotos",user_id_ = uid,offset_ = 0,limit_ = 1}, cb1, cb2)
  end
--idreply
  function idby_reply(extra,data)
    --vardump(extra)
    --vardump(data)
    local uid = data.sender_user_id_
    get_pro(uid,idby_photo,{gid=extra.gid,uid=uid,id=extra.id})
  end
  --banned
  function is_banned(msg)
    local var = false
    local msg = data.message_
    local chat_id = msg.chat_id_
    local user_id = msg.sender_user_id_
    local hash = 'bot:banned:Araz'..chat_id
    local banned = redis:sismember(hash, user_id)
    if banned then
      var = true
    end
    return var
  end
--CALLBACK-RUNAWAY
  function tdcli_update_callback(data)

    if (data.ID == "UpdateNewMessage") then
      local msg = data.message_
      local input = msg.content_.text_
      local chat_id = msg.chat_id_
      local user_id = msg.sender_user_id_
      local reply_id = msg.reply_to_message_id_



      if msg.chat_id_ then



        local id = tostring(msg.chat_id_)
        if id:match('^(%d+)') then --- msg to group
        --process
        if msg.content_.ID == "MessageChatAddMembers" or msg.content_.ID == "MessageChatJoinByLink" or msg.content_.ID == "MessageChatDeleteMember" then
          if redis:get('lock_tgservice:Araz'..msg.chat_id_) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end
        end
if msg.content_photo_ or msg.content_.animation_ or msg.content_.audio_ or msg.content_.document_ or msg.content_.video_ then
          if msg.content_.caption_ and not is_mod(msg) then
            if redis:get('lock_link:Araz'..chat_id) and msg.content_.caption_:find("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/") or msg.content_.caption_:find("[Tt].[Mm][Ee]/") and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            if redis:get('lock_tag:Araz'..chat_id) and msg.content_.caption_:find("#") and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            if redis:get('lock_username:Araz'..chat_id) and msg.content_.caption_:find("@") and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            if redis:get('lock_persian:Araz'..chat_id) and msg.content_.caption_:find("[\216-\219][\128-\191]") and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end


            local is_english_msg = msg.content_.caption_:find("[a-z]") or msg.content_.caption_:find("[A-Z]")
            if redis:get('lock_english:Araz'..chat_id) and is_english_msg and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            local is_curse_msg = msg.content_.caption_:find("کير") or msg.content_.caption_:find("کص") or msg.content_.caption_:find("کون") or msg.content_.caption_:find("جنده") or msg.content_.caption_:find("قهبه") or msg.content_.caption_:find("گایید") or msg.content_.caption_:find("سکس") or msg.content_.caption_:find("kir") or msg.content_.caption_:find("kos") or msg.content_.caption_:find("kon")
            if redis:get('lock_curse:Araz'..chat_id) and is_curse_msg and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            local is_emoji_msg = input:match("😀") or input:match("😬") or input:match("😁") or input:match("😂") or  input:match("😃") or input:match("😄") or input:match("😅") or input:match("☺️") or input:match("🙃") or input:match("🙂") or input:match("😊") or input:match("😉") or input:match("😇") or input:match("😆") or input:match("😋") or input:match("😌") or input:match("😍") or input:match("😘") or input:match("😗") or input:match("😙") or input:match("😚") or input:match("🤗") or input:match("😎") or input:match("🤓") or input:match("🤑") or input:match("😛") or input:match("😏") or input:match("😶") or input:match("😐") or input:match("😑") or input:match("😒") or input:match("🙄") or input:match("🤔") or input:match("😕") or input:match("😔") or input:match("😡") or input:match("😠") or input:match("😟") or input:match("😞") or input:match("😳") or input:match("🙁") or input:match("☹️") or input:match("😣") or input:match("😖") or input:match("😫") or input:match("😩") or input:match("😤") or input:match("😲") or input:match("😵") or input:match("😭") or input:match("😓") or input:match("😪") or input:match("😥") or input:match("😢") or input:match("🤐") or input:match("😷") or input:match("🤒") or input:match("🤕") or input:match("😴") or input:match("💋") or input:match("❤️")
            if redis:get('lock_emoji:Araz'..chat_id) and is_emoji_msg and not is_mod(msg)  then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
          end
        end

        -----------
        if msg.content_.game_ then
          if redis:get('mute_game:Araz'..chat_id) and msg.content_.game_ and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end
        end
        ---------
        if  msg.content_.ID == "MessageContact" and msg.content_.contact_  then
	 if redis:get('mute_contact:Araz'..chat_id) or redis:get('mute_all:Araz'..msg.chat_id_) then
            if msg.content_.contact_ and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
          end
          if msg.content_.ID == "MessageContact" then
            tdcli.importContacts(msg.content_.contact_.phone_number_, (msg.content_.contact_.first_name_ or '--'), '#bot', msg.content_.contact_.user_id_)
            redis:set('is:added:Araz'..msg.sender_user_id_, "yes")
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, '☘️شماره شما ذخیره شد!', 1, 'html')
          end
        end
      end
    end
    if msg.content_.caption_ then
	if redis:get('lock_caption:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
			if redis:get('lock_link:Araz'..chat_id) and msg.content_.caption_:find("[Hh]ttps://[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/(.*)") and not is_mod(msg) or redis:get('lock_link:Araz'..chat_id) and msg.content_.caption_:find("[Hh]ttps://[Tt].[Mm][Ee]/(.*)") and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

          if redis:get('lock_tag:Araz'..chat_id) and msg.content_.caption_:find("#") and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

          if redis:get('lock_username:Araz'..chat_id) and msg.content_.caption_:find("@") and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

          if redis:get('lock_persian:Araz'..chat_id) and msg.content_.caption_:find("[\216-\219][\128-\191]") and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end



          local is_english_msg = msg.content_.caption_:find("[a-z]") or msg.content_.caption_:find("[A-Z]")
          if redis:get('lock_english:Araz'..chat_id) and is_english_msg and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end
	end

 if  msg.content_.animation_ then
        if redis:get('mute_gif:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
        end
     end

        if msg.content_.photo_ then
          if redis:get('mute_photo:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg)  then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
          end

        if msg.content_.audio_ then
          if redis:get('mute_audio:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
          end

        if msg.content_.voice_ then
          if redis:get('mute_voice:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_)  and not is_mod(msg)  then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
          end
        if  msg.content_.video_ then
          if redis:get('mute_video:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg)  then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
          end
        if  msg.content_.document_ then
          if redis:get('mute_document:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end
        end


        if msg.content_.location_ then
          if redis:get('lock_location:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end
        end
     if msg.forward_info_ then
	if redis:get('lock_forward:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
	end

if msg.content_.contact_ then
	if redis:get('mute_contact:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
	end

if msg.content_.location_ then
	if redis:get('lock_location:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
	end

	   if msg.content_.sticker_ then
	      if redis:get('mute_sticker:Araz'..chat_id) and not is_mod(msg) or redis:get('mute_all:Araz'..msg.chat_id_) and not is_mod(msg) then
                tdcli.deleteMessages(chat_id, {[0] = msg.id_})
             end
          end

    if msg.content_.ID == "MessageText"  then
if msg.content_.text_ then
          if redis:get('mute_text:Araz'..chat_id) or redis:get('mute_all:Araz'..msg.chat_id_) then
            if msg.content_.text_ and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
          end
        end
      redis:incr("bot:usermsgs:Araz"..msg.chat_id_..":"..msg.sender_user_id_)
      redis:incr("bot:allgpmsgs:Araz"..msg.chat_id_)
      redis:incr("bot:allmsgs:Araz")
      if msg.chat_id_ then
        local id = tostring(msg.chat_id_)
        if id:match('-100(%d+)') then
	if redis:get('markread'..msg.chat_id_) then
	              tdcli.viewMessages(chat_id, {[0] = msg.id_})
	end
--LeaveRealm
          if msg.content_.text_:match("^!leave(-%d+)") and is_admin(msg) then
            local txt = {string.match(msg.content_.text_, "^!(leave)(-%d+)$")}
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, '☘️ربات با موفقيت از گروه '..txt[2]..' خارج شد.', 1, 'md')
            tdcli.sendText(txt[2], 0, 0, 1, nil, '☘️ربات این گروه را ترک خواهد کرد!\n#علت:ممکن است یکی از مدیران از گروه مدیریتی ربات را از گروه شما لفت داده باشد یا ربات را تمدید نکرده باشید\nربات پشتیبان:@NeTGuarDBot\nکانال:@NeTGuarD_COM', 1, 'html')
            tdcli.changeChatMemberStatus(txt[2], tonumber(92986552), 'Left')
          end
--ADD
          if msg.content_.text_:match("^[!][Aa]dd$") and is_admin(msg) then
            if  redis:sismember('groups:Araz',chat_id) then
              return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️_گروه از قبل افزوده شده است!_', 1, 'md')
            end
            tdcli.sendText(-1001086624506, 0, 0, 1, nil, '☘️<b>New Group Has Been Added By :</b> '..get_info(msg.sender_user_id_)..'', 1, 'html')
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<i>گروه جدید به لیست مدیریتی افزوده شد\n☘️اضافه کننده</i>: '..get_info(msg.sender_user_id_)..'\n<i>☘️آراز ورژن 8.5</i>', 1, 'html')
            redis:sadd('groups:Araz',chat_id)
			redis:setex("bot:charge:Araz"..chat_id,2592000,true)
            redis:set('floodtime:Araz'..chat_id, tonumber(3))
            redis:set("bot:enable:Araz"..msg.chat_id_,true)
            redis:set('floodnum:Araz'..chat_id, tonumber(5))
            redis:set('maxspam:Araz'..chat_id, tonumber(2000))
            redis:set('owners:Araz'..chat_id, msg.sender_user_id_)
            redis:sadd('owners:Araz'..msg.sender_user_id_,msg.chat_id_)
          end
--REM
          if msg.content_.text_:match("^[!][Rr]em$") and is_admin(msg) then
            if not redis:sismember('groups:Araz',chat_id) then
              return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '*Group is not added !*', 1, 'md')
            end
	     redis:srem('groups:Araz',chat_id)
		  tdcli.sendText(-1001086624506, 0, 0, 1, nil, '☘️<b>Group Has Been Removed By :</b> '..get_info(msg.sender_user_id_)..'', 1, 'html')
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<i>گروه از لیست مدیریتی حذف شد</i>\n<i>☘️حذف کننده</i>: '..get_info(msg.sender_user_id_)..'\n<i>☘️آراز ورژن 8.5</i>', 1, 'html')
            redis:del('owners:Araz'..chat_id)
            redis:srem('owners:Araz'..msg.sender_user_id_,msg.chat_id_)
            redis:del('promotes:Araz'..chat_id)
            redis:del('muteusers:Araz'..chat_id)
            redis:del('mute_user:Araz'..chat_id)
            redis:set('floodtime:Araz'..chat_id, tonumber(3))
            redis:set('floodnum:Araz'..chat_id, tonumber(5))
            redis:set('maxspam:Araz'..chat_id, tonumber(2000))
            redis:del('lock_username:Araz'..chat_id)
            redis:del('lock_link:Araz'..chat_id)
            redis:del('lock_bots:Araz'..chat_id)
            redis:del('lock_tag:Araz'..chat_id)
            redis:del('lock_forward:Araz'..chat_id)
            redis:del('lock_persian:Araz'..chat_id)
            redis:del('lock_english:Araz'..chat_id)
            redis:del('lock_curse:Araz'..chat_id)
            redis:del('lock_location:Araz'..chat_id)
            redis:del('lock_edit:Araz'..chat_id)
            redis:del('lock_caption:Araz'..chat_id)
            redis:del('lock_emoji:Araz'..chat_id)
            redis:del('lock_inline:Araz'..chat_id)
            redis:del('lock_reply:Araz'..chat_id)
            redis:del('lock_tgservice:Araz'..chat_id)
            redis:del('lock_spam:Araz'..chat_id)
            redis:del('lock_flood:Araz'..chat_id)
            redis:del('mute_all:Araz'..chat_id)
            redis:del('mute_text:Araz'..chat_id)
            redis:del('mute_game:Araz'..chat_id)
            redis:del('mute_sticker:Araz'..chat_id)
            redis:del('mute_contact:Araz'..chat_id)
            redis:del('mute_gif:Araz'..chat_id)
            redis:del('mute_voice:Araz'..chat_id)
            redis:del('mute_weblink:Araz'..chat_id)
            redis:del('mute_markdown:Araz'..chat_id)
            redis:del('mute_keyboard:Araz'..chat_id)
            redis:del('mute_photo:Araz'..chat_id)
            redis:del('mute_audio:Araz'..chat_id)
            redis:del('mute_video:Araz'..chat_id)
            redis:del('mute_document:Araz'..chat_id)
          end
          if not redis:sismember("bot:groupss:Araz",msg.chat_id_) then
            redis:sadd("bot:groupss:Araz",msg.chat_id_)
          end

          if not redis:get("bot:charge:Araz"..msg.chat_id_) then
	redis:set('bot:disable:Araz'..msg.chat_id_, true)
            if redis:get("bot:enable:Araz"..msg.chat_id_) then
              redis:del("bot:enable:Araz"..msg.chat_id_)
                tdcli.sendText(-1001086624506, 0, 0, 1, nil, "☘️شارژ اين گروه به اتمام رسيد \nLink : "..(redis:get("bot:group:link"..msg.chat_id_) or "تنظيم نشده").."\nID : "..msg.chat_id_..'\n\nدر صورتي که ميخواهيد ربات اين گروه را ترک کند از دستور زير استفاده کنيد\n\n/leave'..msg.chat_id_..'\nبراي جوين دادن توي اين گروه ميتوني از دستور زير استفاده کني:\n/join'..msg.chat_id_..'\n_________________\nدر صورتي که ميخواهيد گروه رو دوباره شارژ کنيد ميتوانيد از کد هاي زير استفاده کنيد...\n\n<code>براي شارژ 1 ماهه:</code>\n/month'..msg.chat_id_..'\n\n<code>براي شارژ 3 ماهه:</code>\n/season'..msg.chat_id_..'\n\n<code>براي شارژ نامحدود:</code>\n/unlimited'..msg.chat_id_, 1, 'html')
              tdcli.sendText(msg.chat_id_, 0,0, 1,nil, '☘شارژ گروه به اتمام رسیده است\n<i>ربات پشتیبان</i>: @NeTGuarDBot\n<i>کانال</i>: @NeTGuarD_COM', 1, 'html')
            end
          end

          redis:sadd("gp:users", msg.sender_user_id_)

        end
        if id:match('^(%d+)') then
          if not redis:get('user:limits:Araz'..msg.sender_user_id_) then
            redis:set('user:limits:Araz'..msg.sender_user_id_, 3)
          end
--PV
--Creator
          if msg.content_.text_:match("^[!]([Cc]reator)$") then
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "☘️<b>Creator and Configure:</b>@Hamidreza_Esh\n☘", 1, "html")
          end
--Araz
		  if msg.content_.text_:match("^[!]([Aa]raz)$") or msg.content_.text_:match("^[!](ARAZ)$") or msg.content_.text_:match("^(ARAZ)$") or msg.content_.text_:match("^(araz)$") or msg.content_.text_:match("^(آراز)$") then
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "☘️ورژن : 8.5\n☘️نام تیم:  نت گارد (Araz)\n☘️سازنده :‌ @Hamidreza_Esh\n☘️کانال : @NeTGuarD_COM", 1, "html")
          end
--ID
          if msg.content_.text_:match("^[!]([Ii][Dd])$") then
            local matches = {msg.content_.text_:match("^[!]([Ii][Dd]) (.*)")}
            local gid = tonumber(msg.chat_id_)
            local uid = tonumber(msg.sender_user_id_)
            local reply = msg.reply_to_message_id_
			local allgpmsgs = redis:get("bot:allgpmsgs:Araz"..msg.chat_id_)
            local usermsgs = redis:get("bot:usermsgs:Araz"..msg.chat_id_..":"..msg.sender_user_id_)
            local percent =  tonumber((usermsgs / allgpmsgs) * 100)
            local top = 1
            for k,v in pairs(redis:hkeys("bot:usermsgs:Araz"..msg.chat_id_..":*")) do
              if redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v) > top then
                top = redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v)
              end
            end
            if not matches[2] and reply == 0 then
              local function dl_photo(arg,data)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️Bot ID : '..msg.chat_id_..'\n☘️Your ID : '..msg.sender_user_id_..'\n☘️Your Messages : '..usermsgs..'(%'..string.sub(percent, 1, 4)..')'
                else
                  text = '☘️آيدي ربات : '..msg.chat_id_..'\n☘️آيدي کاربر : '..msg.sender_user_id_..'\n☘️پیام های شما : '..usermsgs..'(%'..string.sub(percent, 1, 4)..')'
                end
                tdcli.sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, data.photos_[0].sizes_[1].photo_.persistent_id_, text)
              end
              tdcli_function ({ID = "GetUserProfilePhotos",user_id_ = msg.sender_user_id_,offset_ = 0,limit_ = 1}, dl_photo, nil)
              return
            elseif reply ~= 0 then
              get_msg(reply,gid,idby_reply,{gid=gid,id=reply})
            end
          end
--Help
if msg.content_.text_:match("^[!]([Hh]elp)$") or msg.content_.text_:match("^(راهنما)$") then
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "☘️لیست دستورات‌‌ خصوصی آراز :‌‌\n\n!Araz : اطلاعات ربات\n!join support : برای عضویت در گروه پشتیبانی\n!id : برای دیدن آیدی خود و ربات\n!rules : برای دیدن قوانین گروه پشتیبانی\n!Araz list: برای دیدن لیست مدیرآراز و تخصص آنها\n!help : برای دیدن این پیام\n!creator : برای دیدن یوزرنیم سازنده ربات\n\n", 1, "html")
          end
--JoinSupport
		  if msg.content_.text_:match("^[!]([Jj]oin support)$") then
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "☘️برای عضویت در گروه پشتیبانی آراز روی لینک زیر کلیک کنید:\n https://t.me/joinchat/AAAAAEH4eUUmI9DL01zJgg \n\n", 1, "html")
          end
--Rules
		  if msg.content_.text_:match("^[!]([Rr]ules)$") then
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "☘️1.از بحث و مطرح کردن سوال هایی راجع به موضوع های متفرقه که راجع به خدمات یا ربات نیست خودداری کنید\n☘️2.سوال خود را مطرح کرده و منتظر بمانید تا مدیران پاسخ دهند و از تکرار چند باره آن خودداری کنید\n☘️3.قبل از هرکاری کانال را مشاهده کنید و درصورت پیدا نکردن جواب خود در پشتیبانی سوال خود را مطرح کنید\n☘️4.این متن قابل تغییر است و تمامی حقوق برای آراز محفوظ است \n\n", 1, "html")
          end
--ArazList
		  if msg.content_.text_:match("^[!]([Aa]raz list)$") then
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, "☘️1.حمیدرضا اسلامزاده @Hamidreza_Esh |مدیریت کل تیم و مدیریت هیات مدیره آراز \n☘️2.محمد خاتمی @MohammadKhatami |مدیر تیم و عضو هیئت مدیره آراز\n\n", 1, "html")
          end
--AutomaticAnswer
		  if not redis:sismember("bot:userss:Araz",msg.chat_id_) then
            redis:set('user:limits:Araz'..msg.sender_user_id_, 3)
            local txthelppv = [[
☘️به ربات ضد اسپم آراز ورژن 8.5 خوش آمدید

آراز یک ربات آنتی اسپم ضد تبلیغات است که با خرید آن شما میتوانید گروه خود را بااطمینان به دست آراز بسپارید.
با آراز تبلیغات و لینک و کلمات زشت و هرچیزی که میخواهید که آنها را در  گروهتان نبینید فراهم است.
ربات خود را سفارش دهید. @NeTGuarDBot پس هم اکنون با استفاده از ربات

برای دیدن لیست دستورات راهنما را ارسال کنید

☘️برای آگاهی از اخبار نیز در @NeTGuarD_COM عضو باشید!
☘️دوستدار شما تیم آراز 
            ]]
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, txthelppv , 1, "md")
            redis:sadd("bot:userss:Araz" , msg.chat_id_)
          end

--EndPV
        end
      end

--CheckSuper
      if msg and redis:sismember('bot:banned:Araz'..msg.chat_id_, msg.sender_user_id_) then
print("Baned user")
        chat_kick(msg.chat_id_, msg.sender_user_id_)
      end

      if msg and redis:sismember('bot:gbanned:Araz', msg.sender_user_id_) then
print("Gbaned user")
        chat_kick(msg.chat_id_, msg.sender_user_id_)
      end
--Report
      if msg.content_.text_:match("^[!]report") and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "en" and is_mod(msg) or msg.content_.text_:match("^ریپورت") and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "fa" and is_mod(msg) then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️*انجام شد !*\n*گزارش شما ارسال شد به :* '..redis:get('owners:Araz'..msg.chat_id_)..'', 1, 'md')
        tdcli.sendText(redis:get('owners:Araz'..msg.chat_id_), 0, 0, 1, nil, '*گزارش دهنده :* '..msg.sender_user_id_..'\n\nپیام گزارش شده :', 1, 'md')
        tdcli.forwardMessages(redis:get('owners:Araz'..msg.chat_id_), chat_id,{[0] = reply_id}, 0)
      end
--Stats
      if msg.content_.text_:match("^[!]stats$") and is_admin(msg) then
        local gps = redis:scard("bot:groupss:Araz")
        local users = redis:scard("bot:userss:Araz")
        local allmgs = redis:get("bot:allmsgs:Araz")
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️مشخصات \n#تعداد گروه:`'..gps..'`\n#تعداد مشترک:`'..users..'`\n#تعداد پیام ها:`'..allmgs..'`', 1, 'md')
      end
--StartSuper
--ID
      if msg.content_.text_:match("^[!]([Ii][Dd]) (.*)$") and is_mod(msg) then
        local matchees = {msg.content_.text_:match("^[!]([Ii][Dd]) (.*)$")}
        local gid = tonumber(msg.chat_id_)
        local uid = matchees[2]
        local function getid_photo(extra, result, success)
          tdcli.sendPhoto(result.chat_id_, result.id_, 0, 1, nil, result.photos_[0].sizes_[1].photo_.persistent_id_, 'Here ID : '..result.chat_id_..'\nHis ID : '..result.sender_user_id_..'\n')
        end
        resolve_username(matchees[2], getid_photo)
      end
--Reload
      if msg.content_.text_:match("^[!][Rr]eload$") and is_sudo(msg) then
        io.popen("killall tg")
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<i>ریلود شد!</i>', 1, 'html')
      end
--Ping
	        if msg.content_.text_:match("^[!][Pp]ing$") and is_sudo(msg) then
        tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<i> آنلاین است!</i>', 1, 'html')
      end
--broadcastgp
      if msg.content_.text_:match("^[!]bcgp (.*)") and is_sudo(msg) then
        for k,v in pairs(redis:smembers("bot:groupss:Araz")) do
          tdcli.sendText(v, 0, 0, 1, nil, msg.content_.text_:match("^[!]bcgp (.*)"), 1 , 'html')
        end
        return
      end
--broadcastuser
      if msg.content_.text_:match("^[!]bcuser (.*)") and is_sudo(msg) then
        for k,v in pairs(redis:smembers("bot:userss:Araz")) do
          tdcli.sendText(v, 0, 0, 1, nil, msg.content_.text_:match("^[!]bcuser (.*)"), 1 , 'html')
        end
        return
      end
--CheckProcessAutoleave
      if not is_added(msg) then
	if redis:get('autoleave') == "on" then
if msg and not is_admin(msg) then
          if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            text = '☘️*Bot will leave this group beacuse* `this is not one of my groups!`*For Contact with admins*: @NeTGuarDBot'
          else
            text = '☘️_ربات این گروه را ترک خواهد کرد زیرا_ `این یکی از گروه های من نیست!`_جهت ارتباط با مدیران_: @NeTGuarDBot'
          end
          tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil, text, 1, 'md')
          tdcli.changeChatMemberStatus(chat_id, tonumber(92986552), 'Left')
        end
end

      else
--SetExpireNewgroup
        if msg.content_.text_:match("^[!]setexpire (%d+)$") and is_admin(msg) then
          local day = tonumber(86400)
          local a = {string.match(msg.content_.text_, "^[!](setexpire) (%d+)$")}
          tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil, '☘️*گروه به مدت* : `'..a[2]..'` *روز شارژ شد !*', 1, 'md')
          tdcli.sendText(-1001086624506, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Set New Expire for a group !</b>\n<b>Expire : </b>"..a[2].." Day!" , 1, 'html')
          local time = a[2] * day
          redis:setex("bot:charge:Araz"..msg.chat_id_,time,true)
          redis:set("bot:enable:Araz"..msg.chat_id_,true)
	   redis:del('bot:disable:Araz'..msg.chat_id_)
        end
--setexpiresecend
	if msg.content_.text_:match("^[!]setexpires (%d+)$") and is_admin(msg) then
	   redis:del('bot:disable:Araz'..msg.chat_id_)
          local day = tonumber(1)
          local a = {string.match(msg.content_.text_, "^[!](setexpires) (%d+)$")}
          tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil, '☘️*گروه برای * : `'..a[2]..'` *ثانیه شارژ شد !*', 1, 'md')
              tdcli.sendText(-1001086624506, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Set New Expire for a group !</b>\n<b>Expire : </b>"..a[2].." Secends!" , 1, 'html')
          local time = a[2] * day
          redis:setex("bot:charge:Araz"..msg.chat_id_,time,true)
          redis:set("bot:enable:Araz"..msg.chat_id_,true)
        end
--setexpireminute
		if msg.content_.text_:match("^[!]setexpirem (%d+)$") and is_admin(msg) then
	   redis:del('bot:disable:Araz'..msg.chat_id_)
          local day = tonumber(60)
          local a = {string.match(msg.content_.text_, "^[!](setexpirem) (%d+)$")}
          tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil, '☘️*گروه برای * : `'..a[2]..'` *دقیقه شارژ شد !*', 1, 'md')
              tdcli.sendText(-1001086624506, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Set New Expire for a group !</b>\n<b>Expire : </b>"..a[2].." Minutes!" , 1, 'html')
          local time = a[2] * day
          redis:setex("bot:charge:Araz"..msg.chat_id_,time,true)
          redis:set("bot:enable:Araz"..msg.chat_id_,true)
        end
--setexpirehour
		if msg.content_.text_:match("^[!]setexpireh (%d+)$") and is_admin(msg) then
	   redis:del('bot:disable:Araz'..msg.chat_id_)
          local day = tonumber(3600)
          local a = {string.match(msg.content_.text_, "^[!](setexpireh) (%d+)$")}
          tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil, '☘️*گروه برای * : `'..a[2]..'` *ساعت شارژ شد !*', 1, 'md')
              tdcli.sendText(-1001086624506, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Set New Expire for a group !</b>\n<b>Expire : </b>"..a[2].." Hours!" , 1, 'html')
          local time = a[2] * day
          redis:setex("bot:charge:Araz"..msg.chat_id_,time,true)
          redis:set("bot:enable:Araz"..msg.chat_id_,true)
        end
--Expire
        if msg.content_.text_:match("^[!]expire") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^انقضا") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
          local ex = redis:ttl("bot:charge:Araz"..msg.chat_id_)
          if ex == -1 then
            tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil ,'☘️*نامحدود !*', 1, 'md')
          else
            local day = tonumber(86400)
            local d = math.floor(ex / day ) + 1
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = "☘️*This Group Have Charge for* `"..d.."` *Days and after that will be expired!*"
            else
              text = "☘️_شارژ این گروه به مدت_ `"..d.."` _روز است_"
            end
            tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil , text, 1, 'md')
          end
        end
--Expirecheck
        if msg.content_.text_:match("^[!]expire (%d+)") and is_admin(msg) then
          local txt = {string.match(msg.content_.text_, "^[!](expire) (%d+)$")}
          local ex = redis:ttl("bot:charge:Araz"..txt[2])
          if ex == -1 then
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️*Unlimited!*'
            else
              text = '☘️`نامحدود!`'
            end
            tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil  ,text, 1, 'md')
          else
            local day = tonumber(86400)
            local d = math.floor(ex / day ) + 1
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = "☘️*This Group Have Charge for* `"..d.."` *Days and after that will be expired!*"
            else
              text = "☘️_شارژ این گروه به مدت_ `"..d.."` _روز است_"
            end
            tdcli.sendText(msg.chat_id_, msg.id_, 0 ,1 , nil ,text, 1, 'md')
          end
        end
--StartPlan
        if is_sudo(msg) then
--PlanMonth
		if msg.content_.text_:match('^!month(-%d+)') and is_admin(msg) then
            local txt = {string.match(msg.content_.text_, "^!(month)(-%d+)$")}
            local timeplan1 = 2592000
            redis:setex("bot:charge:Araz"..txt[2],timeplan1,true)
	     redis:del('bot:disable:Araz'..txt[2])
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1,nil, '☘️پلن ماهانه با موفقيت براي گروه '..txt[2]..' فعال شد\nاين گروه تا 30 روز ديگر اعتبار دارد! ( 1 ماه )', 1, 'md')
            tdcli.sendText(txt[2], 0, 0, 1,nil, '☘️ربات با موفقيت فعال شد و تا 30 روز ديگر اعتبار دارد!', 1, 'md')
            for k,v in pairs(sudo_users) do
              tdcli.sendText(v, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Used a New Plan For a Group !</b>\n<b>Group id : </b>"..txt[2].."" , 1, 'html')
            end
            redis:set("bot:enable:Araz"..txt[2],true)
          end
--Plan3Month
          if msg.content_.text_:match('^!season(-%d+)') and is_admin(msg) then
            local txt = {string.match(msg.content_.text_, "^!(season)(-%d+)$")}
            local timeplan2 = 7776000
	     redis:del('bot:disable:Araz'..txt[2])
            redis:setex("bot:charge:Araz"..txt[2],timeplan2,true)
            tdcli.sendText(msg.chat_id_, msg.id_,0,1,nil, '☘️پلن فصلی با موفقيت براي گروه '..txt[2]..' فعال شد\nاين گروه تا 90 روز ديگر اعتبار دارد! ( 3 ماه )', 1, 'md')
            tdcli.sendText(txt[2], 0, 0, 1,nil, '☘️ربات با موفقيت فعال شد و تا 90 روز ديگر اعتبار دارد!', 1, 'md')
            for k,v in pairs(sudo_users) do
              tdcli.sendText(v, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Used a New Plan For a Group !</b>\n<b>Group id :</b> "..txt[2].."" , 1, 'html')
            end
            redis:set("bot:enable:Araz"..txt[2],true)
          end
--PlanUnlimited
          if msg.content_.text_:match('^!unlimited(-%d+)') and is_admin(msg) then
            local txt = {string.match(msg.content_.text_, "^!(unlimited)(-%d+)$")}
            redis:set("bot:charge:Araz"..txt[2],true)
	     redis:del('bot:disable:Araz'..txt[2])
            tdcli.sendText(msg.chat_id_, msg.id_,0, 1,nil, '☘️پلن نامحدود با موفقيت براي گروه '..txt[2]..' فعال شد\nاين گروه به صورت نامحدود شارژ شد!', 1, 'md')
            tdcli.sendText(txt[2], 0,0, 1,nil,'☘️ربات بدون محدوديت فعال شد !', 1, 'md')
            for k,v in pairs(sudo_users) do
              tdcli.sendText(v, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Used a New Plan For a Group !</b>\n<b>Group id :</b> "..txt[2].."" , 1, 'html')
            end
            redis:set("bot:enable:Araz"..txt[2],true)
          end
--Joingap
          if msg.content_.text_:match('!join(-%d+)') and is_admin(msg) then
            local txt = {string.match(msg.content_.text_, "^!(join)(-%d+)$")}
			redis:set('admin',msg.sender_user_id_)
            tdcli.sendText(msg.chat_id_, msg.id_,0, 1,nil, '☘️با موفقيت تورو به گروه '..txt[2]..' اضافه کردم.', 1, 'md')
            tdcli.sendText(txt[2], 0, 0, 1,nil, '☘️ادمین ربات وارد گروه میشود ! \nادمین :'..get_info(redis:get('admin')), 1, 'md')
               tdcli.sendText(-1001086624506, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Has added to this group !</b>\n<b>Group ID : </b>"..txt[2].."" , 1, 'html')
               tdcli.addChatMember(txt[2], msg.sender_user_id_, 10)
          end
        end
--check disable 
 if redis:get('bot:disable:Araz'..msg.chat_id_) then
	      return
		else
        if not redis:hget(msg.chat_id_, "lang:Araz") then
          redis:hset(msg.chat_id_,"lang:Araz", "en")
        end
        --[[if redis:hget('gp:cmd'..msg.chat_id_) == 0 then
          redis:hset('gp:cmd'..msg.chat_id_, "mod")
          end]]
--SetlangFa
			           if msg.content_.text_:match("^[!][Ss]etlang fa$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^تنظیم زبان فارسی$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
 if redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
  text = "☘️_زبان گروه پیش از این فارسی بوده است_"
            else
              text = "☘️*Group Language:* `Farsi`"
            end
            redis:hset(msg.chat_id_,"lang:Araz", "fa")
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1 , "md")

		  end
--SetlangEn
          if msg.content_.text_:match("^[!][Ss]etlang en$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^تنظیم زبان انگلیسی$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            if redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
              text = "☘️*زبان گروه:* `انگليسي`"
            else
              text = "☘️*Group language have been already English!*"
            end
            redis:hset(msg.chat_id_,"lang:Araz", "en")
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1 , "md")
          end
--Lang
          if msg.content_.text_:match("^[!]lang$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^زبان$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            if redis:hget(msg.chat_id_ , "lang:Araz") == "fa" then
              text = "☘️_زبان گروه_: `فارسی`"
            else
              text = "☘️*Group Language*: `English`"
            end
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil , text, 1 , "md")
          end
--Setcmd
          if msg.content_.text_:match("^[!][Ss]etcmd (.*)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local matches = {string.match(msg.content_.text_, "^[!]([Ss]etcmd) (.*)$")}
            if matches[2] == "owner" then
              redis:set("gp:cmd"..msg.chat_id_, "owner")
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️*Commands now for:* `Owner`"
              else
                text = "☘️*دسترسی برای :* `مالک`"
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, "md")
            elseif matches[2] == "mod" then
              redis:set("gp:cmd"..msg.chat_id_, "mod")
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️*Commands now for :* `Mods`"
              else
                text = "☘️*دسترسی براي :* `ناظم ها`"
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, "md")
            elseif matches[2] == "all" then
              redis:set("gp:cmd"..msg.chat_id_, "all")
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️*Commands now for :* `All`"
              else
                text = "☘️*دسترسی براي :* `همه`"
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, "md")
            end
          end
--SetCmdFa
          if msg.content_.text_:match("^تنظیم دسترسی (.*)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local matches = {string.match(msg.content_.text_, "^(تنظیم دسترسی) (.*)$")}
            if matches[2] == "مالک" then
              redis:set("gp:cmd"..msg.chat_id_, "owner")
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️*Commands now for:* `Owner`"
              else
                text = "☘️*دسترسی برای :* `مالک`"
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, "md")
            elseif matches[2] == "ناظم" then
              redis:set("gp:cmd"..msg.chat_id_, "mod")
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️*Commands now for :* `Mods`"
              else
                text = "☘️*دسترسی براي :* `ناظم ها`"
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, "md")
            elseif matches[2] == "همه" then
              redis:set("gp:cmd"..msg.chat_id_, "all")
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️*Commands now for :* `All`"
              else
                text = "☘️*دسترسی براي :* `همه`"
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, "md")
            end
          end
--Me
          if msg.content_.text_:match("^[!][Mm][Ee]$") and redis:hget(msg.chat_id_, "lang:Araz") == "en" and is_mod(msg) then
            local allgpmsgs = redis:get("bot:allgpmsgs:Araz"..msg.chat_id_)
            local usermsgs = redis:get("bot:usermsgs:Araz"..msg.chat_id_..":"..msg.sender_user_id_)
            local percent =  tonumber((usermsgs / allgpmsgs) * 100)
            local top = 1
            for k,v in pairs(redis:hkeys("bot:usermsgs:Araz"..msg.chat_id_..":*")) do
              if redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v) > top then
                top = redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v)
              end
            end
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = "☘️<b>All of your messages:</b> <code>"..usermsgs.."</code>\n☘️<b>All of group messages:</b> <code>"..allgpmsgs.."</code>\n☘️<b>Percent of your messages:</b> <code>%"..string.sub(percent, 1, 4).."</code>\n☘️<b>Your info: </b>"..get_info(msg.sender_user_id_)..""
            else
              text = "☘️<i>کل پیام های شما:</i> <code>"..usermsgs.."</code>\n☘️<i>کل پیام های گروه:</i> <code>"..allgpmsgs.."</code>\n☘️<i>درصد پیام های شما:</i> <code>%"..string.sub(percent, 1, 4).."</code>\n☘️<i>اطلاعات شما:</i>"..get_info(msg.sender_user_id_)..""
            end
            tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, "html")
          end

--ProcessSuperGroup
          if msg.content_.text_  then
		  
		    if redis:get('lock_bots:Araz'..chat_id) and not is_mod(msg) then
             local userbot = get_username(msg.sender_user_id_)      
            if userbot:match("(.*)[Bb][Oo][Tt]") then
             tdcli.deleteMessages(chat_id, {[0] = msg.id_})
             tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
            end
            end

            local is_link = msg.content_.text_:find("[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/") or msg.content_.text_:find("[Tt].[Mm][Ee]/")
            if redis:get('lock_link:Araz'..chat_id) and is_link and not is_mod(msg) then
			tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
            if redis:get('lock_tag:Araz'..chat_id) and msg.content_.text_:find("#") and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            if redis:get('lock_username:Araz'..chat_id) and msg.content_.text_:find("@") and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            if redis:get('lock_persian:Araz'..chat_id) and msg.content_.text_:find("[\216-\219][\128-\191]") and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            local is_english_msg = msg.content_.text_:find("[a-z]") or msg.content_.text_:find("[A-Z]")
            if redis:get('lock_english:Araz'..chat_id) and is_english_msg and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            local is_curse_msg = msg.content_.text_:find("کیر") or msg.content_.text_:find("کص") or msg.content_.text_:find("کس") or msg.content_.text_:find("کون") or msg.content_.text_:find("جنده") or msg.content_.text_:find("قهبه") or msg.content_.text_:find("گایید") or msg.content_.text_:find("سکس") or msg.content_.text_:find("kir") or msg.content_.text_:find("kos") or msg.content_.text_:find("kon")
            if redis:get('lock_curse:Araz'..chat_id) and is_curse_msg and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            local is_emoji_msg = input:match("😀") or input:match("😬") or input:match("😁") or input:match("😂") or  input:match("😃") or input:match("😄") or input:match("😅") or input:match("☺️") or input:match("🙃") or input:match("🙂") or input:match("😊") or input:match("😉") or input:match("😇") or input:match("😆") or input:match("😋") or input:match("😌") or input:match("😍") or input:match("😘") or input:match("😗") or input:match("😙") or input:match("😚") or input:match("🤗") or input:match("😎") or input:match("🤓") or input:match("🤑") or input:match("😛") or input:match("😏") or input:match("😶") or input:match("😐") or input:match("😑") or input:match("😒") or input:match("🙄") or input:match("🤔") or input:match("😕") or input:match("😔") or input:match("😡") or input:match("😠") or input:match("😟") or input:match("😞") or input:match("😳") or input:match("🙁") or input:match("☹️") or input:match("😣") or input:match("😖") or input:match("😫") or input:match("😩") or input:match("😤") or input:match("😲") or input:match("😵") or input:match("😭") or input:match("😓") or input:match("😪") or input:match("😥") or input:match("😢") or input:match("🤐") or input:match("😷") or input:match("🤒") or input:match("🤕") or input:match("😴") or input:match("💋") or input:match("❤️")
            if redis:get('lock_emoji:Araz'..chat_id) and is_emoji_msg and not is_mod(msg)  then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end


            if redis:get('lock_inline:Araz'..chat_id) and  msg.via_bot_user_id_ ~= 0 and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            if redis:get('lock_reply:Araz'..chat_id) and  msg.reply_to_message_id_ ~= 0 and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            if redis:get('mute_user:Araz'..chat_id) and is_normal(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end

            for k,v in pairs(redis:smembers('filters:'..msg.chat_id_)) do
              if string.find(msg.content_.text_:lower(), v) and not is_mod(msg) then
                tdcli.deleteMessages(chat_id, {[0] = msg.id_})
              end
            end
          end
--StartClean
--Modlist
 if msg.content_.text_:match("^[!]clean modlist$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^پاک کردن لیست ناظم ها$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            redis:del('promotes:Araz'..msg.chat_id_)
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️*modlist had cleaned!*'
            else
              text = '☘️ليست ناظم ها پاک شد!'
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
--MuteList
          if msg.content_.text_:match("^[!]clean mutelist$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^پاک کردن لیست ساکت شدگان$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘*mutelist has cleaned!*'
            else
              text = '☘️ليست افراد ساکت شده پاک شد!'
            end
            redis:del('muteusers:Araz'..msg.chat_id_)
            redis:del('mute_user:Araz'..msg.chat_id_)
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
--Banlist
          if msg.content_.text_:match("^[!]clean banlist$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^پاک کردن لیست بن شدگان$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️*Banlist has cleaned!*'
            else
              text = '☘️ليست اعضاي بن شده پاک شد!'
            end
            redis:del('bot:banned:Araz'..msg.chat_id_)
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
--Rules
          if msg.content_.text_:match("^[!]clean rules$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^پاک کردن قوانین$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️*Rules has cleaned!*'
            else
              text = '☘قوانین پاک شد!'
            end
            redis:del('bot:rules'..msg.chat_id_)
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
--FilterList
          if msg.content_.text_:match("^[!]clean filterlist$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^پاک کردن لیست فیلتر$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️*filterlist has cleaned!*'
            else
              text = '☘لیست فیلتر پاک شد!'
            end
            redis:del('filters:'..msg.chat_id_)
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
--Gbanlist
		    if msg.content_.text_:match("^[!]clean gbanlist$") and is_sudo(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️Globalbanlist has cleaned!'
            else
              text = '☘️ليست اعضای گلوبال بن شده پاک شد!'
            end
            redis:del('bot:gbanned:Araz')
			tdcli.sendText(-1001104922723, 0, 0,1,nil, "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>has deleted gbanlist !</b>" , 1, 'html')
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
          -------------------------------------------------------------
          if redis:get("bot:group:link"..msg.chat_id_) == 'Link Set Status : `Waiting !`' and is_mod(msg) then
            if msg.content_.text_:match("(https://telegram.me/joinchat/%S+)") or msg.content_.text_:match("(https://t.me/joinchat/%S+)") then
              local glink = msg.content_.text_:match("(https://telegram.me/joinchat/%S+)") or msg.content_.text_:match("(https://t.me/joinchat/%S+)")
              local hash = "bot:group:link"..msg.chat_id_
              redis:set(hash,glink)
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*NewLink Seted!*'
              else
                text = '☘️_لينک جديد ذخیره شد!_'
              end
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
            end
          end
--ID SUPERGROUP
          if msg.content_.text_:match("^[!][Ii][Dd]$") and redis:hget(msg.chat_id_, "lang:Araz") == "en" and is_mod(msg) or msg.content_.text_:match("^آیدی$") and redis:hget(msg.chat_id_, "lang:Araz") == "fa" and is_mod(msg) then
            local matches = {msg.content_.text_:match("^[!][Ii][Dd] (.*)")}
            local gid = tonumber(msg.chat_id_)
            local uid = tonumber(msg.sender_user_id_)
            local reply = msg.reply_to_message_id_
			            local allgpmsgs = redis:get("bot:allgpmsgs:Araz"..msg.chat_id_)
            local usermsgs = redis:get("bot:usermsgs:Araz"..msg.chat_id_..":"..msg.sender_user_id_)
            local percent =  tonumber((usermsgs / allgpmsgs) * 100)
            local top = 1
            for k,v in pairs(redis:hkeys("bot:usermsgs:Araz"..msg.chat_id_..":*")) do
              if redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v) > top then
                top = redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v)
              end
            end
            if not matches[2] and reply == 0 then
              local function dl_photo(arg,data)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️SuperGroup ID : '..string.sub(chat_id, 5,14)..'\n☘️User ID : '..msg.sender_user_id_..'\n☘️Your Messages : '..usermsgs..'(%'..string.sub(percent, 1, 4)..')\n☘️Use "profile [1-'..data.total_count_..']" to see your special profile!'
                else
                  text = '☘️آيدي گروه : '..string.sub(chat_id, 5,14)..'\n☘️آيدي شخص : '..msg.sender_user_id_..'\n☘️پیام های شما : '..usermsgs..'(%'..string.sub(percent, 1, 4)..')\n☘️از پروفایل 1-'..data.total_count_..' استفاده کنید تا پروفایل مخصوص خود را ببینید!'
                end
                tdcli.sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, data.photos_[0].sizes_[1].photo_.persistent_id_, text)
              end
              tdcli_function ({ID = "GetUserProfilePhotos",user_id_ = msg.sender_user_id_,offset_ = 0,limit_ = 1}, dl_photo, nil)
              return
            elseif reply ~= 0 then
              get_msg(reply,gid,idby_reply,{gid=gid,id=reply})
            end
          end
--Profile
if msg.content_.text_:match("^!profile (.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
  profilematches = {string.match(msg.content_.text_, "^!profile (.*)$")}
              local gid = tonumber(msg.chat_id_)
            local uid = tonumber(msg.sender_user_id_)
            local reply = msg.reply_to_message_id_
			local allgpmsgs = redis:get("bot:allgpmsgs:Araz"..msg.chat_id_)
            local usermsgs = redis:get("bot:usermsgs:Araz"..msg.chat_id_..":"..msg.sender_user_id_)
            local percent =  tonumber((usermsgs / allgpmsgs) * 100)
            local top = 1
            for k,v in pairs(redis:hkeys("bot:usermsgs:Araz"..msg.chat_id_..":*")) do
              if redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v) > top then
                top = redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v)
              end
            end
  local function dl_photo(arg,data)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️SuperGroup ID : '..string.sub(chat_id, 5,14)..'\n☘️User ID : '..msg.sender_user_id_..'\n☘️Your Messages : '..usermsgs..'(%'..string.sub(percent, 1, 4)..')\n☘️This Profile : '..profilematches[1]..'\n☘️Use "profile [1-'..data.total_count_..']" to see your special profile!'
                else
                  text = '☘️آيدي گروه : '..string.sub(chat_id, 5,14)..'\n☘️آيدي شخص : '..msg.sender_user_id_..'\n☘️پیام های شما : '..usermsgs..'(%'..string.sub(percent, 1, 4)..')\n☘️این پروفایل : '..profilematches[1]..'\n\n☘️از پروفایل 1-'..data.total_count_..' استفاده کنید تا پروفایل مخصوص خود را ببینید!'
                end
				  tdcli.sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, data.photos_[0].sizes_[1].photo_.persistent_id_, text)
  end
  tdcli.getUserProfilePhotos(user_id, profilematches[1] - 1, profilematches[1], dl_photo, nil)
end
--Profile Farsi
if msg.content_.text_:match("^پروفایل (.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
  profilematches = {string.match(msg.content_.text_, "^پروفایل (.*)$")}
              local gid = tonumber(msg.chat_id_)
            local uid = tonumber(msg.sender_user_id_)
            local reply = msg.reply_to_message_id_
			local allgpmsgs = redis:get("bot:allgpmsgs:Araz"..msg.chat_id_)
            local usermsgs = redis:get("bot:usermsgs:Araz"..msg.chat_id_..":"..msg.sender_user_id_)
            local percent =  tonumber((usermsgs / allgpmsgs) * 100)
            local top = 1
            for k,v in pairs(redis:hkeys("bot:usermsgs:Araz"..msg.chat_id_..":*")) do
              if redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v) > top then
                top = redis:get("bot:usermsgs:Araz"..msg.chat_id_":"..v)
              end
            end
  local function dl_photo(arg,data)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️SuperGroup ID : '..string.sub(chat_id, 5,14)..'\n☘️User ID : '..msg.sender_user_id_..'\n☘️Your Messages : '..usermsgs..'(%'..string.sub(percent, 1, 4)..')\n☘️This Profile : '..profilematches[1]..'\n☘️Use "profile [1-'..data.total_count_..']" to see your special profile!'
                else
                  text = '☘️آيدي گروه : '..string.sub(chat_id, 5,14)..'\n☘️آيدي شخص : '..msg.sender_user_id_..'\n☘️پیام های شما : '..usermsgs..'(%'..string.sub(percent, 1, 4)..')\n☘️این پروفایل : '..profilematches[1]..'\n\n☘️از پروفایل 1-'..data.total_count_..' استفاده کنید تا پروفایل مخصوص خود را ببینید!'
                end
				  tdcli.sendPhoto(msg.chat_id_, msg.id_, 0, 1, nil, data.photos_[0].sizes_[1].photo_.persistent_id_, text)
  end
  tdcli.getUserProfilePhotos(user_id, profilematches[1] - 1, profilematches[1], dl_photo, nil)
end
--SetRules
          if msg.content_.text_:match("^[!]setrules (.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local txt = {string.match(msg.content_.text_, "^[!](setrules) (.*)$")}
            redis:set('bot:rules'..msg.chat_id_, txt[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️*Rules Seted!*'
            else
              text = '☘️*قوانين تنظيم شد!*'
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
--SetRulesFa
          if msg.content_.text_:match("^تنظیم قوانین (.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local txt = {string.match(msg.content_.text_, "^(تنظیم قوانین) (.*)$")}
            redis:set('bot:rules'..msg.chat_id_, txt[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️*Rules Seted!*'
            else
              text = '☘️*قوانين تنظيم شد!*'
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
--Rules
          if msg.content_.text_:match("^[!]rules$") and msg.chat_id_:match('-100(%d+)') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^قوانین$") and msg.chat_id_:match('-100(%d+)') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local rules = redis:get('bot:rules'..msg.chat_id_)
            if not rules then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                rules = '☘️<b>Any Rules do not save yet!</b>'
              else
                rules = '☘️<i>قوانيني تاکنون برای گروه ثبت نشده است!</i>'
              end
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, rules, 1, 'html')
          end
--Pin
          if msg.content_.text_:match("^سنجاق$")  and msg.reply_to_message_id_ and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Pp][Ii][Nn]$")  and msg.reply_to_message_id_ and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            tdcli.pinChannelMessage(msg.chat_id_, msg.reply_to_message_id_, 0)
          end
--UnPin
          if msg.content_.text_:match("^حذف سنجاق$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[!][Uu][Nn][Pp][Ii][Nn]$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️<b>Message UnPinned</b>'
            else
              text = '☘️<i>پيام سنجاق حذف شد!</i>'
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
            tdcli.unpinChannelMessage(chat_id)
          end
--SetPrice
          if msg.content_.text_:match("^[!]setprice (.*)$") and is_sudo(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local txt = {string.match(msg.content_.text_, "^[!](setprice) (.*)$")}
            redis:set('bot:price', txt[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️*Price Seted!*'
            else
              text = '☘️*نرخ تنظيم شد!*'
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
          end
--Price
          if msg.content_.text_:match("^[!]price$") and msg.chat_id_:match('-100(%d+)') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^نرخ$") and msg.chat_id_:match('-100(%d+)') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local price = redis:get('bot:price')
            if not price then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                price = '☘️<b>Any price do not save yet!</b>'
              else
                price = '☘️<i>قوانيني تاکنون برای گروه ثبت نشده است!</i>'
              end
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, price, 1, 'html')
          end
--Help
          if msg.content_.text_:match("^راهنما$") and msg.chat_id_:match('^-100(%d+)') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Hh][eE]lp$") and msg.chat_id_:match('^-100(%d+)') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            if redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
              help = [[لیست دستورات کمکی آراز:
☘️قفل ها :
☘️قفل حساسیت
☘️قفل اسپم
☘️قفل لینک
☘️قفل تگ
☘قفل یوزرنیم
☘️قفل فوروارد
☘️قفل فارسی
☘️قفل انگلیسی
☘️قفل پاسخ
☘️قفل کلمات زشت
☘️قفل ویرایش 
☘قفل موقعیت
☘️قفل کپشن
☘️قفل اینلاین
☘️قفل شکلک
☘️قفل همه 
☘️قفل کیبورد
☘️قفل استیکر
☘️قفل بازی
☘قفل گیف
☘️قفل مخاطب
☘️قفل عکس
☘️قفل آهنگ
☘️قفل صدا 
☘️قفل فیلم
☘️قفل فایل
☘️قفل متن

⚠️برای باز کردن هر یک از قفل های بالا بجای قفل یک باز کردن اضافه کنید.
مثال:
قفل متن ➡️باز کردن متن
➖➖➖➖➖➖➖➖➖➖
☘️فیلتر [کلمه ]
برای فیلتر کردن کلمه ای ( کلمه فیلتر شده در صورت مشاهده در پیامی , پیام حذف میشود )
مثلا :
فیلتر کلمه

☘️حذف فیلتر [کلمه]
برای درآوردن کلمه از لیست کلمات فیلتر شده
☘️لیست فیلتر
برای دیدن لیست کلمات فیلتر شده
➖➖➖➖➖➖➖➖➖➖
☘️تنظیم قوانین [متن قوانین]
برای تعیین متنی به عنوان قوانین گروه . مثلا :
تنظیم قوانین لطفا بی ادبی نکنید

☘️قوانین
برای گرفتن قوانین تعیین شده توسط ربات
➖➖➖➖➖➖➖➖➖➖
☘️ارتقا [ریپلای]
برای ارتقای شخصی به عنوان مدیر
ارتقا
با ریپلای کردن به پیام شخصی که میخواهید مدیر شود اورا مدیر کنید
☘️لیست مدیران
برای گرفتن لیست مدیر ها
➖➖➖➖➖➖➖➖➖➖
☘️تنظیمات
برای گرفتن لیست تنظیمات گروه !
☘️آیدی
برای گرفتن آیدی عددی خود زیر عکس پروفایلتان و همچنین آیدی عددی گروه
➖➖➖➖➖➖➖➖➖➖
☘️تنظیم اسپم  [عدد]
برای تعیین حذف کردن پیام هایی شامل بیشتر از کاراکتر تعریف شده‌(‌بزرگی پیام )(در صورتی کار میکنم ک !lock spam زده باشید )
مثلا :
تنظیم اسپم 2000
➖➖➖➖➖➖➖➖➖➖
☘️تنظیم زمان حساسیت [2-20]
برای تعیین مدت زمان( بر حسب ثانیه ) چک کردن تعداد پیام های داده شده شخص برای تشخیص رگباری بودن یا نبودن پیام هاش ( معمولیش 2 هست ) مثلا :
تنظیم زمان حساسیت 3


☘️تنظیم تعداد حساسیت [4-30]
برای تعیین تعداد پیام های مجازی رگباری در مدت زمان تعیین شده ( باید !lock flood هم در مورد بالا هم در این مورد فعال باشد ) مثلا :
تنظیم تعداد حساسیت 10
➖➖➖➖➖➖➖➖➖➖
☘️من
برای دادن آمار پیام ها و شخص فعال گروه
➖➖➖➖➖➖➖➖➖➖
☘️تنظیم زبان [فارسی/انگلیسی]
برای تنظیم زبان ربات به فارسی یا انگلیسی کافیه یکی از اون عبارت هارا بزاری جلوش مثلا :
تنظیم زبان فارسی

☘️زبان
برای گرفتن زبان گروه
➖➖➖➖➖➖➖➖➖➖
☘️حذف پیام
با ریپلای به پیام شخص توسط مدیر , پیام شخص حذف میشه
➖➖➖➖➖➖➖➖➖➖
☘️اخراج [ریپلای]
برای حذف کردن شخص از گروه با یوزرنیم یا آیدی عددی شخص , با ریپلای هم باید خالی بنویسی !kick تا حذف کنه
➖➖➖➖➖➖➖➖➖➖
☘️بن [ریپلای]
برای بن کردن شخص از گره تا اگر باری دیگر آمد ربات باز حذفش کنه
☘️آنبن [ریپلای]
برای آنبن کردن شخص تا بتونه بیاد
☘️لیست بن
برای دیدن لیست اعضای بن شده
➖➖➖➖➖➖➖➖➖➖
☘️ساکت کردن [ریپلای]
برای سایلنت کردن شخص با یوزرنیم یا آیدی عددی , با ریپلای هم خالی بنویس !muteuser
شخص اگر حرف بزنه پیامش حذف میشه
☘️آزاد کردن [ریپلای]
برای خارج کردن شخص از لیست سایلنت شده ها , با ریپلای ساده بنویس !unmuteuser
☘️لیست ساکت
برای دیدن لیست اعضای حذف شده !
➖➖➖➖➖➖➖➖➖➖
☘️تنظیم نام (اسم گروه)
برای تغیر اسم گروه
☘️ویرایش (متن)
با ریپلای کردن به یه پیام ربات و نوشتن متنتون , ربات پیام خودشو به متن شما تغییر میده و ادیت میکنه
➖➖➖➖➖➖➖➖➖➖
☘️سنجاق
با ریپلای به پیامی ربات پیام شما را پین میکنه
☘️حذف سنجاق
ساده بنویسید تا ربات پیام پین شده را برداره
➖➖➖➖➖➖➖➖➖➖
☘️پاک کردن [لیست ناظم ها/لیست بن شدگان/لیست ساکت شدگان/قوانین]
برای پاک کردن لیست مدیرت ها و ربات های گروه و اعضای بن شده و اعضای ساکت شده به کار میره مثلا :
پاک کردن لیست ناظم ها
➖➖➖➖➖➖➖➖➖➖
ورژن 8.5 آراز
کانال ما : @NeTGuarD_COM
]]
            else
help = [[لیست دستورات کمکی آراز:
☘️قفل ها :
☘️!lock  flood(قفل پیام های رگباری)
☘️!lock  spam(قفل پیام های حاوی متن طولانی)
☘️!lock  link(قفل لینک های تلگرامی)
☘️!lock  tag(# قفل پیام های حاوی هشتگ) 
☘️!lock  username (@ قفل پیام حاوی اتساین)
☘️!lock  fwd (قفل فوروارد)
☘️!lock  persian (قفل حروف فارسی)  
☘️!lock  english(قفل حروف انگلیسی)
☘️!lock  reply  (قفل کردن امکان ریپلای به پیام مخاطب)
☘️!lock  curse(قفل کلمات زشت)
☘️!lock  edit(قفل کردن امکان ویرایش پیام) 
☘️!lock  location (ممنوعیت اشتراک مکان) 
☘️!lock  caption (ممنوعیت عکس و ... شامل متن زیری)
☘️!lock  inline(ممنوعیت استفاده از خاصیت اینلاین ربات ها)
☘️!lock  emoji(ممنوعیت شکلک)
☘️!lock  all(تعطیل کردن گروه) 
☘️!lock  keyboard(ممنوعیت دکمه های شیشه ای)
☘️!lock  sticker(ممنوعیت استیکر) 
☘️!lock  game(ممنوعیت بازی های تلگرامی) 
☘️!lock  gif(ممنوعیت تصاویر متحرک)
☘️!lock  contact(ممنوعیت اشتراک مخاطب)
☘️!lock  photo(ممنوعیت تصویر)
☘️!lock  audio(ممنوعیت فایل موسیقی)
☘️!lock  voice(ممنوعیت پیام صوتی) 
☘️!lock  video(ممنوعیت فیلم)
☘️!lock  document(ممنوعیت فایل)
☘️!lock  text(ممنوعیت پیام متنی)

⚠️برای باز کردن هر یک از قفل های بالا به قبل از lock یک un اضافه کنید.
مثال:
lock text ➡️unlock text
➖➖➖➖➖➖➖➖➖➖
☘️!filter کلمه
برای فیلتر کردن کلمه ای ( کلمه فیلتر شده در صورت مشاهده در پیامی , پیام حذف میشود )
مثلا :
!filter کلمه

☘️!unfilter کلمه
برای درآوردن کلمه از لیست کلمات فیلتر شده
☘️!filterlist
برای دیدن لیست کلمات فیلتر شده
➖➖➖➖➖➖➖➖➖➖
☘️!setrules [متن قوانین]
برای تعیین متنی به عنوان قوانین گروه . مثلا :
!setrules لطفا بی ادبی نکنید

☘️!rules
برای گرفتن قوانین تعیین شده توسط ربات
➖➖➖➖➖➖➖➖➖➖
☘️!promote [یوزرنیم,آی دی]
برای ارتقای شخصی به عنوان مدیر
!promote
با ریپلای کردن به پیام شخصی که میخواهید مدیر شود اورا مدیر کنید
☘️!modlist
برای گرفتن لیست مدیر ها
➖➖➖➖➖➖➖➖➖➖
☘️!settings
برای گرفتن لیست تنظیمات گروه !
☘️!id
برای گرفتن آیدی عددی خود زیر عکس پروفایلتان و همچنین آیدی عددی گروه
➖➖➖➖➖➖➖➖➖➖
☘️!setspam  [عدد]
برای تعیین حذف کردن پیام هایی شامل بیشتر از کاراکتر تعریف شده‌(‌بزرگی پیام )(در صورتی کار میکنم ک !lock spam زده باشید )
مثلا :
!setspam 2000
➖➖➖➖➖➖➖➖➖➖
☘️!setfloodtime [2-20]
برای تعیین مدت زمان( بر حسب ثانیه ) چک کردن تعداد پیام های داده شده شخص برای تشخیص رگباری بودن یا نبودن پیام هاش ( معمولیش 2 هست ) مثلا :
!setfloodtime 2


☘️!setfloodnum [5-30]
برای تعیین تعداد پیام های مجازی رگباری در مدت زمان تعیین شده ( باید !lock flood هم در مورد بالا هم در این مورد فعال باشد ) مثلا :
!setfloodnum 10
➖➖➖➖➖➖➖➖➖➖
☘️!me
برای دادن آمار پیام ها و شخص فعال گروه
➖➖➖➖➖➖➖➖➖➖
☘️!setlang [fa/en]
برای تنظیم زبان ربات به فارسی یا انگلیسی کافیه یکی از اون عبارت هارا بزاری جلوش مثلا :
!setlang fa

☘️!lang
برای گرفتن زبان گروه
➖➖➖➖➖➖➖➖➖➖
☘️!del
با ریپلای به پیام شخص توسط مدیر , پیام شخص حذف میشه
➖➖➖➖➖➖➖➖➖➖
☘️!kick [username / id ]
برای حذف کردن شخص از گروه با یوزرنیم یا آیدی عددی شخص , با ریپلای هم باید خالی بنویسی !kick تا حذف کنه
➖➖➖➖➖➖➖➖➖➖
☘️!ban [username / id ]
برای بن کردن شخص از گره تا اگر باری دیگر آمد ربات باز حذفش کنه
☘️!unban [username / id]
برای آنبن کردن شخص تا بتونه بیاد
☘️!banlist
برای دیدن لیست اعضای بن شده
➖➖➖➖➖➖➖➖➖➖
☘️!muteuser [username / id]
برای سایلنت کردن شخص با یوزرنیم یا آیدی عددی , با ریپلای هم خالی بنویس !muteuser
شخص اگر حرف بزنه پیامش حذف میشه
☘️!unmuteuser [username / id]
برای خارج کردن شخص از لیست سایلنت شده ها , با ریپلای ساده بنویس !unmuteuser
☘️!mutelist
برای دیدن لیست اعضای حذف شده !
➖➖➖➖➖➖➖➖➖➖
☘️!setname (اسم گروه)
برای تغیر اسم گروه
☘️!edit (متن)
با ریپلای کردن به یه پیام ربات و نوشتن متنتون , ربات پیام خودشو به متن شما تغییر میده و ادیت میکنه
➖➖➖➖➖➖➖➖➖➖
☘️!pin
با ریپلای به پیامی ربات پیام شما را پین میکنه
☘️!unpin
ساده بنویسید تا ربات پیام پین شده را برداره
➖➖➖➖➖➖➖➖➖➖
☘️!clean [modlist/banlist/mutelist/rules]
برای پاک کردن لیست مدیرت ها و ربات های گروه و اعضای بن شده و اعضای ساکت شده به کار میره مثلا :
!clean mutelist
➖➖➖➖➖➖➖➖➖➖
ورژن 8.5 آراز
کانال ما : @NeTGuarD_COM
]]
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, help, 1, 'html')
          end
          if msg.content_.text_:match("^!addadmin$") and is_sudo(msg) and msg.reply_to_message_id_ then
            function addadmin_reply(extra, result, success)
              local hash = 'botadmins:Araz'
              if redis:sismember(hash, result.sender_user_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️User : `'..result.sender_user_id_..'` *is Already in Admin list !*'
                else
                  text = '☘️کاربر : `'..result.sender_user_id_..'` *از قبل ادمين ربات هست !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                redis:sadd(hash, result.sender_user_id_)
                if redis:hget(msg.chat_id_ , "lang:Araz") == "en" then
                  text = '☘️User : `'..result.sender_user_id_..'` *Has been added as admin !*'
                else
                  text = '☘️کاربر : `'..result.sender_user_id_..'` *به ادمين هاي ربات اضافه شد !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            getMessage(msg.chat_id_, msg.reply_to_message_id_,addadmin_reply)
          end
          if msg.content_.text_:match("^[!]addadmin @(.*)$") and is_sudo(msg) then
            local match= {string.match(msg.content_.text_, "^[!](addadmin) @(.*)$")}
            function addadmin_by_username(extra, result, success)
              if result.id_ then
                redis:sadd('botadmins:Araz', result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User : <code>'..match[2]..'</code> <b>Has been Added to Admins !</b>'
                else
                  texts = '☘️کاربر : <code>'..match[2]..'</code> <b>به ادمين هاي ربات اضافه شد !</b>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>Not Found!</code>\n<b>User not found!</b>'
                else
                  texts = '☘️<code>پیدا نشد!</code>\n<b>کاربر يافت نشد !</b>'
                end

              end
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(match[2],addadmin_by_username)
          end
          if msg.content_.text_:match("^[!]addadmin (%d+)$") and is_sudo(msg) then
            local match = {string.match(msg.content_.text_, "^[!](addadmin) (%d+)$")}
            redis:sadd('botadmins:Araz', match[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              texts = '☘️User : <code>'..match[2]..'</code> <b>Has Added to Admins !</b>'
            else
              texts = '☘️کاربر : <code>'..match[2]..'</code> <b>به ادمين هاي ربات اضافه شد !</b>'
            end
          end
          if msg.content_.text_:match("^!remadmin$") and is_sudo(msg) and msg.reply_to_message_id_ then
            function remadmin_reply(extra, result, success)
              local hash = 'botadmins:Araz'
              if not redis:sismember(hash, result.sender_user_id_) then
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️User : `'..result.sender_user_id_..'` *Is not Admin !*', 1, 'md')
              else
                redis:srem(hash, result.sender_user_id_)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️User : `'..result.sender_user_id_..'` *Has Removed from Admins !*', 1, 'md')
              end
            end
            getMessage(msg.chat_id_, msg.reply_to_message_id_,remadmin_reply)
          end
          -----------------------------------------------------------------------------------------------
          if msg.content_.text_:match("^[!]remadmin @(.*)$") and is_sudo(msg) then
            local hash = 'botadmins:Araz'
            local ap = {string.match(msg.content_.text_, "^[!](remadmin) @(.*)$")}
            function remadmin_by_username(extra, result, success)
              if result.id_ then
                redis:srem(hash, result.id_)
                texts = '☘️User : <code>'..result.id_..'</code> <b>Has been Removed From Admins list !</b>'
              else
                texts = '☘️<code>Not Found!</code>\n<b>User not found!</b>'
              end
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap[2],remadmin_by_username)
          end
          -----------------------------------------------------------------------------------------------
          if msg.content_.text_:match("^[!]remadmin (%d+)$") and is_sudo(msg) then
            local hash = 'botadmins:Araz'
            local ap = {string.match(msg.content_.text_, "^[!](remadmin) (%d+)$")}
            redis:srem(hash, ap[2])
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️User : <code>'..ap[2]..'</code> <b>Has been Removed From Admins list !</b>', 1, 'html')
          end
          ----------------------------------------------------------------------------------------------__
          if msg.content_.text_:match('^[!]([Aa]dminlist)') and is_admin(msg) then
            if redis:scard('botadmins:Araz') == 0 then
              tdcli.sendText(chat_id, 0, 0, 1, nil, '☘️`Sorry Sir !`\n*There isnt any Admins Set for Bot !*', 1, 'md')
            else
              local text = "<b>Araz Bots Admins :</b> \n"
              for k,v in pairs(redis:smembers('botadmins:Araz')) do
                text = text.."<b>"..k.."</b> <b>></b> "..get_info(v).."\n"
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, 'html')
            end
          end
          -----------------------------------------------------------------------
--PromoteDemoteReply
          if msg.content_.text_:match('^ارتقا') and is_owner(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            tdcli.getMessage(chat_id,msg.reply_to_message_id_,setmod_reply,nil)
          end
		            if msg.content_.text_:match('^[!][Pp]romote') and is_owner(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            tdcli.getMessage(chat_id,msg.reply_to_message_id_,setmod_reply,nil)
          end
		  if msg.content_.text_:match('^[!][Dd]emote') and is_owner(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            tdcli.getMessage(chat_id,msg.reply_to_message_id_,remmod_reply,nil)
          end
		  if msg.content_.text_:match('^عزل') and is_owner(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            tdcli.getMessage(chat_id,msg.reply_to_message_id_,remmod_reply,nil)
          end
--Promote@ID
          if msg.content_.text_:match("^[!]promote @(.*)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local ap = {string.match(msg.content_.text_, "^[!](promote) @(.*)$")}
            function promote_by_username(extra, result, success)
              if result.id_ then
                redis:sadd('promotes:Araz'..msg.chat_id_, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User : <code>'..result.id_..'</code> <b>Has Been Promoted !</b>'
                else
                  texts = '☘️کاربر : <code>'..result.id_..'</code> <b>ارتقا يافت !</b>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  texts = '☘️<code>پیدا نشد!</code>\n<b>کاربر يافت نشد !</b>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap[2],promote_by_username)
          end
--Promote@Fa
		            if msg.content_.text_:match("^ارتقا @(.*)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local ap = {string.match(msg.content_.text_, "^(ارتقا) @(.*)$")}
            function promote_by_username(extra, result, success)
              if result.id_ then
                redis:sadd('promotes:Araz'..msg.chat_id_, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User : <code>'..result.id_..'</code> <b>Has Been Promoted !</b>'
                else
                  texts = '☘️کاربر : <code>'..result.id_..'</code> <b>ارتقا يافت !</b>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  texts = '☘️<code>پیدا نشد!</code>\n<b>کاربر يافت نشد !</b>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap[2],promote_by_username)
          end
--PromoteID
          if msg.content_.text_:match("^[!]promote (%d+)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local hash = 'promotes:Araz'..msg.chat_id_
            local ap = {string.match(msg.content_.text_, "^[!](promote) (%d+)$")}
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️User : <code>'..ap[2]..'</code> <b>Has been Promoted !</b>'
            else
              text = '☘️کاربر : <code>'..ap[2]..'</code> <b>ارتقا يافت !</b>'
            end
            redis:sadd(hash, ap[2])
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
          end
--Demote@ID
          if msg.content_.text_:match("^[!]demote @(.*)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local hash = 'promotes:Araz'..msg.chat_id_
            local ap = {string.match(msg.content_.text_, "^[!](demote) @(.*)$")}
            function demote_by_username(extra, result, success)
              if result.id_ then
                redis:srem(hash, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User :<code>'..result.id_..'</code> <b>Has been Demoted !</b>'
                else
                  texts = '☘️کاربر :<code>'..result.id_..'</code> <b>عزل مقام شد !</b>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  texts = '☘️<code>پیدا نشد!</code>\n<b>کاربر يافت نشد !</b>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap[2],demote_by_username)
          end
--PromoteFa
if msg.content_.text_:match("^ارتقا (%d+)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local hash = 'promotes:Araz'..msg.chat_id_
            local ap = {string.match(msg.content_.text_, "^(ارتقا) (%d+)$")}
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️User : <code>'..ap[2]..'</code> <b>Has been Promoted !</b>'
            else
              text = '☘️کاربر : <code>'..ap[2]..'</code> <b>ارتقا يافت !</b>'
            end
            redis:sadd(hash, ap[2])
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
          end
--Demote@Fa
          if msg.content_.text_:match("^عزل @(.*)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local hash = 'promotes:Araz'..msg.chat_id_
            local ap = {string.match(msg.content_.text_, "^(عزل) @(.*)$")}
            function demote_by_username(extra, result, success)
              if result.id_ then
                redis:srem(hash, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User :<code>'..result.id_..'</code> <b>Has been Demoted !</b>'
                else
                  texts = '☘️کاربر :<code>'..result.id_..'</code> <b>عزل مقام شد !</b>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  texts = '☘️<code>پیدا نشد!</code>\n<b>کاربر يافت نشد !</b>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap[2],demote_by_username)
          end
--DemoteId
          if msg.content_.text_:match("^[!]demote (%d+)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local hash = 'promotes:Araz'..msg.chat_id_
            local ap = {string.match(msg.content_.text_, "^[!](demote) (%d+)$")}
            redis:srem(hash, ap[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️User : <code>'..ap[2]..'</code> <b>Has been Demoted !</b>'
            else
              text = '☘️کاربر : <code>'..ap[2]..'</code> <b>عزل شد ! </b>'
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
          end
--DemoteFa
          if msg.content_.text_:match("^عزل (%d+)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local hash = 'promotes:Araz'..msg.chat_id_
            local ap = {string.match(msg.content_.text_, "^(عزل) (%d+)$")}
            redis:srem(hash, ap[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️User : <code>'..ap[2]..'</code> <b>Has been Demoted !</b>'
            else
              text = '☘️کاربر : <code>'..ap[2]..'</code> <b>عزل شد ! </b>'
            end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
          end
--ModList
          if msg.content_.text_:match('^(لیست مدیران)') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match('^([!][Mm]odlist)') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            if redis:scard('promotes:Araz'..chat_id) == 0 then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*There is no Moderators !*'
              else
                text = '☘️*مديري تعيين نشده است !*'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            else
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️<b>Group Moderators List :</b> \n"
              else
                text = "☘️<i>ليست مديران گروه :</i> \n"
              end
              for k,v in pairs(redis:smembers('promotes:Araz'..chat_id)) do
                text = text.."<code>"..k.."</code> - "..get_info(v).."\n"
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
            end
          end

--SetOwnerDelOwnerReply
		  if msg.content_.text_:match('^[!][Ss]etowner') and is_admin(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            tdcli.getMessage(chat_id,msg.reply_to_message_id_,setowner_reply,nil)
          end
		  if msg.content_.text_:match('^[!][Dd]elowner') and is_admin(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            tdcli.getMessage(chat_id,msg.reply_to_message_id_,deowner_reply,nil)
          end
--SetOwner
          if msg.content_.text_:match('^(مالک)$') and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match('^([!][Oo]wner)$') and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local hash = 'owners:Araz'..chat_id
            local owner = redis:get(hash)
            if owner == nil then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*There is not Owner in this group!*'
              else
                text = '☘️*براي اين گروه مديري تعيين نشده است!*'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            end
            local owner_list = redis:get('owners:Araz'..chat_id)
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text85 = '☘️<b>Group Owner :</b>\n\n '..get_info(owner_list)
            else
              text85 = '☘️<i>مدير گروه :</i>\n\n '..get_info(owner_list)
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text85, 1, 'html')
          end
--SetOwner@ID
          if msg.content_.text_:match("^[!]([Ss]etowner) @(.*)$") and is_admin(msg)and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local matches = {string.match(msg.content_.text_, "^[!]([Ss]etowner) @(.*)$")}
            function setowner_username(extra, result, success)
              if result.id_ then
                redis:set('owners:Araz'..msg.chat_id_, result.id_)
                redis:sadd('owners:Araz'..result.id_,msg.chat_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User : <code>'..result.id_..'</code> <b>Has Been Promoted as Owner !</b>'
                else
                  texts = '☘️کاربر : <code>'..result.id_..'</code> <i>به عنوان مدير گروه ارتقا يافت !</i>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  texts = '☘️<code>پیدا نشد!</code>\n<b>يافت نشد !</b>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(matches[2], setowner_username)
          end
--SetOwner@Fa
 if msg.content_.text_:match("^(تنظیم مالک) @(.*)$") and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local matches = {string.match(msg.content_.text_, "^(تنظیم مالک) @(.*)$")}
            function setowner_username(extra, result, success)
              if result.id_ then
                redis:set('owners:Araz'..msg.chat_id_, result.id_)
                redis:sadd('owners:Araz'..result.id_,msg.chat_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User : <code>'..result.id_..'</code> <b>Has Been Promoted as Owner !</b>'
                else
                  texts = '☘️کاربر : <code>'..result.id_..'</code> <i>به عنوان مدير گروه ارتقا يافت !</i>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  texts = '☘️<code>پیدا نشد!</code>\n<b>يافت نشد !</b>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(matches[2], setowner_username)
          end
--DelOwner
          if msg.content_.text_:match('^[!][Dd]elowner (.*)') and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            redis:del('owners:Araz'..chat_id)
            redis:srem('owners:Araz'..msg.sender_user_id_,msg.chat_id_)
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️User : `'..msg.content_.text_:match('^[!][Dd]elowner (.*)')..'` *Has De-Ownered !*'
            else
              text = '☘️کاربر : `'..msg.content_.text_:match('^[!][Dd]elowner (.*)')..'` *از مدیریت عزل شد !*'
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
          end
--DelOwnerFa
          if msg.content_.text_:match('^حذف مالک (.*)') and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            redis:del('owners:Araz'..chat_id)
            redis:srem('owners:Araz'..msg.sender_user_id_,msg.chat_id_)
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️User : `'..msg.content_.text_:match('^حذف مالک (.*)')..'` *Has been De-Ownered !*'
            else
              text = '☘️کاربر : `'..msg.content_.text_:match('^حذف مالک (.*)')..'` *از مديريت عزل شد !*'
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
          end
--DelOwner
          if msg.content_.text_:match("^[!][Dd]elowner @(.*)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local hash = 'promotes:Araz'..msg.chat_id_
            local ap2 = {string.match(msg.content_.text_, "^[!]([Dd]elowner) @(.*)$")}
            function deowner_username(extra, result, success)
              if result.id_ then
                redis:del(hash, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User :<code>'..result.id_..'</code> <b>Has been Demoted From Owner !</b>'
                else
                  texts = '☘️کاربر :<code>'..result.id_..'</code> <i>از مديريت عزل شد !</i>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<b>User not found !</b>'
                else
                  texts = '☘️<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap2[2],deowner_username)
          end
--DelOwner@Fa
          if msg.content_.text_:match("^حذف مالک @(.*)$") and is_owner(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local hash = 'promotes:Araz'..msg.chat_id_
            local ap2 = {string.match(msg.content_.text_, "^(حذف مالک) @(.*)$")}
            function deowner_username(extra, result, success)
              if result.id_ then
                redis:del(hash, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️User :<code>'..result.id_..'</code> <b>Has been Demoted From Owner !</b>'
                else
                  texts = '☘️کاربر :<code>'..result.id_..'</code> <i>از مديريت عزل شد !</i>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<b>User not found !</b>'
                else
                  texts = '☘️<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap2[2],deowner_username)
          end

--clean msg
          if msg.content_.text_:match('^حذف پیام') and is_mod(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match('^[!]rmsg') and is_mod(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
		  function rmsg_reply(extra, result, success)
               local hash = 'promotes:Araz'..msg.chat_id_
              if redis:sismember(hash, result.sender_user_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = "🍀You Can't Delete messages of promote users!*"
                else
                  text = '🍀شما نمیتوانید پیام افراد ارتقا یافته را حذف کنید!*'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
				else
                tdcli.deleteMessagesFromUser(result.chat_id_, result.sender_user_id_)
            end
          end
		              tdcli.getMessage(msg.chat_id_, msg.reply_to_message_id_,rmsg_reply)
          end
--autoleave
          if msg.content_.text_:match('^!autoleave on$') then
            tdcli.sendText(chat_id, 0, 0, 1, nil, '☘️`Done!`\n*Auto Leave is Activated !*', 1, 'md')
            redis:set('autoleave', "on")
          end
          if msg.content_.text_:match('^!autoleave off$') then
            tdcli.sendText(chat_id, 0, 0, 1, nil, '☘️`Done!`\n*Auto Leave is Deactivated !*', 1, 'md')
            redis:set('autoleave', "off")
          end
--KickReply
          if input:match('^([!]kick)$') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            tdcli_function({ID = "GetMessage",chat_id_ = msg.chat_id_,message_id_ = msg.reply_to_message_id_}, kick_reply, 'md')
            return
          end
		            if input:match('^(اخراج)$') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            tdcli_function({ID = "GetMessage",chat_id_ = msg.chat_id_,message_id_ = msg.reply_to_message_id_}, kick_reply, 'md')
            return
          end
--KickID
          if input:match('^!kick (.*)') and not input:find('@') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            if redis:sismember('promotes:Araz'..msg.chat_id_ ,input:match('^!kick (.*)')) then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*You Can Not Kick Moderators!*'
              else
                text = '🍀_شما نمیتوانید مدیر و ناظم هارا حذف کنید !_'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            else
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '🍀User : '..get_info(input:match('^!kick (.*)'))..' <b>Has Kicked!</b>'
              else
                text = '🍀کاربر : \n'..get_info(input:match('^!kick (.*)'))..'\n حذف شد !'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
              tdcli.changeChatMemberStatus(chat_id, input:match('^!kick (.*)'), 'Kicked')
            end
          end
          if input:match('^!kick (.*)') and input:find('@') and is_mod(msg)and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            if redis:sismember('promotes:Araz'..msg.chat_id_ ,input:match('^!kick (.*)') ) then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*You Can Not Kick Moderators!*'
              else
                text = '🍀_شما نمیتوانید مدیر و ناظم هارا حذف کنید !_'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            else
              function Inline_Callback_(arg, data)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : '..input:match('^!kick (.*)')..' <b>Has Kicked!</b>'
                else
                  text = '🍀کاربر : '..input:match('^!kick (.*)')..' حذف شد !'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
                tdcli.changeChatMemberStatus(chat_id, data.id_, 'Kicked')
              end
              tdcli_function ({ID = "SearchPublicChat",username_ =input:match('^kick (.*)')}, Inline_Callback_, nil)
            end
          end
--KickIDFa
          if input:match('^اخراج (.*)') and not input:find('@') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            if redis:sismember('promotes:Araz'..msg.chat_id_ ,input:match('^اخراج (.*)')) then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*You Can,t Kick Moderators !*'
              else
                text = '🍀_شما نميتوانيد مدير و ناظم هارا حذف کنيد !_'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            else
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '🍀User : '..get_info(input:match('^اخراج (.*)'))..' <b>Has been Kicked !</b>'
              else
                text = '🍀کاربر : \n'..get_info(input:match('^اخراج (.*)'))..'\n حذف شد !'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
              tdcli.changeChatMemberStatus(chat_id, input:match('^اخراج (.*)'), 'Kicked')
            end
          end
          if input:match('^اخراج (.*)') and input:find('@') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            if redis:sismember('promotes:Araz'..msg.chat_id_ ,input:match('^اخراج (.*)') ) then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*You Can,t Kick Moderators !*'
              else
                text = '🍀_شما نميتوانيد مدير و ناظم هارا حذف کنيد !_'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            else
              function Inline_Callback_(arg, data)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : '..input:match('^اخراج (.*)')..' <b>Has been Kicked !</b>'
                else
                  text = '🍀کاربر : '..input:match('^اخراج (.*)')..' حذف شد !'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
                tdcli.changeChatMemberStatus(chat_id, data.id_, 'Kicked')
              end
              tdcli_function ({ID = "SearchPublicChat",username_ =input:match('^kick (.*)')}, Inline_Callback_, nil)
            end
          end
--BanReply
          if msg.content_.text_:match("^!ban$") and is_mod(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            function ban_by_reply(extra, result, success)
              local hash = 'bot:banned:Araz'..msg.chat_id_
              if redis:sismember(hash, result.sender_user_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : `'..result.sender_user_id_..'` *is Already Banned !*'
                else
                  text = '🍀کاربر : `'..result.sender_user_id_..'` _از قبل بن بود !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                chat_kick(result.chat_id_, result.sender_user_id_)
              else
                redis:sadd(hash, result.sender_user_id_)

                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : `'..result.sender_user_id_..'` *Has been Banned !*'
                else
                  text = '🍀کاربر : `'..result.sender_user_id_..'` _از گروه بن شد !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                chat_kick(result.chat_id_, result.sender_user_id_)
              end
              if result.sender_user_id_ == redis:sismember('promotes:Araz'..msg.chat_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*You Can,t Ban Moderators !*'
                else
                  text = '🍀_شما نميتوانيد مدير و ناظم هارا بن کنيد !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
              end
            end
			
            tdcli.getMessage(msg.chat_id_, msg.reply_to_message_id_,ban_by_reply)
          end
--BanFaReply
		  if msg.content_.text_:match("^بن$") and is_mod(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            function ban_by_reply(extra, result, success)
              local hash = 'bot:banned:Araz'..msg.chat_id_
              if redis:sismember(hash, result.sender_user_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : `'..result.sender_user_id_..'` *is Already Banned !*'
                else
                  text = '🍀کاربر : `'..result.sender_user_id_..'` _از قبل بن بود !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                chat_kick(result.chat_id_, result.sender_user_id_)
              else
                redis:sadd(hash, result.sender_user_id_)

                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : `'..result.sender_user_id_..'` *Has been Banned !*'
                else
                  text = '🍀کاربر : `'..result.sender_user_id_..'` _از گروه بن شد !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                chat_kick(result.chat_id_, result.sender_user_id_)
              end
              if result.sender_user_id_ == redis:sismember('promotes:Araz'..msg.chat_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*You Can,t Ban Moderators !*'
                else
                  text = '🍀_شما نميتوانيد مدير و ناظم هارا بن کنيد !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
              end
            end
			
            tdcli.getMessage(msg.chat_id_, msg.reply_to_message_id_,ban_by_reply)
          end
--BanAll
          if msg.content_.text_:match("^!banall$") and is_sudo(msg) and msg.reply_to_message_id_ then
            function banall_by_reply(extra, result, success)
		if redis:sismember('botadmins:Araz', result.id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*You Can,t Banall [ Admins / Sudo ] !*'
                else
                  text = '🍀_شما نميتوانيد سازنده ربات و ادمين ها را بن کنيد !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
              end
              local hash = 'bot:gbanned:Araz'
              if redis:sismember(hash, result.id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : `'..result.id_..'` *is Already Globally Banned !*'
                else
                  text = '🍀کاربر : `'..result.id_..'` _از قبل بن همگاني بود !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                chat_kick(result.chat_id_, result.id_)
              else
                redis:sadd(hash, result.id_)

                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : `'..result.id_..'` *Has been Globally Banned !*'
                else
                  text = '🍀کاربر : `'..result.id_..'` _از گروه بن همگاني شد !_'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                chat_kick(result.chat_id_, result.id_)
              end
            end
            tdcli.getMessage(msg.chat_id_, msg.reply_to_message_id_,banall_by_reply)
          end
--Ban@ID
          if msg.content_.text_:match("^[!]ban @(.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local ap = {string.match(msg.content_.text_, "^[!](ban) @(.*)$")}
            function ban_by_username(extra, result, success)
              if result.id_ then
                if redis:get('promotes:Araz'..result.id_) then
                  if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                    text = '☘️*You Can,t Ban Moderators !*'
                  else
                    text = '🍀_شما نميتوانيد مدير و ناظم هارا بن کنيد !_'
                  end
                  tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                end
                if not redis:get('promotes:Araz'..result.id_) then
                  redis:sadd('bot:banned:Araz'..msg.chat_id_, result.id_)
                  if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                    texts = '🍀User : '..result.id_..' <b>Has been Banned !</b>'
                  else
                    texts = '🍀کاربر : '..result.id_..' <i>بن شد !</i>'
                  end
                  chat_kick(msg.chat_id_, result.id_)
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>User not found!</code>'
                else
                  texts = '☘️<code>کاربر يافت نشد !</code>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap[2],ban_by_username)
          end
--Ban@Fa
         if msg.content_.text_:match("^بن @(.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local ap = {string.match(msg.content_.text_, "^(بن) @(.*)$")}
            function ban_by_username(extra, result, success)
              if result.id_ then
                if redis:get('promotes:Araz'..result.id_) then
                  if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                    text = '☘️*You Can,t Ban Moderators !*'
                  else
                    text = '🍀_شما نميتوانيد مدير و ناظم هارا بن کنيد !_'
                  end
                  tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                end
                if not redis:get('promotes:Araz'..result.id_) then
                  redis:sadd('bot:banned:Araz'..msg.chat_id_, result.id_)
                  if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                    texts = '🍀User : '..result.id_..' <b>Has been Banned !</b>'
                  else
                    texts = '🍀کاربر : '..result.id_..' <i>بن شد !</i>'
                  end
                  chat_kick(msg.chat_id_, result.id_)
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>User not found!</code>'
                else
                  texts = '☘️<code>کاربر يافت نشد !</code>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap[2],ban_by_username)
          end
--BanAllID
          if msg.content_.text_:match("^[!]banall @(.*)$") and is_sudo(msg) then
            local ap = {string.match(msg.content_.text_, "^[!](banall) @(.*)$")}
            function banall_by_username(extra, result, success)
              if result.id_ then
                if redis:sismember('botadmins:Araz', result.id_) then
                  if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                    text = '☘️*You Can,t Banall [ Admins / Sudo ] !*'
                  else
                    text = '🍀_شما نميتوانيد سازنده ربات و ادمين ها را بن کنيد !_'
                  end
                  tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
                end
                if not redis:sismember('bot:gbanned:Araz', result.id_) then
                  redis:sadd('bot:gbanned:Araz', result.id_)
                  if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                    texts = '☘️<b>User :</b> '..get_info(result.id_)..' <b>Has been Globally Banned !</b>'
                  else
                    texts = '🍀کاربر : \n'..get_info(result.id_)..' \n<i>بن همگاني شد !</i>'
                  end
                  chat_kick(msg.chat_id_, result.id_)
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  texts = '☘️<code>User not found!</code>'
                else
                  texts = '☘️<code>کاربر يافت نشد !</code>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, texts, 1, 'html')
            end
            resolve_username(ap[2],banall_by_username)
          end
--BanID
          if msg.content_.text_:match("^[!]ban (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local ap = {string.match(msg.content_.text_, "^[!](ban) (%d+)$")}
            if redis:get('promotes:Araz'..result.chat_id_, result.id_) then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*You Can,t [Kick/Ban] Moderators !*'
              else
                text = '🍀_شما نميتوانيد مدير و ناظم ها را بن کنيد !_'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            else
              redis:sadd('bot:banned:Araz'..msg.chat_id_, ap[2])
              chat_kick(msg.chat_id_, ap[2])
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '🍀User : '..ap[2]..' <b> Has been Banned !</b>'
              else
                text = '🍀کاربر : '..ap[2]..' <i> بن شد !</i>'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
            end
          end
--BanFa
         if msg.content_.text_:match("^بن (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local ap = {string.match(msg.content_.text_, "^(بن) (%d+)$")}
            if redis:get('promotes:Araz'..result.chat_id_, result.id_) then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*You Can,t [Kick/Ban] Moderators !*'
              else
                text = '🍀_شما نميتوانيد مدير و ناظم ها را بن کنيد !_'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            else
              redis:sadd('bot:banned:Araz'..msg.chat_id_, ap[2])
              chat_kick(msg.chat_id_, ap[2])
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '🍀User : '..ap[2]..' <b> Has been Banned !</b>'
              else
                text = '🍀کاربر : '..ap[2]..' <i> بن شد !</i>'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
            end
          end
--BanAll
          if msg.content_.text_:match("^[!]banall (%d+)$") and is_sudo(msg) then
            local ap = {string.match(msg.content_.text_, "^[!](banall) (%d+)$")}
            if not redis:sismember("botadmins:", ap[2]) or sudo_users == result.sender_user_id_ then
		redis:sadd('bot:gbanned:Araz', ap[2])
              chat_kick(msg.chat_id_, ap[2])
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️<b>User :</b> <code>'..ap[2]..'</code> <b> Has been Globally Banned !</b>'
              else
                text = '🍀کاربر : <code>'..ap[2]..'</code> <i> بن همگاني شد !</i>'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
            else
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*You Can,t Banall [Admins / Sudo ] !*'
              else
                text = '🍀_شما نميتوانيد سازنده ربات و ادمين ها را بن کنيد !_'
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            end
          end
--UnbanReply
          if msg.content_.text_:match("^[!][Uu]nban$") and is_mod(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            function unban_by_reply(extra, result, success)
              local hash = 'bot:banned:Araz'..msg.chat_id_
              if not redis:sismember(hash, result.sender_user_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : '..result.sender_user_id_..' <b>is Not Banned !</b>'
                else
                  text = '🍀کاربر : '..result.sender_user_id_..' <i>بن نبود !</i>'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
              else
                redis:srem(hash, result.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : '..result.sender_user_id_..' <b>Has been Unbanned !</b>'
                else
                  text = '🍀کاربر : '..result.sender_user_id_..' <i>آنبن شد !</i>'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
              end
            end
            getMessage(msg.chat_id_, msg.reply_to_message_id_,unban_by_reply)
          end
--UnbanFaReply
         if msg.content_.text_:match("^آنبن$") and is_mod(msg) and msg.reply_to_message_id_ and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            function unban_by_reply(extra, result, success)
              local hash = 'bot:banned:Araz'..msg.chat_id_
              if not redis:sismember(hash, result.sender_user_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : '..result.sender_user_id_..' <b>is Not Banned !</b>'
                else
                  text = '🍀کاربر : '..result.sender_user_id_..' <i>بن نبود !</i>'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
              else
                redis:srem(hash, result.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '🍀User : '..result.sender_user_id_..' <b>Has been Unbanned !</b>'
                else
                  text = '🍀کاربر : '..result.sender_user_id_..' <i>آنبن شد !</i>'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
              end
            end
            getMessage(msg.chat_id_, msg.reply_to_message_id_,unban_by_reply)
          end
--UnbanAll
          if msg.content_.text_:match("^[!][Uu]nbanall$") and is_sudo(msg) and msg.reply_to_message_id_ then
            function unbanall_by_reply(extra, result, success)
              local hash = 'bot:gbanned:Araz'
              if not redis:sismember(hash, result.sender_user_id_) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>User :</b> '..get_info(result.sender_user_id_)..' <b>is Not Globally Banned !</b>'
                else
                  text = '🍀کاربر : \n'..get_info(result.sender_user_id_)..' \n<i>بن نبود !</i>'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
              else
                redis:srem(hash, result.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>User :</b> '..get_info(result.sender_user_id_)..' <b>Has been Globally Unbanned !</b>'
                else
                  text = '🍀کاربر : \n'..get_info(result.sender_user_id_)..' \n<i>آنبن شد !</i>'
                end
                tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
              end
            end
            getMessage(msg.chat_id_, msg.reply_to_message_id_,unbanall_by_reply)
          end
--UnBan@ID
          if msg.content_.text_:match("^[!][Uu]nban @(.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local ap = {string.match(msg.content_.text_, "^[!](unban) @(.*)$")}
            function unban_by_username(extra, result, success)
              if result.id_ then
                redis:srem('bot:banned:Araz'..msg.chat_id_, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>User :</b> '..result.id_..' <b>Has been Unbanned !</b>'
                else
                  text = '☘️<i>کاربر :</i> '..result.id_..' <i> آنبن شد !</i>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<code>Not Found!</code>\n<b>User not found!</b>'
                else
                  text = '☘️<code>پیدا نشد !</code>\n<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
            end
            resolve_username(ap[2],unban_by_username)
          end
--UnBan@IDFa
          if msg.content_.text_:match("^آنبن @(.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local ap = {string.match(msg.content_.text_, "^(آنبن) @(.*)$")}
            function unban_by_username(extra, result, success)
              if result.id_ then
                redis:srem('bot:banned:Araz'..msg.chat_id_, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>User :</b> '..result.id_..' <b>Has been Unbanned !</b>'
                else
                  text = '☘️<i>کاربر :</i> '..result.id_..' <i> آنبن شد !</i>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<code>Not Found!</code>\n<b>User not found!</b>'
                else
                  text = '☘️<code>پیدا نشد !</code>\n<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
            end
            resolve_username(ap[2],unban_by_username)
          end
--UnbanAll @ID
          if msg.content_.text_:match("^[!][Uu]nbanall @(.*)$") and is_sudo(msg) then
            local ap = {string.match(msg.content_.text_, "^[!](unbanall) @(.*)$")}
            function unbanall_by_username(extra, result, success)
              if result.id_ then
                redis:srem('bot:gbanned:Araz', result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>User :</b> '..get_info(result.id_)..' <b>Has been Globally Unbanned !</b>'
                else
                  text = '☘️<i>کاربر :</i> \n'..get_info(result.id_)..' \n<i> آنبن همگاني شد !</i>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<code>Not Found!</code>\n<b>User not found!</b>'
                else
                  text = '☘️<code>پیدا نشد !</code>\n<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
            end
            resolve_username(ap[2],unbanall_by_username)
          end
--Unban ID
          if msg.content_.text_:match("^[!][Uu]nban (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local ap = {string.match(msg.content_.text_, "^[!]([Uu]nban) (%d+)$")}
            redis:srem('bot:banned:Araz'..msg.chat_id_, ap[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '🍀User : '..ap[2]..' <b>Has been Unbanned !</b>'
            else
              text = '🍀کاربر : '..ap[2]..' <i>آنبن شد !</i>'
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--Unban ID
          if msg.content_.text_:match("^آنبن (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local ap = {string.match(msg.content_.text_, "^(آنبن) (%d+)$")}
            redis:srem('bot:banned:Araz'..msg.chat_id_, ap[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '🍀User : '..ap[2]..' <b>Has been Unbanned !</b>'
            else
              text = '🍀کاربر : '..ap[2]..' <i>آنبن شد !</i>'
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--UnbanAll
          if msg.content_.text_:match("^[!][Uu]nbanall (%d+)$") and is_sudo(msg) then
            local ap = {string.match(msg.content_.text_, "^[!]([Uu]nbanall) (%d+)$")}
	     if not redis:hget('bot:gbanned', ap[2]) then
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️<b>User :</b> '..get_info(ap[2])..' <b>Is not Globally banned !</b>'
            else
              text = '🍀کاربر : \n'..get_info(ap[2])..' \n<i>بن همگاني نبود !</i>'
            end
	    else
            redis:srem('bot:gbanned:Araz', ap[2])
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '☘️<b>User :</b> '..get_info(ap[2])..' <b>Has been Globally Unbanned !</b>'
            else
              text = '🍀کاربر : \n'..get_info(ap[2])..' \n<i>آنبن همگاني شد !</i>'
            end
	    end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--BanList
          if msg.content_.text_:match("^[!]banlist$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^لیست بن شدگان$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local hash =  'bot:banned:Araz'..msg.chat_id_
            local list = redis:smembers(hash)
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = "☘️<b>Ban List:</b>\n\n"
            else
              text = "☘️<i>ليست بن شده ها :</i>\n\n"
            end
            for k,v in pairs(list) do
              local user_info = redis:hgetall('user:'..v)
              if user_info and user_info.username then
                local username = user_info.username
                text = text..k.." - @"..username.." ["..v.."]\n"
              else
                text = text..k.." - "..v.."\n"
              end
            end
            if #list == 0 then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️<code>Not Found!</code>\n<b>Ban List is empty !</b>"
              else
                text = "☘️<code>پیدا نشد!</code>\n<i>ليست بن خاليست !</i>"
              end
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end

--Gbanlist
          if msg.content_.text_:match("^[!]gbanlist$") and is_admin(msg) then
            local hash =  'bot:gbanned:Araz'
            local list = redis:smembers(hash)
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = "☘️<b>Global Ban List:</b>\n\n"
            else
              text = "☘️<i>ليست بن شده هاي همگاني :</i>\n\n"
            end
            for k,v in pairs(list) do
              local user_info = redis:hgetall('user:'..v)
              if user_info and user_info.username then
                local username = user_info.username
                text = text..k.." - @"..username.." ["..v.."]\n"
              else
                text = text..k.." - "..v.."\n"
              end
            end
            if #list == 0 then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️<code>Not Found!</code>\n<b>Ban List is empty !</b>"
              else
                text = "☘️<code>پیدا نشد!</code>\n<i>ليست بن هاي همگاني خاليست !</i>"
              end
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--MuteUserReply

		  if msg.content_.text_:match('^[!]muteuser') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            redis:set('mute_user:Araz'..chat_id,'yes')
            tdcli_function({ID = "GetMessage",chat_id_ = msg.chat_id_,message_id_ = msg.reply_to_message_id_}, setmute_reply, 'md')
          end
		  if msg.content_.text_:match('^ساکت کردن') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            redis:set('mute_user:Araz'..chat_id,'yes')
            tdcli_function({ID = "GetMessage",chat_id_ = msg.chat_id_,message_id_ = msg.reply_to_message_id_}, setmute_reply, 'md')
          end
		  if msg.content_.text_:match('^[!]unmuteuser') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            tdcli_function({ID = "GetMessage",chat_id_ = msg.chat_id_,message_id_ = msg.reply_to_message_id_}, demute_reply, 'md')
          end
		  if msg.content_.text_:match('^آزاد کردن') and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            tdcli_function({ID = "GetMessage",chat_id_ = msg.chat_id_,message_id_ = msg.reply_to_message_id_}, demute_reply, 'md')
          end
--MuteUserID
          mu = msg.content_.text_:match('^!muteuser (.*)')
          if mu and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            redis:sadd('muteusers:Araz'..chat_id,mu)
            redis:set('mute_user:Araz'..chat_id,'yes')
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '🍀User : <code>('..mu..')</code> <b>Has been Added to mutelist</b>'
            else
              text = '🍀کاربر : <code>('..mu..')</code> <i>ساکت شد !</i>\nوضعيت : <code>قادر به حرف زدن نميباشد !</code>'
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--MuteUserIDFa
          mu = msg.content_.text_:match('^ساکت کردن (.*)')
          if mu and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            redis:sadd('muteusers:Araz'..chat_id,mu)
            redis:set('mute_user:Araz'..chat_id,'yes')
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '🍀User : <code>('..mu..')</code> <b>Has been Added to mutelist</b>'
            else
              text = '🍀کاربر : <code>('..mu..')</code> <i>ساکت شد !</i>\nوضعيت : <code>قادر به حرف زدن نميباشد !</code>'
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--UnMuteUerID
          umu = msg.content_.text_:match('^!unmuteuser (.*)')
          if umu and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            redis:srem('muteusers:Araz'..chat_id,umu)
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '🍀User : <code>('..umu..')</code> <b>Has Been Removed From Mute list !</b>'
            else
              text = '🍀کاربر : <code>('..umu..')</code> <i>از ليست ساکت شده ها حذف شد !</i>'
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--UnMuteUerIDFa
          umu = msg.content_.text_:match('^آزاد کردن (.*)')
          if umu and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            redis:srem('muteusers:Araz'..chat_id,umu)
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = '🍀User : <code>('..umu..')</code> <b>Has Been Removed From Mute list !</b>'
            else
              text = '🍀کاربر : <code>('..umu..')</code> <i>از ليست ساکت شده ها حذف شد !</i>'
            end
            tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--MuteUser@ID
          if msg.content_.text_:match("^!muteuser @(.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local aps = {string.match(msg.content_.text_, "^!muteuser @(.*)$")}
            function mute_by_username(extra, result, success)
              if result.id_ then
                redis:sadd('muteusers:Araz'..msg.chat_id_, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  textss = '🍀User : <code>('..result.id_..')</code> <b>Has been Added to mutelist</b>'
                else
                  textss = '🍀کاربر : <code>('..result.id_..')</code> <i>ساکت شد !</i>\nوضعيت : <code>قادر به حرف زدن نميباشد !</code>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  textss = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  textss = '☘️<code>پیدا نشد!</code>\n<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, textss, 1, 'html')
            end
            resolve_username(aps[2],mute_by_username)
          end
--MuteUser@IDFA
          if msg.content_.text_:match("^ساکت کردن @(.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local aps = {string.match(msg.content_.text_, "^ساکت کردن @(.*)$")}
            function mute_by_username(extra, result, success)
              if result.id_ then
                redis:sadd('muteusers:Araz'..msg.chat_id_, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  textss = '🍀User : <code>('..result.id_..')</code> <b>Has been Added to mutelist</b>'
                else
                  textss = '🍀کاربر : <code>('..result.id_..')</code> <i>ساکت شد !</i>\nوضعيت : <code>قادر به حرف زدن نميباشد !</code>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  textss = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  textss = '☘️<code>پیدا نشد!</code>\n<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, textss, 1, 'html')
            end
            resolve_username(aps[2],mute_by_username)
          end
--UnMuteUser@ID
          if msg.content_.text_:match("^!unmuteuser @(.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            local aps = {string.match(msg.content_.text_, "^!unmuteuser @(.*)$")}
            function mute_by_username(extra, result, success)
              if result.id_ then
                redis:srem('muteusers:Araz'..msg.chat_id_, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  textss = '🍀User : <code>('..result.id_..')</code> <b>Has been removed from mutelist</b>'
                else
                  textss = '🍀کاربر : <code>('..result.id_..')</code> <i>آزاد شد !</i>\nوضعيت : <code>قادر به حرف زدن میباشد !</code>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  textss = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  textss = '☘️<code>پیدا نشد!</code>\n<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, textss, 1, 'html')
            end
            resolve_username(aps[2],mute_by_username)
          end
--UnMuteUser@IDFA
          if msg.content_.text_:match("^آزاد کردن @(.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
            local aps = {string.match(msg.content_.text_, "^آزاد کردن @(.*)$")}
            function mute_by_username(extra, result, success)
              if result.id_ then
                redis:srem('muteusers:Araz'..msg.chat_id_, result.id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  textss = '🍀User : <code>('..result.id_..')</code> <b>Has been Removed from mutelist</b>'
                else
                  textss = '🍀کاربر : <code>('..result.id_..')</code> <i>آزاد شد !</i>\nوضعيت : <code>قادر به حرف زدن میباشد !</code>'
                end
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  textss = '☘️<code>Not Found!</code>\n<b>User Not Found !</b>'
                else
                  textss = '☘️<code>پیدا نشد!</code>\n<i>کاربر يافت نشد !</i>'
                end
              end
              tdcli.sendText(chat_id, 0, 0, 1, nil, textss, 1, 'html')
            end
            resolve_username(aps[2],mute_by_username)
          end
--MuteList
          if input:match('^لیست ساکت شدگان') and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or input:match('^[!][Mm]utelist') and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
            if redis:scard('muteusers:Araz'..chat_id) == 0 then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*There is not Muted Users in This Group !*'
              else
                text = '🍀_هيچ شخص ساکت شده اي وجود ندارد !_'
              end
              return tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'md')
            end
            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              text = "☘️<b>Muted Users List :</b>\n"
            else
              text = "☘️<i>ليست اعضاي ساکت شده :</i>\n"
            end
            for k,v in pairs(redis:smembers('muteusers:Araz'..chat_id)) do
              text = text.."<code>"..k.."</code>> <b>"..v.."</b>\n"
            end
            return tdcli.sendText(chat_id, 0, 0, 1, nil, text, 1, 'html')
          end
--ProcessSetLink
          if msg.content_.text_:find('^https://(.*)') or msg.content_.text_:find('^http://(.*)') and not is_mod(msg) then
            if redis:get('mute_weblink:Araz'..msg.sender_user_id_) then
              tdcli.deleteMessages(msg.chat_id_, {[0] = msg.reply_to_message_id_})
            else return end
            end
--FilterWord
            if msg.content_.text_:match("^[!][Ff]ilter (.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️<b>Word :</b> <code>'..msg.content_.text_:match("^[!][Ff]ilter (.*)$")..'</code> <b>Added to Filtered Words!</b>'
              else
                text = '☘️<i>کلمه ی :</i> <code>'..msg.content_.text_:match("^[!][Ff]ilter (.*)$")..'</code> <i>به لیست کلمات فیلتر شده اضافه شد !</i>'
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, 'html')
              redis:sadd('filters:'..msg.chat_id_, msg.content_.text_:match("^[!][Ff]ilter (.*)$"))
            end
--FilterWordFa
            if msg.content_.text_:match("^فیلتر (.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️<b>Word :</b> <code>'..msg.content_.text_:match("^فیلتر (.*)$")..'</code> <b>Has been Added to Filtered Words !</b>'
              else
                text = '☘️<i>کلمه ي :</i> <code>'..msg.content_.text_:match("^فیلتر (.*)$")..'</code> <i>به ليست کلمات فيلتر شده اضافه شد !</i>'
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, 'html')
              redis:sadd('filters:'..msg.chat_id_, msg.content_.text_:match("^فیلتر (.*)$"))
            end
--UnFilter
            if msg.content_.text_:match("^[!][Uu]n[Ff]ilter (.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️<i>Word :</i> <code>'..msg.content_.text_:match("^[!][Uu]n[Ff]ilter (.*)$")..'</code> <i>Removed From Filtered Words!</i>'
              else
                text = '☘️<i>کلمه ی :</i> <code>'..msg.content_.text_:match("^[!][Uu]n[Ff]ilter (.*)$")..'</code> <i>از لیست کلمات فیلتر شده حذف شد !</i>'
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, 'html')
              redis:srem('filters:'..msg.chat_id_, msg.content_.text_:match("^[!][Uu]n[Ff]ilter (.*)$"))
            end
--UnFilterFa
            if msg.content_.text_:match("^حذف فیلتر (.*)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️<i>Word :</i> <code>'..msg.content_.text_:match("^حذف فیلتر (.*)$")..'</code> <i>Has been Removed From Filtered Words !</i>'
              else
                text = '☘️<i>کلمه ي :</i> <code>'..msg.content_.text_:match("^حذف فیلتر (.*)$")..'</code> <i>از ليست کلمات فيلتر شده حذف شد !</i>'
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, 'html')
              redis:srem('filters:'..msg.chat_id_, msg.content_.text_:match("^حذف فیلتر (.*)$"))
            end
--FilterList
            if msg.content_.text_:match("^لیست فیلتر$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[/!#]filterlist$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^filterlist$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              local flist = redis:smembers('filters:'..msg.chat_id_)
              if flist == 0 then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Filter List is Empty !*'
                else
                  text = '🍀_ليست کلمات فيلتر شده خالي ميباشد !_'
                end
                tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1 , "md")
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Filtered Words List :*\n\n'
                else
                  text = '🍀_ليست کلمات فيلتر شده :_\n\n'
                end
                for k,v in pairs(flist) do
                  text = text..">*"..k.."*- `"..v.."`\n"
                end
                tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1 , "md")
              end
            end
--START LOCKS
--lock bots
            groups = redis:sismember('groups:Araz',chat_id)
            if msg.content_.text_:match("^قفل ربات$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock bots$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_bots:Araz'..chat_id) then
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Bots Status Was :</b> <code>Locked</code> \n<b>Bots Protection Is Already Locked by :</b> '..get_info(redis:get('locker_bots'..chat_id))..'', 1, 'html')
              else
                redis:set('locker_bots'..chat_id, msg.sender_user_id_)
                redis:set('lock_bots:Araz'..chat_id, "True")
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Bots Status :</b> <code>Locked</code> \n<b>Bots Protection Has been Changed by :</b>\n'..get_info(msg.sender_user_id_)..'', 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن ربات")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock bots$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_bots:Araz'..chat_id) then
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>‌Bots Protection Was on :</b> <code>UnLock</code>\n<b>Status Not Changed !</b>', 1, 'html')
              else
                redis:set('unlocker_bots'..chat_id, msg.sender_user_id_)
                redis:del('lock_bots:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Bots Status :</b> <code>UnLock</code>\n<b>Bots Protections Has Been Disabled !</b>', 1, 'html')
              end
            end
--Status Bots
if msg.content_.text_:match("^ربات$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[/#!][Bb]ot$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Bb]ot$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_bots:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Bot Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('locker_bots'..chat_id))..'\n<b>For Unlock Please use /unlock bots</b>'
                else
                  text = '☘️<b>قفل ربات: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_bots'..chat_id))..'\nبرای باز کردن از "بازکردن ربات" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^ربات$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Bb]ot$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_bots:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Bot Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unlocker_bots'..chat_id))..'\n<b>For lock Please use !lock bots</b>'
                else
                  text = '☘️<b>قفل ربات:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_bots'..chat_id))..'\nبرای قفل از"قفل ربات"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
            --lock link
            groups = redis:sismember('groups:Araz',chat_id)
            if msg.content_.text_:match("^قفل لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock link$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_link:Araz'..chat_id) then
                 if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Link Status Was :</b> <code>Locked</code> \n<b>Cleaning Link Is Already Locked by :</b> '..get_info(redis:get('locker_links'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي لینک :</b> <code>قفل</code> \n<b>قفل لینک از قبل فعال شده بود توسط :</b>\n'..get_info(redis:get('locker_links'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_link:Araz'..chat_id, "True")
                redis:set('locker_links'..chat_id, msg.sender_user_id_)
                           if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Link Status :</b> <code>Locked</code> \n<b>Link Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت لینک :</b> <code>قفل</code> \n<b>لینک ها قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock link$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_link:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>Link Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي لینک :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_links'..chat_id, msg.sender_user_id_)
                redis:del('lock_link:Araz'..chat_id)
                 if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Link Status :</b> <code>UnLock</code>\n<b>Link Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت لینک :</b> <code>باز</code>\n<b>قفل لینک غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status Link
if msg.content_.text_:match("^لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_link:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Link Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('locker_links'..chat_id))..'\n<b>For Unlock Please Use !unlock link</b>'
                else
                  text = '☘️<b>وضعيت لینک:</b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_links'..chat_id))..'\nبرای باز کردن از "بازکردن لینک" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_link:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Link Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unlocker_links'..chat_id))..'\n<b>For lock Please Use !lock link</b>'
                else
                  text = '☘️<b>وضعيت لینک:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_links'..chat_id))..'\nبرای  قفل کردن از "قفل لینک" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
--lock username
            if msg.content_.text_:match("^قفل یوزرنیم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock username$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_username:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Username Status Was :</b> <code>Locked</code> \n<b>Cleaning Username Is Already Locked By:</b> '..get_info(redis:get('locker_username'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي یوزرنیم :</b> <code>قفل</code> \n<b>قفل یوزرنیم از قبل فعال شده بود توسط :</b>\n'..get_info(redis:get('locker_username'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_username:Araz'..chat_id, "True")
                redis:set('locker_username'..chat_id, msg.sender_user_id_)
                               if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Username Status :</b> <code>Locked</code> \n<b>Username Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت یوزرنیم :</b> <code>قفل</code> \n<b>یوزرنیم ها قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن یوزرنیم$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock username$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_username:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>Username Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي یوزرنیم :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_username'..chat_id, msg.sender_user_id_)
                redis:del('lock_username:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Username Status :</b> <code>UnLock</code>\n<b>Username Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت یوزرنیم :</b> <code>باز</code>\n<b>قفل يوزرنيم غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status UserName
if msg.content_.text_:match("^یوزرنیم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]sername$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_username:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>UserName Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('locker_username'..chat_id))..'\n<b>For Unlock Please Use !unlock username</b>'
                else
                  text = '☘️<b>قفل یوزر نیم: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_username'..chat_id))..'\nبرای باز کردن از "باز کردن یوزرنیم" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^یوزرنیم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]sername$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_username:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>username Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unlocker_username'..chat_id))..'\n<b>For Lock Please Use !lock username</b>'
                else
                  text = '☘️<b>وضعیت یوزرنیم</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_username'..chat_id))..'\nبرای قفل کردن از "قفل یوزرنیم" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
            --lock tag
            if msg.content_.text_:match("^قفل تگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock tag$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_tag:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Tag Status Was :</b> <code>Locked</code> \n<b>Cleaning Tag Is Already Locked By :</b> '..get_info(redis:get('locker_tag'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي هشتگ :</b> <code>قفل</code> \n<b>قفل هشتگ از قبل فعال شده بود توسط :</b>\n'..get_info(redis:get('locker_tag'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_tag:Araz'..chat_id, "True")
                redis:set('locker_tag'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Tag Status :</b> <code>Locked</code> \n<b>Tag Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت هشتگ :</b> <code>قفل</code> \n<b>هشتگ ها قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن تگ$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock tag$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_tag:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Tag Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي هشتگ :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_tag'..chat_id, msg.sender_user_id_)
                redis:del('lock_tag:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Tag Status :</b> <code>UnLock</code>\n<b>Tag Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت هشتگ :</b> <code>باز</code>\n<b>قفل يوزرنيم غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status tag			
if msg.content_.text_:match("^تگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Tt]ag$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_tag:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Tag Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('locker_tag'..chat_id))..'\n<b>For Unlock Please Use !unlock tag</b>'
                else
                  text = '☘️<b>وضعیت هشتگ: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_tag'..chat_id))..'\nبرای بازکردن از"بازکردن تگ" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^تگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Tt]ag$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_tag:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Tag Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unlocker_tag'..chat_id))..'\n<b>For Lock Please use !lock tag</b>'
                else
                  text = '☘️<b>وضعیت هشتگ:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_tag'..chat_id))..'\nبرای قفل کردن از"قفل تگ" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
            --arabic/persian
            if msg.content_.text_:match("^قفل فارسی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock persian$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_persian:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Persian/Arabic Status Was :</b> <code>Locked</code> \n<b>Cleaning Persian/Arabic Is Already Locked by :</b> '..get_info(redis:get('locker_persian'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي حروف فارسي :</b> <code>قفل</code> \n<b>قفل حروف فارسي از قبل فعال شده بود توسط :</b>\n'..get_info(redis:get('locker_persian'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_persian:Araz'..chat_id, "True")
                redis:set('locker_persian'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Persian/Arabic Status :</b> <code>Locked</code> \n<b>Persian/Arabic Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت حروف فارسي :</b> <code>قفل</code> \n<b>حروف فارسي قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن فارسی$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock persian$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Uu]nlock persian$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_persian:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Persian/Arabic Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي حروف فارسي :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_persian'..chat_id, msg.sender_user_id_)
                redis:del('lock_persian:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Persian/Arabic Status :</b> <code>UnLock</code>\n<b>Persian/Arabic Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت حروف فارسي :</b> <code>باز</code>\n<b>قفل حروف فارسي غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
		--Status persian
if msg.content_.text_:match("^فارسی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Pp]ersian$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_persian:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Link Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('locker_persian'..chat_id))..'\n<b>For Unlock Please Use !unlock persian</b>'
                else
                  text = '☘️<b>وضعيت فارسي:</b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_persian'..chat_id))..'\nبرای باز کردن از "بازکردن فارسی" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^فارسی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Pp]ersian$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_persian:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Link Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unlocker_persian'..chat_id))..'\n<b>For Lock Please use !lock persian</b>'
                else
                  text = '☘️<b>وضعيت فارسي:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_persian'..chat_id))..'\nبرای  قفل کردن از "قفل فارسی" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
            ---forward
            if msg.content_.text_:match("^قفل فوروارد$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock fwd$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_forward:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Forward Status Was :</b> <code>Locked</code> \n<b>Cleaning Forward Is Already Locked By:</b> '..get_info(redis:get('locker_forward'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي فوروارد :</b> <code>قفل</code> \n<b>قفل فوروارد از قبل فعال شده بود توسط :</b>\n'..get_info(redis:get('locker_forward'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_forward:Araz'..chat_id, "True")
                redis:set('locker_forward'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Forward Status :</b> <code>Locked</code> \n<b>Forward Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت فوروارد :</b> <code>قفل</code> \n<b>فوروارد قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن فوروارد$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock fwd$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_forward:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Forward Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي فوروارد :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_forward'..chat_id, msg.sender_user_id_)
                redis:del('lock_forward:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Forward Status :</b> <code>UnLock</code>\n<b>Forward Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت فوروارد :</b> <code>باز</code>\n<b>قفل فوروارد غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
			--Status fwd			
if msg.content_.text_:match("^فوروارد$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ff]orward$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_forward:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Forward Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('locker_forward'..chat_id))..'\n<b>For Unlock Please Use !unlock fwd</b>'
                else
                  text = '☘️<b>وضعیت فوروارد: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_forward'..chat_id))..'\nبرای باز کردن از"بازکردن فوروارد" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^فوروارد$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ff]orward$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_forward:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Forward Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unlocker_forward'..chat_id))..'\n<b>For Lock Please Use !lock fwd</b>'
                else
                  text = '☘️<b>وضعیت فوروارد:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_forward'..chat_id))..'\nبرای قفل کردن از "قفل کردن فوروارد" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
            --lock curse
            if msg.content_.text_:match("^قفل کلمات زشت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock curse$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_curse:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>curse Status Was :</b> <code>Locked</code> \n<b>Cleaning Curse Is Already Locked By:</b> '..get_info(redis:get('locker_curse'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي کلمات زشت :</b> <code>قفل</code> \n<b>قفل کلمات زشت از قبل فعال شده بود توسط :</b>\n'..get_info(redis:get('locker_curse'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_curse:Araz'..chat_id, "True")
                redis:set('locker_curse'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Curse Status :</b> <code>Locked</code> \n<b>curse Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت کلمات زشت :</b> <code>قفل</code> \n<b>کلمات زشت قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن کلمات زشت$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock curse$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_curse:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Curse Cleaning Was On:</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي کلمات زشت :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_curse'..chat_id, msg.sender_user_id_)
                redis:del('lock_curse:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Curse Status :</b> <code>UnLock</code>\n<b>Curse Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت کلمات زشت :</b> <code>باز</code>\n<b>قفل کلمات زشت غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status curse			
if msg.content_.text_:match("^کلمات زشت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Cc]urse$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_curse:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Curse Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('locker_curse'..chat_id))..'\n<b>For Unlock Please Use !unlock curse</b>'
                else
                  text = '☘️<b>وضعیت کلمات زشت: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_curse'..chat_id))..'\nبرای بازکردن از"بازکردن کلمات زشت" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^کلمات زشت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Cc]urse$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_curse:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>curse Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unlocker_curse'..chat_id))..'\n<b>For Lock Please Use !lock curse</b>'
                else
                  text = '☘️<b>وضعیت کلمات زشت:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_curse'..chat_id))..'\nبرای قفل کردن از"قفل کلمات زشت" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
            --lock location
            if msg.content_.text_:match("^قفل موقعیت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock location$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_location:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Location Status Was :</b> <code>Locked</code> \n<b>Cleaning Location Is Already Locked By:</b> '..get_info(redis:get('locker_location'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي اشتراک مکان :</b> <code>قفل</code> \n<b>قفل اشتراک مکان از قبل فعال شده بود توسط :</b>\n'..get_info(redis:get('locker_location'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_location:Araz'..chat_id, "True")
                redis:set('locker_location'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Location Status :</b> <code>Locked</code> \n<b>Location Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت اشتراک مکان :</b> <code>قفل</code> \n<b>اشتراک مکان قفل شد توسط :</b> \n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن موقعیت$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock location$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_location:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Location Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي اشتراک مکان :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_location'..chat_id, msg.sender_user_id_)
                redis:del('lock_location:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Location Status :</b> <code>UnLock</code>\n<b>Location Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت اشتراک مکان :</b> <code>باز</code>\n<b>قفل اشتراک مکان غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status location			
if msg.content_.text_:match("^موقعیت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ocation$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_location:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>location Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('locker_location'..chat_id))..'\n<b>For Unlock Please Use !unlock location</b>'
                else
                  text = '☘️<b>وضعیت موقعیت: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_location'..chat_id))..'\nبرای بازکردن از"بازکردن موقعیت" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^موقعیت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ocation$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Ll]ocation$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_location:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>location Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unlocker_location'..chat_id))..'\n<b>For Lock Please Use !lock location</b>'
                else
                  text = '☘️<b>وضعیت موقعیت:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_location'..chat_id))..'\nبرای قفل کردن از"قفل موقعیت"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
            --lock edit
            if msg.content_.text_:match("^قفل ویرایش$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock edit$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_edit:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Edit Status Was :</b> <code>Locked</code> \n<b>Cleaning Edit Is Already Locked By:</b> '..get_info(redis:get('locker_edit'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي ويرايش :</b> <code>قفل</code> \n<b>قفل ويرايش از قبل فعال شده بود توسط :</b> \n'..get_info(redis:get('locker_edit'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_edit:Araz'..chat_id, "True")
                redis:set('locker_edit'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Edit Status :</b> <code>Locked</code> \n<b>Edit Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت ويرايش :</b> <code>قفل</code> \n<b>ويرايش قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن ویرایش$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock edit$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_edit:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Edit Cleaning Was On:</b> <code>UnLock</code>\n<b>Status Not Change!</b>'
                else
                  text = '☘️<b>وضعيت قبلي ويرايش :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_edit'..chat_id, msg.sender_user_id_)
                redis:del('lock_edit:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Edit Status :</b> <code>UnLock</code>\n<b>Edit Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت ويرايش :</b> <code>باز</code>\n<b>قفل ويرايش غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
		--Status edit			
if msg.content_.text_:match("^ویرایش$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ee]dit$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_edit:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>edit Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('locker_edit'..chat_id))..'\n<b>For Unlock Please Use !unlock edit</b>'
                else
                  text = '☘️<b>وضعیت ویرایش: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_edit'..chat_id))..'\nبرای بازکردن از"بازکردن ویرایش" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^ویرایش$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ee]edit$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_edit:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Edit Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unlocker_edit'..chat_id))..'\n<b>For Lock Please Use !lock edit</b>'
                else
                  text = '☘️<b>وضعیت ویرایش:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_edit'..chat_id))..'\nبرای قفل کردن از"قفل ویرایش" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --- lock Caption
            if msg.content_.text_:match("^قفل کپشن$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock caption$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_caption:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Caption Status Was :</b> <code>Locked</code> \n<b>Cleaning Caption Is Already Locked By:</b> '..get_info(redis:get('locker_caption'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي زير نويس :</b> <code>قفل</code> \n<b>قفل زير نويس از قبل فعال شده بود توسط :</b>\n'..get_info(redis:get('locker_caption'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_caption:Araz'..chat_id, "True")
                redis:set('locker_caption'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Caption Status :</b> <code>Locked</code> \n<b>Caption Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت زير نويس :</b> <code>قفل</code> \n<b>زير نويس قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن کپشن$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock caption$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_caption:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Caption Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي زير نويس :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_caption'..chat_id, msg.sender_user_id_)
                redis:del('lock_caption:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Caption Status :</b> <code>UnLock</code>\n<b>Caption Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت زير نويس :</b> <code>باز</code>\n<b>قفل زير نويس غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status Caption			
if msg.content_.text_:match("^کپشن$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Cc]aption$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_‌Caption:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>‌Caption Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('locker_caption'..chat_id))..'\n<b>For Unlock Please Use !unlock ‌Caption</b>'
                else
                  text = '☘️<b>وضعیت کپشن: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_‌caption'..chat_id))..'\nبرای بازکردن از"بازکردن کپشن"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^کپشن$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Cc]aption$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_‌Caption:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>‌Caption Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unlocker_caption'..chat_id))..'\n<b>For Lock Please Use !lock ‌Caption</b>'
                else
                  text = '☘️<b>وضعیت کپشن:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_caption'..chat_id))..'\nبرای قفل کردن از "قفل کردن کپشن" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end				
            --lock emoji
            if msg.content_.text_:match("^قفل شکلک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock emoji$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_emoji:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Emoji Status Was :</b> <code>Locked</code> \n<b>Cleaning Emoji Is Already Locked By:</b> '..get_info(redis:get('locker_emoji'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي شکلک ها :</b> <code>قفل</code> \n<b>قفل شکلک ها از قبل فعال شده بود توسط :</b> \n'..get_info(redis:get('locker_emoji'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_emoji:Araz'..chat_id, "True")
                redis:set('locker_emoji'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Emoji Status :</b> <code>Locked</code> \n<b>Emoji Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت شکلک ها :</b> <code>قفل</code> \n<b>شکلک ها قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن شکلک$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock emoji$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_emoji:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Emoji Cleaning Was On:</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي شکلک ها :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_emoji'..chat_id, msg.sender_user_id_)
                redis:del('lock_emoji:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Emoji Status :</b> <code>UnLock</code>\n<b>Emoji Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت شکلک ها :</b> <code>باز</code>\n<b>قفل شکلک ها غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
			--Status emoji			
if msg.content_.text_:match("^شکلک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ee]moji$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_‌emoji:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Emoji Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('locker_emoji'..chat_id))..'\n<b>For Unlock Please Use !unlock emoji</b>'
                else
                  text = '☘️<b>وضعیت شکلک: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_emoji'..chat_id))..'\nبرای بازکردن از"بازکردن شکلک"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^شکلک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ee]moji$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_‌emoji:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>emoji Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unlocker_emoji'..chat_id))..'\n<b>For Lock Please Use !lock emoji</b>'
                else
                  text = '☘️<b>وضعیت شکلک:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_emoji'..chat_id))..'\nبرای قفل کردن از"قفل شکلک" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --- lock inline
            if msg.content_.text_:match("^قفل اینلاین$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock inline$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_inline:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Inline Status Was :</b> <code>Locked</code> \n<b>Cleaning Inline Is Already Locked By:</b> '..get_info(redis:get('locker_inline'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي اينلاين :</b> <code>قفل</code> \n<b>قفل اينلاين از قبل فعال شده بود توسط :</b> \n'..get_info(redis:get('locker_inline'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_inline:Araz'..chat_id, "True")
                redis:set('locker_inline'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Inline Status :</b> <code>Locked</code> \n<b>Inline Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت اينلاين :</b> <code>قفل</code> \n<b>اينلاين قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن اینلاین$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock inline$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_inline:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Inline Cleaning Was On:</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي اينلاين :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_inline'..chat_id, msg.sender_user_id_)
                redis:del('lock_inline:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Inline Status :</b> <code>UnLock</code>\n<b>Inline Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت اينلاين :</b> <code>باز</code>\n<b>قفل اينلاين غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status inline			
if msg.content_.text_:match("^اینلاین$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ii]nline$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_inline:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>inline Status:</b> <code>Locked</code> \n<b>Locked by :</b>'..get_info(redis:get('locker_inline'..chat_id))..'\n<b>For Unlock Please Use !unlock inline</b>'
                else
                  text = '☘️<b>وضعیت اینلاین: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_inline'..chat_id))..'\nبرای بازکردن از "بازکردن اینلاین"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^اینلاین$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ii]nline$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_inline:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>inline Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b>'..get_info(redis:get('unlocker_inline'..chat_id))..'\n<b>For Lock Please Use !lock inline</b>'
                else
                  text = '☘️<b>وضعیت اینلاین:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_inline'..chat_id))..'\nبرای قفل کردن از"قفل اینلاین"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	

            -- lock english

            if msg.content_.text_:match("^قفل انگلیسی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock english$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_english:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>English Status Was :</b> <code>Locked</code> \n<b>Cleaning English Are Already Locked By:</b> '..get_info(redis:get('locker_english'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي حروف انگليسي :</b> <code>قفل</code> \n<b>قفل حروف انگليسي از قبل فعال شده بود توسط :</b> \n'..get_info(redis:get('locker_english'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_english:Araz'..chat_id, "True")
                redis:set('locker_english'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>English Status :</b> <code>Locked</code> \n<b>English Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت حروف انگليسي :</b> <code>قفل</code> \n<b>حروف انگليسي قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن انگلیسی$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock english$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_english:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌English Cleaning Was On:</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي حروف انگليسي :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_english'..chat_id, msg.sender_user_id_)
                redis:del('lock_english:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>English Status :</b> <code>UnLock</code>\n<b>English Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت حروف انگليسي :</b> <code>باز</code>\n<b>قفل حروف انگليسي غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status english			
if msg.content_.text_:match("^انگلیسی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ee]nglish$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en"then
 if redis:get('lock_english:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>english Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('locker_english'..chat_id))..'\n<b>For Unlock Please Use !unlock english</b>'
                else
                  text = '☘️<b>وضعیت انگلیسی : </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_english'..chat_id))..'\nبرای بازکردن از"بازکردن انگلیسی"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^انگلیسی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ee]nglish$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_english:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>english Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b>'..get_info(redis:get('unlocker_english'..chat_id))..'\n<b>For Lock Please use !lock english</b>'
                else
                  text = '☘️<b>وضعیت انگلیسی : </b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_english'..chat_id))..'\nبرای قفل کردن از"قفل انگلیسی"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
            -- lock reply
            if msg.content_.text_:match("^قفل پاسخ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock reply$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_reply:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Reply Status Was :</b> <code>Locked</code> \n<b>Cleaning Reply Is Already Locked By :</b> '..get_info(redis:get('locker_reply'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي پاسخ به پيام :</b> <code>قفل</code> \n<b>قفل پاسخ به پيام از قبل فعال شده بود توسط :</b> \n'..get_info(redis:get('locker_reply'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_reply:Araz'..chat_id, "True")
                redis:set('locker_reply'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Reply Status :</b> <code>Locked</code> \n<b>Reply Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت پاسخ به پيام :</b> <code>قفل</code> \n<b>پاسخ به پيام قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن پاسخ$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock reply$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Uu]nlock reply$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_reply:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Reply Cleaning Was On:</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي پاسخ به پيام :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_reply'..chat_id, msg.sender_user_id_)
                redis:del('lock_reply:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Reply Status :</b> <code>UnLock</code>\n<b>Reply Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت پاسخ به پيام :</b> <code>باز</code>\n<b>قفل پاسخ به پيام غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
			--Status reply			
if msg.content_.text_:match("^پاسخ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Rr]eply$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_‌reply:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>reply Status:</b> <code>Locked</code> \n<b>Locked by :</b>'..get_info(redis:get('locker_reply'..chat_id))..'\n<b>For Unlock Please Use !unlock reply</b>'
                else
                  text = '☘️<b>وضعیت پاسخ: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_reply'..chat_id))..'\nبرای بازکردن از"بازکردن پاسخ"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^پاسخ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Rr]eply$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_‌reply:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>reply Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b>'..get_info(redis:get('unlocker_reply'..chat_id))..'\n<b>For Lock Please Use !lock reply</b>'
                else
                  text = '☘️<b>وضعیت پاسخ:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_reply'..chat_id))..'\nبرای قفل کردن از "قفل پاسخ"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --lock tgservice
            if msg.content_.text_:match("^قفل اعلان$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock tgservice$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_tgservice:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Tgservice Status Was :</b> <code>Locked</code> \n<b>Cleaning TGservice Is Already Locked By:</b> '..get_info(redis:get('locker_tgservice'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي پيام ورود خروج :</b> <code>قفل</code> \n<b>قفل پيام ورود خروج از قبل فعال شده بود توسط :</b> \n'..get_info(redis:get('locker_tgservice'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_tgservice:Araz'..chat_id, "True")
                redis:set('locker_tgservice'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Tgservice Status :</b> <code>Locked</code> \n<b>Tgservice Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت پيام ورود خروج :</b> <code>قفل</code> \n<b>پيام ورود خروج قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن اعلان$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock tgservice$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en"then
              if not redis:get('lock_tgservice:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Tgservice Cleaning Was On:</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي پيام ورود خروج :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_tgservice'..chat_id, msg.sender_user_id_)
                redis:del('lock_tgservice:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Tgservice Status :</b> <code>UnLock</code>\n<b>Tgservice Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت پيام ورود خروج :</b> <code>باز</code>\n<b>قفل پيام ورود خروج غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status tgservice			
if msg.content_.text_:match("^اعلان$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Tt]gservice$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_‌tgservice:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>tgservice Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('locker_tgservice'..chat_id))..'\n<b>For Unlock Please Use !unlock tgservice</b>'
                else
                  text = '☘️<b>وضعیت اعلان: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_tgservice'..chat_id))..'\nبرای بازکردن از"بازکردن اعلان"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^اعلان$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Tt]gservice$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_‌tgservice:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>tgservice Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unlocker_‌tgservice'..chat_id))..'\n<b>For lock Please use !lock tgservice</b>'
                else
                  text = '☘️<b>وضعیت اعلان:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_tgservice'..chat_id))..'\nبرای قفل کردن از "قفل اعلان"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --lock spam
            if msg.content_.text_:match("^قفل اسپم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock spam$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_spam:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Spam Status Was :</b> <code>Locked</code> \n<b>Cleaning Spam Is Already Locked By:</b> '..get_info(redis:get('locker_spam'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي پيام طولاني :</b> <code>قفل</code> \n<b>قفل پيام طولاني از قبل فعال شده بود توسط :</b> \n'..get_info(redis:get('locker_spam'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_spam:Araz'..chat_id, "True")
                redis:set('locker_spam'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Spam Status :</b> <code>Locked</code> \n<b>Spam Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت پيام طولاني :</b> <code>قفل</code> \n<b>پيام طولاني قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن اسپم$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock spam$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_spam:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Spam Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي پيام طولاني :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_spam'..chat_id, msg.sender_user_id_)
                redis:del('lock_spam:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Spam Status :</b> <code>UnLock</code>\n<b>Spam Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت پيام طولاني :</b> <code>باز</code>\n<b>قفل پيام طولاني غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status spam			
if msg.content_.text_:match("^اسپم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ss]pam$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_‌spam:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>spam Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('locker_spam'..chat_id))..'\n<b>For Unlock Please Use !unlock spam</b>'
                else
                  text = '☘️<b>وضعیت اسپم: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_spam'..chat_id))..'\nبرای بازکردن از"بازکردن اسپم"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^اسپم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ss]pam$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_‌spam:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>spam Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unlocker_spam'..chat_id))..'\n<b>For Lock Please Use !lock spam</b>'
                else
                  text = '☘️<b>وضعیت اسپم:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_spam'..chat_id))..'\nبرای قفل کردن از "قفل اسپم"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            -- flood lock
            if msg.content_.text_:match("^قفل حساسیت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock flood$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('lock_flood:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Flood Status Was :</b> <code>Locked</code> \n<b>Cleaning Flood Is Already Locked By:</b> '..get_info(redis:get('locker_flood'..chat_id))..''
                else
                  text = '☘️<b>وضعيت قبلي پيام رگباري :</b> <code>قفل</code> \n<b>قفل پيام رگباري از قبل فعال شده بود توسط :</b> \n'..get_info(redis:get('locker_flood'..chat_id))..''
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('lock_flood:Araz'..chat_id, "True")
                redis:set('locker_flood'..chat_id, msg.sender_user_id_)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Flood Status :</b> <code>Locked</code> \n<b>Flood Has been Locked by :</b> '..get_info(msg.sender_user_id_)..''
                else
                  text = '☘️<b>وضعيت پيام رگباري :</b> <code>قفل</code> \n<b>پيام رگباري قفل شد توسط :</b>\n'..get_info(msg.sender_user_id_)..''
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
            if msg.content_.text_:match("^باز کردن حساسیت$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock flood$")  and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('lock_flood:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text ='☘️<b>‌Flood Cleaning Was on :</b> <code>UnLock</code>\n<b>Status Not Changed!</b>'
                else
                  text = '☘️<b>وضعيت قبلي پيام رگباري :</b> <code>باز</code>\n<b>وضعيت تغيير نکرد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              else
                redis:set('unlocker_flood'..chat_id, msg.sender_user_id_)
                redis:del('lock_flood:Araz'..chat_id)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️<b>Flood Status :</b> <code>UnLock</code>\n<b>Flood Cleaning is Disabled !</b>'
                else
                  text = '☘️<b>وضعيت پيام رگباري :</b> <code>باز</code>\n<b>قفل پيام رگباري غير فعال شد !</b>'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
              end
            end
--Status flood			
if msg.content_.text_:match("^حساسیت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ff]lood$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('lock_‌flood:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>flood Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('locker_flood'..chat_id))..'\n<b>For Unlock Please Use !unlock flood</b>'
                else
                  text = '☘️<b>وضعیت حساسیت: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('locker_flood'..chat_id))..'\nبرای بازکردن از "بازکردن حساسیت"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^حساسیت$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ff]lood$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('lock_‌flood:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>flood Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unlocker_flood'..chat_id))..'\n<b>For Lock Please Use !lock flood</b>'
                else
                  text = '☘️<b>وضعیت حساسیت:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unlocker_flood'..chat_id))..'\nبرای قفل کردن از"قفل حساسیت"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
--SetFloodNum
            if msg.content_.text_:match("^[!][Ss]etfloodnum (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              local floodmax = {string.match(msg.content_.text_, "^[!](setfloodnum) (%d+)$")}
              if tonumber(floodmax[2]) < 2 then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Wrong Number*\n_Range Is  [2-99]_'
                else
                  text = '☘️*عدد اشتباه است !*\n_محدوده عدد براي تعيين :  [2-99]_'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                redis:set('floodnum:Araz'..msg.chat_id_,floodmax[2])
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*> Flood Number Set To* : `['..floodmax[2]..']` *!*'
                else
                  text = '☘️*> تعداد حساسيت به پيام رگباري تنظيم شد به * : `['..floodmax[2]..']` *!*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--SetFloodNumFa
            if msg.content_.text_:match("^تنظیم تعداد حساسیت (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
              local floodmax = {string.match(msg.content_.text_, "^(تنظیم تعداد حساسیت) (%d+)$")}
              if tonumber(floodmax[2]) < 2 then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Wrong number*\n_range is  [2-99]_'
                else
                  text = '☘️*عدد اشتباه است !*\n_محدوده عدد براي تعيين :  [2-99]_'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                redis:set('floodnum:Araz'..msg.chat_id_,floodmax[2])
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*> Flood Number has been set to* : `['..floodmax[2]..']` *!*'
                else
                  text = '☘️*> تعداد حساسيت به پيام رگباري تنظيم شد به * : `['..floodmax[2]..']` *!*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--SetSpam
            if msg.content_.text_:match("^[!][Ss]etspam (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              local maxspam = {string.match(msg.content_.text_, "^[!](setspam) (%d+)$")}
              if tonumber(maxspam[2]) < 20 or tonumber(maxspam[2]) > 2000 then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Refused!*\n*Wrong Number of Value !*\n*SMust Be Between *`[20-2000]` *!*'
                else
                  text = '☘️*خطا !*\n*مقدار تعيين شده اشتباه ميباشد !*\n*ميبايست بين *`[20-2000]` *باشد !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil,text , 1, 'md')
              else
                redis:set('maxspam:Araz'..msg.chat_id_,maxspam[2])
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*> Spam Characters has been set to* : `['..maxspam[2]..']`'
                else
                  text = '☘️*> ميزان حد مجازي پيام طولاني تنظيم شد به* : `['..maxspam[2]..']`'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--SetSpamFa
            if msg.content_.text_:match("^تنظیم اسپم (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
              local maxspam = {string.match(msg.content_.text_, "^(تنظیم اسپم) (%d+)$")}
              if tonumber(maxspam[2]) < 20 or tonumber(maxspam[2]) > 2000 then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Refused!*\n*Wrong Number of Value !*\n*Should be between *`[20-2000]` *!*'
                else
                  text = '☘️*خطا !*\n*مقدار تعيين شده اشتباه ميباشد !*\n*ميبايست بين *`[20-2000]` *باشد !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil,text , 1, 'md')
              else
                redis:set('maxspam:Araz'..msg.chat_id_,maxspam[2])
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*> Spam Characters has been set to* : `['..maxspam[2]..']`'
                else
                  text = '☘️*> ميزان حد مجازي پيام طولاني تنظيم شد به* : `['..maxspam[2]..']`'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--SetFloodTime
            if msg.content_.text_:match("^[!][Ss]etfloodtime (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              local floodt = {string.match(msg.content_.text_, "^[!](setfloodtime) (%d+)$")}
              if tonumber(floodt[2]) < 2 or tonumber(floodt[2]) > 999 then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Refused!*\n*Wrong Number Of Value !*\n*Must Be Between *`[2-99]` *!*'
                else
                  text = '☘️*خطا !*\n*مقدار تعيين شده اشتباه ميباشد !*\n*ميبايست بين *`[2-99]` *باشد !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil,text , 1, 'md')
              else
                redis:set('floodtime:Araz'..msg.chat_id_,floodt[2])
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*> Flood Time has been set to* : `['..floodt[2]..']`'
                else
                  text = '☘️*> زمان پيام رگباري تنظيم شد به* : `['..floodt[2]..']`'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--SetFloodTimeFa
            if msg.content_.text_:match("^تنظیم زمان حساسیت (%d+)$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
              local floodt = {string.match(msg.content_.text_, "^(تنظیم زمان حساسیت) (%d+)$")}
              if tonumber(floodt[2]) < 2 or tonumber(floodt[2]) > 999 then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Refused!*\n*Wrong Number of Value !*\n*Should be between *`[2-99]` *!*'
                else
                  text = '☘️*خطا !*\n*مقدار تعيين شده اشتباه ميباشد !*\n*ميبايست بين *`[2-99]` *باشد !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil,text , 1, 'md')
              else
                redis:set('floodtime:Araz'..msg.chat_id_,floodt[2])
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*> Flood Time has been set to* : `['..floodt[2]..']`'
                else
                  text = '☘️*> زمان پيام رگباري تنظيم شد به* : `['..floodt[2]..']`'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Setlink
            if msg.content_.text_:match("^تنظیم لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ss]etlink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Ss]etlink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = '☘️*Please Send Group Link Now!*'
              else
                text = '☘️*لطفا لينک گروه را ارسال کنيد !*'
              end
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              redis:set("bot:group:link"..msg.chat_id_, 'Link Set Status : `Waiting !`')
            end
--Link
            if msg.content_.text_:match("^لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              local link = redis:get("bot:group:link"..msg.chat_id_)
              if link then
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>لینک گروه:</b>\n'..link, 1, 'html')
              else
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️_هیچ لینکی تاکنون ثبت نشده است_\n☘️_لطفا بااستفاده از_ `setlink` _لینک خودرا ثبت کنید_', 1, 'md')
              end
            end
--SettingsColorTexts
			local link = 'lock_link:Araz'..chat_id
            if redis:get(link) then
              link = "`Lock`"
            else
              link = "`Unlock`"
            end

            local bots = 'lock_bots:Araz'..chat_id
            if redis:get(bots) then
              bots = "`Lock`"
            else
              bots = "`Unlock`"
            end

            local flood = 'lock_flood:Araz'..msg.chat_id_
            if redis:get(flood) then
              flood = "`Lock`"
            else
              flood = "`Unlock`"
            end

            local spam = 'lock_spam:Araz'..chat_id
            if redis:get(spam) then
              spam = "`Lock`"
            else
              spam = "`Unlock`"
            end

            local username = 'lock_username:Araz'..chat_id
            if redis:get(username) then
              username = "`Lock`"
            else
              username = "`Unlock`"
            end

            local tag = 'lock_tag:Araz'..chat_id
            if redis:get(tag) then
              tag = "`Lock`"
            else
              tag = "`Unlock`"
            end

            local forward = 'lock_forward:Araz'..chat_id
            if redis:get(forward) then
              forward = "`Lock`"
            else
              forward = "`Unlock`"
            end

            local arabic = 'lock_persian:Araz'..chat_id
            if redis:get(arabic) then
              arabic = "`Lock`"
            else
              arabic = "`Unlock`"
            end

            local eng = 'lock_english:Araz'..chat_id
            if redis:get(eng) then
              eng = "`Lock`"
            else
              eng = "`Unlock`"
            end

            local badword = 'lock_curse:Araz'..chat_id
            if redis:get(badword) then
              badword = "`Lock`"
            else
              badword = "`Unlock`"
            end

            local edit = 'lock_edit:Araz'..chat_id
            if redis:get(edit) then
              edit = "`Lock`"
            else
              edit = "`Unlock`"
            end

            local location = 'lock_location:Araz'..chat_id
            if redis:get(location) then
              location = "`Lock`"
            else
              location = "`Unlock`"
            end

            local emoji = 'lock_emoji:Araz'..chat_id
            if redis:get(emoji) then
              emoji = "`Lock`"
            else
              emoji = "`Unlock`"
            end


            if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              lang = '`English`'
            else
              lang = '`Persian`'
            end


            local caption = 'lock_caption:Araz'..chat_id
            if redis:get(caption) then
              caption = "`Lock`"
            else
              caption = "`Unlock`"
            end

            local inline = 'lock_inline:Araz'..chat_id
            if redis:get(inline) then
              inline = "`Lock`"
            else
              inline = "`Unlock`"
            end

            local reply = 'lock_reply:Araz'..chat_id
            if redis:get(reply) then
              reply = "`Lock`"
            else
              reply = "`Unlock`"
            end
            --muteall
            groups = redis:sismember('groups:Araz',chat_id)
            if msg.content_.text_:match("^قفل همه$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock all$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Ll]ock all$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_all:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute All is already on*'
                else
                  text = '☘️*همه ي پيام ها  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute All Has Been Enabled !*'
                else
                  text = '☘️*همه ي پيام ها حذف خواهند شد ( گروه تعطيل شد ) *'
                end
				redis:set('muter_all'..chat_id, msg.sender_user_id_)
                redis:set('mute_all:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
			--Status muteall			
if msg.content_.text_:match("^همه$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Aa]ll$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_all:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Muteall Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('muter_all'..chat_id))..'\n<b>For Unlock Please Use !unlock spam</b>'
                else
                  text = '☘️<b>وضعیت قفل همه: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_all'..chat_id))..'\nبرای بازکردن از"بازکردن همه"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^همه$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Aa]ll$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_all:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Muteall Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unmuter_all'..chat_id))..'\n<b>For lock Please use !lock spam</b>'
                else
                  text = '☘️<b>وضعیت قفل همه:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_all'..chat_id))..'\nبرای قفل کردن از"قفل همه"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
			--muteallM
            groups = redis:sismember('groups:Araz',chat_id)
		if msg.content_.text_:match("^[!]lock all (%d+)$") and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
		local a = {string.match(msg.content_.text_, "^[!](lock all) (%d+)$")}
		local day = tonumber(60)
              if redis:get('mute_all:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute All is already on*'
                else
                  text = '☘️*همه ي پيام ها  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
			  	local time = a[2] * day
								redis:set('muter_all'..chat_id, msg.sender_user_id_)
				redis:setex("mute_all:Araz"..chat_id,time,true)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️Mute All Has Been Enabled for '..a[2]..' Minutes!'
                else
                  text = '☘️همه ي پيام ها حذف خواهند شد برای '..a[2]..' دقیقه ( گروه تعطيل شد )'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
			--muteallMFa
            groups = redis:sismember('groups:Araz',chat_id)
		if msg.content_.text_:match("^قفل همه (%d+)$") and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
		local a = {string.match(msg.content_.text_, "^(قفل همه) (%d+)$")}
		local day = tonumber(60)
              if redis:get('mute_all:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute All is already on*'
                else
                  text = '☘️*همه ي پيام ها  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
			  	local time = a[2] * day
								redis:set('muter_all'..chat_id, msg.sender_user_id_)
				redis:setex("mute_all:Araz"..chat_id,time,true)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️Mute All Has Been Enabled for '..a[2]..' Minutes!'
                else
                  text = '☘️همه ي پيام ها حذف خواهند شد برای '..a[2]..' دقیقه ( گروه تعطيل شد )'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end

            if msg.content_.text_:match("^باز کردن همه$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock all$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_all:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute All Is Already Disables!*'
                else
                  text = '☘️*همه ي پيام ها از قبل حذف نميشدند !*'
                end

                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute All has been Disabled*'
                else
                  text = '☘️*همه ي پيام ها از حالت حذف خارج شدند ( گروه باز شد ) !*'
                end
								redis:set('unmuter_all'..chat_id, msg.sender_user_id_)
                redis:del('mute_all:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end


            --mute game


            if msg.content_.text_:match("^قفل بازی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock game$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_game:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Game Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل بازي  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute game Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل بازي حذف خواهند شد *'
                end
								redis:set('muter_game'..chat_id, msg.sender_user_id_)
                redis:set('mute_game:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
						--muteGame
            groups = redis:sismember('groups:Araz',chat_id)
		if msg.content_.text_:match("^[!]lock game (%d+)$") and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
		local a = {string.match(msg.content_.text_, "^[!](lock game) (%d+)$")}
		local day = tonumber(60)
              if redis:get('mute_game:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Games is already on*'
                else
                  text = '☘️* بازی ها از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
			  	local time = a[2] * day
								redis:set('muter_game'..chat_id, msg.sender_user_id_)
				redis:setex("mute_game:Araz"..chat_id,time,true)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️Mute Games Has Been Enabled for '..a[2]..' Minutes!'
                else
                  text = '☘️بازی ها حذف خواهند شد برای '..a[2]..' دقیقه'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
			--mutegameFA
            groups = redis:sismember('groups:Araz',chat_id)
		if msg.content_.text_:match("^قفل بازی (%d+)$") and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
		local a = {string.match(msg.content_.text_, "^(قفل بازی) (%d+)$")}
		local day = tonumber(60)
              if redis:get('mute_game:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Game All is already on*'
                else
                  text = '☘️*بازی ها  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
			  	local time = a[2] * day
								redis:set('muter_game'..chat_id, msg.sender_user_id_)
				redis:setex("mute_game:Araz"..chat_id,time,true)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️Mute Game Has Been Enabled for '..a[2]..' Minutes!'
                else
                  text = '☘️بازی ها حذف خواهند شد برای '..a[2]..' دقیقه'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
			
            if msg.content_.text_:match("^باز کردن بازی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock game$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_game:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Game Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل بازي از قبل حذف نميشدند !*'
                end

                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute game has been disabled*'
                else
                  text = '☘️*پيام هاي شامل بازي از حالت حذف خارج شدند !*'
                end
								redis:set('unmuter_game'..chat_id, msg.sender_user_id_)

                redis:del('mute_game:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status game			
if msg.content_.text_:match("^بازی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Gg]ame$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_game:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Game Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('muter_game'..chat_id))..'\n<b>For Unlock Please Use !unlock game</b>'
                else
                  text = '☘️<b>وضعیت قفل بازی: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_game'..chat_id))..'\nبرای بازکردن از"بازکردن بازی"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^بازی$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Gg]ame$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_game:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Game Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unmuter_game'..chat_id))..'\n<b>For Lock Please Use !lock game</b>'
                else
                  text = '☘️<b>وضعیت قفل بازی:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_game'..chat_id))..'\nبرای قفل کردن از"قفل بازی"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	

            --mute sticker


            if msg.content_.text_:match("^قفل استیکر$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock sticker$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_sticker:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute sticker is already on*'
                else
                  text = '☘️*پيام هاي شامل استيکر  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute sticker Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل استيکر حذف خواهند شد *'
                end
				redis:set('muter_sticker'..chat_id, msg.sender_user_id_)
                redis:set('mute_sticker:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
									--muteSticker
            groups = redis:sismember('groups:Araz',chat_id)
		if msg.content_.text_:match("^[!]lock sticker (%d+)$") and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
		local a = {string.match(msg.content_.text_, "^[!](lock sticker) (%d+)$")}
		local day = tonumber(60)
              if redis:get('mute_sticker:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Sticker Is Already On!*'
                else
                  text = '☘️* استیکر ها از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
			  	local time = a[2] * day
								redis:set('muter_sticker'..chat_id, msg.sender_user_id_)
				redis:setex("mute_sticker:Araz"..chat_id,time,true)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️Mute sticker Has Been Enabled for '..a[2]..' Minutes!'
                else
                  text = '☘️استیکر ها حذف خواهند شد برای '..a[2]..' دقیقه'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
			--mutestickerFA
            groups = redis:sismember('groups:Araz',chat_id)
		if msg.content_.text_:match("^قفل استیکر (%d+)$") and is_admin(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
		local a = {string.match(msg.content_.text_, "^(قفل استیکر) (%d+)$")}
		local day = tonumber(60)
              if redis:get('mute_sticker:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Sticker Cleaning is already on*'
                else
                  text = '☘️*استیکر ها  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
			  	local time = a[2] * day
								redis:set('muter_sticker'..chat_id, msg.sender_user_id_)
				redis:setex("mute_sticker:Araz"..chat_id,time,true)
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️Mute Sticker Has Been Enabled for '..a[2]..' Minutes!'
                else
                  text = '☘️استیکر ها حذف خواهند شد برای '..a[2]..' دقیقه'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن استیکر$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock sticker$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_sticker:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Sticker Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل استيکر از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute sticker has been disabled*'
                else
                  text = '☘️*پيام هاي شامل استيکر از حالت حذف خارج شدند !*'
                end
 				redis:set('unmuter_sticker'..chat_id, msg.sender_user_id_)
               redis:del('mute_sticker:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status sticker			
if msg.content_.text_:match("^استیکر$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ss]ticker$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_sticker:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Sticker Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('muter_sticker'..chat_id))..'\n<b>For Unlock Please Use !unlock sticker</b>'
                else
                  text = '☘️<b>وضعیت قفل استیکر: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_sticker'..chat_id))..'\nبرای بازکردن از"بازکردن استیکر"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^استیکر$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ss]ticker$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_sticker:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Sticker Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unmuter_sticker'..chat_id))..'\n<b>For Lock Please Use !lock sticker</b>'
                else
                  text = '☘️<b>وضعیت قفل استیکر:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_sticker'..chat_id))..'\nبرای قفل کردن از"قفل استیکر"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	

            --mute gif

            if msg.content_.text_:match("^قفل گیف$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock gif$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_gif:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Gif Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل گيف  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute gif Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل گيف حذف خواهند شد *'
                end
				redis:set('muter_gif'..chat_id, msg.sender_user_id_)
                redis:set('mute_gif:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن گیف$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock gif$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_gif:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Gif Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل گيف از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute gif has been disabled*'
                else
                  text = '☘️*پيام هاي شامل گيف از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_gif'..chat_id, msg.sender_user_id_)
                redis:del('mute_gif:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status gif			
if msg.content_.text_:match("^گیف$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Gg]if$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_gif:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Gif Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('muter_gif'..chat_id))..'\n<b>For Unlock Please Use !unlock gif</b>'
                else
                  text = '☘️<b>وضعیت قفل گیف: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_gif'..chat_id))..'\nبرای بازکردن از"بازکردن گیف"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^گیف$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Gg]if$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_gif:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Gif Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unmuter_gif'..chat_id))..'\n<b>For Lock Please Use !lock gif</b>'
                else
                  text = '☘️<b>وضعیت قفل گیف:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_gif'..chat_id))..'\nبرای قفل کردن از"قفل گیف"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	


            --mute markdown

            if msg.content_.text_:match("^قفل رنگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock markdown$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_markdown:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Markdown Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل رنگ  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Markdown Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل رنگ حذف خواهند شد *'
                end
				redis:set('muter_markdown'..chat_id, msg.sender_user_id_)
                redis:set('mute_markdown:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن رنگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock markdown$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_markdown:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Markdown Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل رنگ از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Markdown has been disabled*'
                else
                  text = '☘️*پيام هاي شامل رنگ از حالت حذف خارج شدند !*'
                end
 				redis:set('unmuter_markdown'..chat_id, msg.sender_user_id_)
               redis:del('mute_markdown:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status markdown			
if msg.content_.text_:match("^رنگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Mm]arkdown$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_markdown:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>markdown Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('muter_markdown'..chat_id))..'\n<b>For Unlock Please use /unlock markdown</b>'
                else
                  text = '☘️<b>وضعیت قفل رنگ: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_markdown'..chat_id))..'\nبرای بازکردن از "بازکردن رنگ"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^رنگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Mm]arkdown$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_markdown:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>markdown Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unmuter_markdown'..chat_id))..'\n<b>For Lock Please Use !lock markdown</b>'
                else
                  text = '☘️<b>وضعیت قفل رنگ:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_markdown'..chat_id))..'\nبرای قفل کردن از "قفل رنگ" استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	

            --mute weblink


            if msg.content_.text_:match("^قفل وب لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock weblink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_weblink:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Web Link Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل لينک سايت  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Web Link Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل لينک سايت حذف خواهند شد *'
                end
				redis:set('muter_weblink'..chat_id, msg.sender_user_id_)
                redis:set('mute_weblink:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن وب لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock weblink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_weblink:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Web Link is already disabled*'
                else
                  text = '☘️*پيام هاي شامل لينک سايت از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Web Link has been disabled*'
                else
                  text = '☘️*پيام هاي شامل لينک سايت از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_weblink'..chat_id, msg.sender_user_id_)
                redis:del('mute_weblink:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status weblink			
if msg.content_.text_:match("^وب لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ww]eblink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_weblink:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>weblink Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('muter_weblink'..chat_id))..'\n<b>For Unlock Please Use !unlock weblink</b>'
                else
                  text = '☘️<b>وضعیت قفل وب لینک: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_weblink'..chat_id))..'\nبرای بازکردن از"بازکردن وب لینک"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^وب لینک$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ww]eblink$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_weblink:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>weblink Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unmuter_weblink'..chat_id))..'\n<b>For Lock Please Use !lock weblink</b>'
                else
                  text = '☘️<b>وضعیت قفل وب لینک:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_weblink'..chat_id))..'\nبرای قفل کردن از"قفل وب لینک"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	

            --mute Keyboard

            if msg.content_.text_:match("^قفل کیبورد$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[/!#][Ll]ock keyboard$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Ll]ock keyboard$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_keyboard:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Keyboard is already on*'
                else
                  text = '☘️*پيام هاي شامل دکمه شيشه اي ربات ها  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Keyboard Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل دکمه شيشه اي ربات ها حذف خواهند شد *'
                end
				redis:set('muter_keyboard'..chat_id, msg.sender_user_id_)
                redis:set('mute_keyboard:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^بازکردن کیبورد$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[/!#][Uu]nlock keyboard$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Uu]nlock keyboard$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_keyboard:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Keyboard is already disabled*'
                else
                  text = '☘️*پيام هاي شامل دکمه شيشه اي ربات ها از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Keyboard has been disabled*'
                else
                  text = '☘️*پيام هاي شامل دکمه شيشه اي ربات ها از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_keyboard'..chat_id, msg.sender_user_id_)
                redis:del('mute_keyboard:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status Keyboard			
if msg.content_.text_:match("^کیبورد$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[/#!][Kk]eyboard$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Kk]eyboard$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_keyboard:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Keyboard Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('muter_keyboard'..chat_id))..'\n<b>For Unlock Please use /unlock Keyboard</b>'
                else
                  text = '☘️<b>وضعیت قفل کیبورد: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_keyboard'..chat_id))..'\nبرای بازکردن از"بازکردن کیبورد"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^کیبورد$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[/#!][Kk]eyboard$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" or msg.content_.text_:match("^[Kk]eyboard$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_keyboard:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Keyboard Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unmuter_keyboard'..chat_id))..'\n<b>For lock Please use /lock Keyboard</b>'
                else
                  text = '☘️<b>وضعیت قفل کیبورد:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_keyboard'..chat_id))..'\nبرای قفل کردن از"قفل کیبورد"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	

            --mute contact


            if msg.content_.text_:match("^قفل مخاطب$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock contact$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_contact:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Is Already On!*'
                else
                  text = '☘️*پيام هاي اشتراک مخاطب  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute contact Has Been Enabled*'
                else
                  text = '☘️*پيام هاي اشتراک مخاطب حذف خواهند شد *'
                end
				redis:set('muter_contact'..chat_id, msg.sender_user_id_)
                redis:set('mute_contact:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن مخاطب$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock contact$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_contact:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Contact Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي اشتراک مخاطب از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute contact has been disabled*'
                else
                  text = '☘️*پيام هاي اشتراک مخاطب از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_contact'..chat_id, msg.sender_user_id_)
                redis:del('mute_contact:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status contact			
if msg.content_.text_:match("^مخاطب$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Cc]ontact$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_contact:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>contact Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('muter_contact'..chat_id))..'\n<b>For Unlock Please Use !unlock contact</b>'
                else
                  text = '☘️<b>وضعیت قفل مخاطب: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_contact'..chat_id))..'\nبرای بازکردن از"بازکردن مخاطب"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^مخاطب$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Cc]ontact$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_contact:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>contact Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unmuter_contact'..chat_id))..'\n<b>For Lock Please Use !lock contact</b>'
                else
                  text = '☘️<b>وضعیت قفل مخاطب:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_contact'..chat_id))..'\nبرای قفل کردن از"قفل مخاطب"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --mute photo

            if msg.content_.text_:match("^قفل عکس$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock photo$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_photo:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Photo Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل عکس  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Photo Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل عکس حذف خواهند شد *'
                end
				redis:set('muter_photo'..chat_id, msg.sender_user_id_)
                redis:set('mute_photo:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن عکس$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock photo$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_photo:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Photo Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل عکس از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Photo has been disabled*'
                else
                  text = '☘️*پيام هاي شامل عکس از حالت حذف خارج شدند !*'
                end
 				redis:set('unmuter_photo'..chat_id, msg.sender_user_id_)
               redis:del('mute_photo:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status photo			
if msg.content_.text_:match("^عکس$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Pp]hoto$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_photo:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>photo Status:</b> <code>Locked</code> \n<b>Locked by :</b> '..get_info(redis:get('muter_photo'..chat_id))..'\n<b>For Unlock Please Use !unlock photo</b>'
                else
                  text = '☘️<b>وضعیت قفل عکس: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_photo'..chat_id))..'\nبرای بازکردن از"بازکردن عکس"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^عکس$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Pp]hoto$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_photo:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>photo Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unmuter_photo'..chat_id))..'\n<b>For lock Please use /lock photo</b>'
                else
                  text = '☘️<b>وضعیت قفل عکس:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_photo'..chat_id))..'\nبرای قفل کردن از"قفل عکس"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --mute audio
            if msg.content_.text_:match("^قفل آهنگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock audio$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_audio:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Audio Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل ترانه و موسيقي  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Audio Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل ترانه و موسيقي  حذف خواهند شد *'
                end
				redis:set('muter_audio'..chat_id, msg.sender_user_id_)
                redis:set('mute_audio:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن آهنگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock audio$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_audio:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Audio Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل ترانه و موسيقي  از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Audio has been disabled*'
                else
                  text = '☘️*پيام هاي شامل ترانه و موسيقي  از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_audio'..chat_id, msg.sender_user_id_)
                redis:del('mute_audio:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status audio			
if msg.content_.text_:match("^آهنگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Aa]udio$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_audio:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Audio Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('muter_audio'..chat_id))..'\n<b>For Unlock Please Use !unlock audio</b>'
                else
                  text = '☘️<b>وضعیت قفل آهنگ: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_audio'..chat_id))..'\nبرای بازکردن از"بازکردن آهنگ"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^آهنگ$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Aa]udio$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_audio:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Audio Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unmuter_audio'..chat_id))..'\n<b>For Lock Please Use !lock audio</b>'
                else
                  text = '☘️<b>وضعیت قفل آهنگ:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_audio'..chat_id))..'\nبرای قفل کردن از"قفل آهنگ"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --mute voice
            if msg.content_.text_:match("^قفل صدا$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock voice$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_voice:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Voice is already on*'
                else
                  text = '☘️*پيام هاي شامل صدا  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Voice Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل صدا حذف خواهند شد *'
                end
				redis:set('muter_voice'..chat_id, msg.sender_user_id_)
                redis:set('mute_voice:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن صدا$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock voice$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_voice:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Voice Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل صدا از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Voice has been disabled*'
                else
                  text = '☘️*پيام هاي شامل صدا از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_voice'..chat_id, msg.sender_user_id_)
                redis:del('mute_voice:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status voice			
if msg.content_.text_:match("^صدا$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Vv]oice$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_voice:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>voice Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('muter_voice'..chat_id))..'\n<b>For Unlock Please Use !unlock voice</b>'
                else
                  text = '☘️<b>وضعیت قفل صدا: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_voice'..chat_id))..'\nبرای بازکردن از"بازکردن صدا"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^صدا$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Vv]oice$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_voice:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>voice Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unmuter_voice'..chat_id))..'\n<b>For Lock Please Use !lock voice</b>'
                else
                  text = '☘️<b>وضعیت قفل صدا:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_voice'..chat_id))..'\nبرای قفل کردن از"قفل صدا"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --mute video
            if msg.content_.text_:match("^قفل فیلم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock video$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_video:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Video Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل فيلم  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Video Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل فيلم حذف خواهند شد *'
                end
 				redis:set('muter_video'..chat_id, msg.sender_user_id_)
               redis:set('mute_video:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن فیلم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock video$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_video:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Video Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل فيلم از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Video has been disabled*'
                else
                  text = '☘️*پيام هاي شامل فيلم از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_video'..chat_id, msg.sender_user_id_)
                redis:del('mute_video:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status video			
if msg.content_.text_:match("^فیلم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Vv]ideo$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_video:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>video Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('muter_video'..chat_id))..'\n<b>For Unlock Please Use !unlock video</b>'
                else
                  text = '☘️<b>وضعیت قفل فیلم: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_video'..chat_id))..'\nبرای بازکردن از"بازکردن فیلم"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^فیلم$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Vv]ideo$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_video:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>video Status:</b> <code>UnLocked</code> \n<b>UnLocked By :</b> '..get_info(redis:get('unmuter_video'..chat_id))..'\n<b>For Lock Please Use !lock video</b>'
                else
                  text = '☘️<b>وضعیت قفل فیلم:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_video'..chat_id))..'\nبرای قفل کردن از"قفل فیلم"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	
            --mute document

            if msg.content_.text_:match("^قفل فایل$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock document$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_document:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Document [ File ] Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل فايل  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Document [ File ] Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل فايل حذف خواهند شد *'
                end
				redis:set('muter_document'..chat_id, msg.sender_user_id_)
                redis:set('mute_document:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن فایل$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock document$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_document:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Document [ File ] Is Already Disabled!*'
                else
                  text = '☘️*پيام هاي شامل فايل از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Document [ File ] has been disabled*'
                else
                  text = '☘️*پيام هاي شامل فايل از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_document'..chat_id, msg.sender_user_id_)
                redis:del('mute_document:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status document			
if msg.content_.text_:match("^فایل$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Dd]ocument$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_document:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Document Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('muter_document'..chat_id))..'\n<b>For Unlock Please Use !unlock document</b>'
                else
                  text = '☘️<b>وضعیت قفل فایل: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_document'..chat_id))..'\nبرای بازکردن از"بازکردن فایل"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^فایل$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Dd]ocument$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_document:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>document Status:</b> <code>UnLocked</code> \n<b>UnLocked by :</b> '..get_info(redis:get('unmuter_document'..chat_id))..'\n<b>For Lock Please Use !lock document</b>'
                else
                  text = '☘️<b>وضعیت قفل فایل:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_document'..chat_id))..'\nبرای قفل کردن از"قفل فایل"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	

            --mute text


            if msg.content_.text_:match("^قفل متن$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ll]ock text$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if redis:get('mute_text:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Text Is Already On!*'
                else
                  text = '☘️*پيام هاي شامل متن  از قبل در حالت حذف شدن هستند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Text Has Been Enabled*'
                else
                  text = '☘️*پيام هاي شامل متن حذف خواهند شد *'
                end
				redis:set('muter_text'..chat_id, msg.sender_user_id_)
                redis:set('mute_text:Araz'..chat_id, "True")
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
            if msg.content_.text_:match("^باز کردن متن$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Uu]nlock text$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              if not redis:get('mute_text:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Text is already disabled*'
                else
                  text = '☘️*پيام هاي شامل متن از قبل حذف نميشدند !*'
                end
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              else
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                  text = '☘️*Mute Text has been disabled*'
                else
                  text = '☘️*پيام هاي شامل متن از حالت حذف خارج شدند !*'
                end
				redis:set('unmuter_text'..chat_id, msg.sender_user_id_)
                redis:del('mute_text:Araz'..chat_id)
                tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
              end
            end
--Status text			
if msg.content_.text_:match("^متن$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Tt]ext$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if redis:get('mute_text:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>Text Status:</b> <code>Locked</code> \n<b>Locked By:</b> '..get_info(redis:get('muter_text'..chat_id))..'\n<b>For Unlock Please Use !unlock text</b>'
                else
                  text = '☘️<b>وضعیت قفل متن: </b> <code>قفل</code> \n<b>قفل شده توسط:</b>\n'..get_info(redis:get('muter_text'..chat_id))..'\nبرای بازکردن از"بازکردن متن"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end
if msg.content_.text_:match("^متن$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Tt]ext$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
 if not redis:get('mute_text:Araz'..chat_id) then
                if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
				text = '☘️<b>text Status:</b> <code>UnLocked</code> \n<b>UnLocked By:</b> '..get_info(redis:get('unmuter_text'..chat_id))..'\n<b>For Lock Please Use !lock text</b>'
                else
                  text = '☘️<b>وضعیت قفل متن:</b> <code>باز</code> \n<b>باز شده توسط:</b>\n'..get_info(redis:get('unmuter_text'..chat_id))..'\nبرای قفل کردن از"قفل متن"استفاده کنید'
                end
                return tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
end
end	

 --settings
            local all = 'mute_all:Araz'..chat_id
            if redis:get(all) then
              All = "`Mute`"
            else
              All = "`UnMute`"
            end

            local spammax = 'maxspam:Araz'..chat_id
            if not redis:get(spammax) then
              spammax = tonumber(2000)
            else
              spammax = redis:get('maxspam:Araz'..chat_id)
            end

            if not redis:get('floodnum:Araz'..msg.chat_id_) then
              floodnum = 5
            else
              floodnum = redis:get('floodnum:Araz'..msg.chat_id_)
            end
            ------------
            if not redis:get('floodtime:Araz'..msg.chat_id_) then
              floodtime = 3
            else
              floodtime = redis:get('floodtime:Araz'..msg.chat_id_)
            end

            local sticker = 'mute_sticker:Araz'..chat_id
            if redis:get(sticker) then
              sticker = "`Mute`"
            else
              sticker = "`UnMute`"
            end


            local game = 'mute_game:Araz'..chat_id
            if redis:get(game) then
              game = "`Mute`"
            else
              game = "`UnMute`"
            end

            local keyboard = 'mute_keyboard:Araz'..chat_id
            if redis:get(keyboard) then
              keyboard = "`Mute`"
            else
              keyboard = "`UnMute`"
            end

            local gif = 'mute_gif:Araz'..chat_id
            if redis:get(gif) then
              gif = "`Mute`"
            else
              gif = "`UnMute`"
            end

            local markdown = 'mute_markdown:Araz'..chat_id
            if redis:get(markdown) then
              markdown = "`Mute`"
            else
              markdown= "`UnMute`"
            end

            local weblink = 'mute_weblink:Araz'..chat_id
            if redis:get(weblink) then
              weblink = "`Mute`"
            else
              weblink = "`UnMute`"
            end

            local contact = 'mute_contact:Araz'..chat_id
            if redis:get(contact) then
              contact = "`Mute`"
            else
              contact = "`UnMute`"
            end

            local photo = 'mute_photo:Araz'..chat_id
            if redis:get(photo) then
              photo = "`Mute`"
            else
              photo = "`UnMute`"
            end

            local audio = 'mute_audio:Araz'..chat_id
            if redis:get(audio) then
              audio = "`Mute`"
            else
              audio = "`UnMute`"
            end

            local voice = 'mute_voice:Araz'..chat_id
            if redis:get(voice) then
              voice = "`Mute`"
            else
              voice = "`UnMute`"
            end

            local video = 'mute_video:Araz'..chat_id
            if redis:get(video) then
              video = "`Mute`"
            else
              video = "`UnMute`"
            end

            local document = 'mute_document:Araz'..chat_id
            if redis:get(document) then
              document = "`Mute`"
            else
              document = "`UnMute`"
            end

            local text1 = 'mute_text:Araz'..chat_id
            if redis:get(text1) then
              text1 = "`Mute`"
            else
              text1 = "`UnMute`"
            end

            local ex = redis:ttl("bot:charge:Araz"..msg.chat_id_)
            if ex == -1 then
              exp_dat = 'Unlimited'
            else
              exp_dat = math.floor(ex / 86400) + 1
            end

            if msg.content_.text_:match("^تنظیمات$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" or msg.content_.text_:match("^[!][Ss]ettings$") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en"  then
              if redis:hget(msg.chat_id_, "lang:Araz") == "en" then
                text = "☘️_Settings ARAZ:_".."\n➖➖➖➖➖➖➖➖➖\n"
                .."🔹*Lock Link : *"..link.."".."\n"
                .."🔸*Lock Tag : *"..""..tag.."".."\n"
                .."🔹*Lock Username : *"..""..username.."".."\n"
                .."🔸*Lock Fwd : *"..""..forward.."".."\n"
                .."🔹*Lock Persian : *"..""..arabic..''..'\n'
                .."🔸*Lock English : *"..""..eng..''..'\n'
                .."🔹*Lock Reply : *"..""..reply..''..'\n'
                .."🔸*Lock Curse : *"..""..badword..''..'\n'
                .."🔹*Lock Edit : *"..""..edit..''..'\n'
                .."🔸*Lock Location : *"..""..location..''..'\n'
                .."🔹*Lock Caption : *"..""..caption..''..'\n'
                .."🔸*Lock Inline : *"..""..inline..''..'\n'
                .."🔹*Lock Emoji : *"..""..emoji..''..'\n'
                .."🔸*Lock All : *"..""..All.."".."\n"
                .."🔹*Lock Keyboard : *"..""..keyboard.."".."\n"
                .."🔸*Lock Sticker : *"..""..sticker.."".."\n"
                .."🔹*Lock Markdown : *"..""..markdown.."".."\n"
                .."🔸*Lock WebLinks : *"..""..weblink.."".."\n"
                .."🔹*Lock Game : *"..""..game.."".."\n"
                .."🔸*Lock Gif : *"..""..gif.."".."\n"
                .."🔹*Lock Contact : *"..""..contact.."".."\n"
                .."🔸*Lock Photo : *"..""..photo.."".."\n"
                .."🔹*Lock Audio : *"..""..audio.."".."\n"
                .."🔸*Lock Voice : *"..""..voice.."".."\n"
                .."🔹*Lock Video : *"..""..video.."".."\n"
                .."🔸*Lock Document : *"..""..document.."".."\n"
                .."🔹*Lock Text : *"..text1.."\n➖➖➖➖➖➖➖➖➖\n"
                .."🔸*Flood Time :* `"..floodtime.."`\n"
                .."🔹*Flood Num : *`"..floodnum.."`\n"
        .."🔸*Max Character : *`"..spammax.."`\n"
		                .."🔸*Lock Spam : *"..spam.."\n➖➖➖➖➖➖➖➖➖\n"
        .."🔹*Group Language :* "..lang.."\n"
          .."🔸*Expire Time :* `"..exp_dat.."` *Days Later !*\n" 
        .."🔹*Version* : `8.5`\n"
        .."🔹*Channel* : *@NeTGuarD_COM*"
              else
                text = "☘️_تنظیمات ربات آراز :_".."\n➖➖➖➖➖➖➖➖➖\n"
                .."#قفل لينک : "..link.."".."\n"
                .."#قفل تگ : "..""..tag.."".."\n"
                .."#قفل نام کاربري : "..""..username.."".."\n"
                .."#قفل فوروارد ( نقل قول ) : "..""..forward.."".."\n"
                .."#قفل حروف فارسي : "..""..arabic..''..'\n'
                .."#قفل حروف انگليسي : "..""..eng..''..'\n'
                .."#قفل ريپلي ( پاسخ ب پيام ) : "..""..reply..''..'\n'
                .."#قفل کلمات زشت  : "..""..badword..''..'\n'
                .."#قفل ويرايش پيام : "..""..edit..''..'\n'
                .."#قفل اشتراک مکان : "..""..location..''..'\n'
                .."#قفل متن زير عکس و ... : "..""..caption..''..'\n'
                .."#قفل حالت اينلاين ربات ها : "..""..inline..''..'\n'
                .."#قفل شکلک ها : "..""..emoji..''..'\n'
                .."#قفل همه پيام ها ( تعطيلي گروه ) : "..""..All.."".."\n"
                .."#قفل کیبورد: "..""..keyboard.."".."\n"
                .."#قفل استيکر : "..""..sticker.."".."\n"
                .."#قفل پيام هاي زيبا : "..""..markdown.."".."\n"
                .."#قفل لينک سايت : "..""..weblink.."".."\n"
                .."#قفل بازي هاي رباتي : "..""..game.."".."\n"
                .."#قفل گيف ( عکس متحرک ) : "..""..gif.."".."\n"
                .."#قفل اشتراک مخاطب : "..""..contact.."".."\n"
                .."#قفل عکس : "..""..photo.."".."\n"
                .."#قفل ترانه : "..""..audio.."".."\n"
                .."#قفل صدا : "..""..voice.."".."\n"
                .."#قفل فيلم : "..""..video.."".."\n"
                .."#قفل فايل : "..""..document.."".."\n"
                .."#قفل پيام متني : "..text1.."\n➖➖➖➖➖➖➖➖➖\n"
                .."#زمان رگباري : `"..floodtime.."`\n"
                .."#تعداد رگباري : `"..floodnum.."`\n"
                .."#قفل پيام رگباري: "..flood.."\n"
                .."#بيشترين مقدار کاراکتر پيام : `"..spammax.."`\n"
                .."#قفل پيام با کاراکتر بالا : "..spam.."\n➖➖➖➖➖➖➖➖➖\n"
                .."#زبان گروه : "..lang.."\n"
                .."#تاريخ انقضاي گروه : `"..exp_dat.."` *روز بعد !*\n"
                .."#ورژن : `8.5`\n"
                .."#کانال ما : *NeTGuarD_COM@*"
                text1 = string.gsub(text,"`Lock`", "`[🔹|فعال]`")
                text2 = string.gsub(text1,"`Unlock`","`[🔸|غیرفعال]`")
                text3 = string.gsub(text2,"`English`","`[انگليسي]`")
                text4 = string.gsub(text3,"`Persian`","`[فارسی]`")
                text5 = string.gsub(text4,"`Mute`","`[🔹|فعال]`")
                text6 = string.gsub(text5,"`UnMute`","`[🔸|غیرفعال]`")
                text = text6
              end
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'md')
            end
            if msg.content_.text_:match("^[!][Ff]wd$") then
              tdcli.forwardMessages(chat_id, chat_id,{[0] = reply_id}, 0)
            end



            if msg.content_.text_:match("^[!]ownerlist$") and is_admin(msg) then
              text = "☘️<i>لیست مالکان :</i>\n\n"
              for k,v in pairs(redis:smembers("bot:groupss:Araz")) do
                tt = redis:get('owners:Araz'..v)
                text = text.."<b>"..k.."</b> > "..tt..""
              end
              tdcli.sendText(msg.chat_id_, msg.id_, 0, 1, nil, text, 1, 'html')
            end

            if msg.content_.text_:match("^[!][Ff]wdall$") and msg.reply_to_message_id_ then
              for k,v in pairs(redis:hkeys("bot:groupss:Araz")) do
                tdcli.forwardMessages(v, chat_id,{[0] = reply_id}, 0)
              end
            end

            if msg.content_.text_:match("^[!][Ss]etusername") and is_sudo(msg) then
              tdcli.changeUsername(string.sub(input, 10))
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Username Changed To </b>@'..string.sub(input, 11), 1, 'html')
            end

           if msg.content_.text_:match("^[!][Ee]cho") and is_mod(msg) then
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, string.sub(input, 6), 1, 'html')
            end
            if msg.content_.text_:match("^[!][Ss]etname") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "en" then
              tdcli.changeChatTitle(chat_id, string.sub(input, 9), 1)
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>SuperGroup Name Changed To </b><code>'..string.sub(input, 10)..'</code>', 1, 'html')
            end
			if msg.content_.text_:match("^تنظیم نام") and is_mod(msg) and redis:hget(msg.chat_id_, "lang:Araz") == "fa" then
              tdcli.changeChatTitle(chat_id, string.sub(input, 9), 1)
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>نام سوپرگروه تغییر کرد به </b><code>'..string.sub(input, 10)..'</code>', 1, 'html')
            end
            if msg.content_.text_:match("^[!][Cc]hangename") and is_sudo(msg) then
              tdcli.changeName(string.sub(input, 12), nil, 1)
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Bot Name Changed To :</b><code>'..string.sub(input, 13)..'</code>', 1, 'html')
            end
            if msg.content_.text_:match("^[!][Cc]hangeuser") and is_sudo(msg) then
              tdcli.changeUsername(string.sub(input, 12), nil, 1)
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Bot UserName Changed To </b><code>'..string.sub(input, 13)..'</code>', 1, 'html')
            end
            if msg.content_.text_:match("^[!][Dd]eluser") and is_sudo(msg) then
              tdcli.changeUsername('')
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️`Done!`\n*Username Deleted!*', 1, 'html')
            end
            if msg.content_.text_:match("^[!][Ee]dit") and is_admin(msg) then
              tdcli.editMessageText(chat_id, reply_id, nil, string.sub(input, 6), 'html')
            end



            if msg.content_.text_:match("^[!][Ii]nvite") and is_admin(msg) then
              tdcli.addChatMember(chat_id, string.sub(input, 9), 20)
            end
            if msg.content_.text_:match("^[!][Cc]reatesuper") and is_sudo(msg) then
              tdcli.createNewChannelChat(string.sub(input, 14), 1, 'My Supergroup, My Rules')
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>SuperGroup </b>'..string.sub(input, 14)..' <b>Created!</b>', 1, 'html')
            end

            if msg.content_.text_:match('^[!][Ww]hois (%d+)$') and is_mod(msg) then
              matches = {string.match(msg.content_.text_, "^[Ww]hois (%d+)$")}
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, "☘️<b>User:</b> "..get_info(matches[2]), 1, 'html')
            end
            if msg.content_.text_:match("^[!][Dd][Ee][Ll]") and msg.reply_to_message_id_ ~= 0 and is_mod(msg)then
              tdcli.deleteMessages(msg.chat_id_, {[0] = msg.reply_to_message_id_})
              tdcli.deleteMessages(msg.chat_id_, {[0] = msg.id_})
            end

            if msg.content_.text_:match('^!tosuper') and is_mod(msg) then
              local gpid = msg.chat_id_
              tdcli.migrateGroupChatToChannelChat(gpid)
            end

            if msg.content_.text_:match("^!markread on$") and is_mod(msg) then
		redis:set('markread'..msg.chat_id_, true)
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Mark Read Enabled!</b>', 1, 'html')
	     end
		if msg.content_.text_:match("^!markread off$") and is_mod(msg) then
		redis:del('markread'..msg.chat_id_)
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Mark Read Disabled!</b>', 1, 'html')
	     end
            if msg.content_.text_:match("^!view") and is_mod(msg) then
              tdcli.viewMessages(chat_id, {[0] = msg.id_})
              tdcli.sendText(chat_id, msg.id_, 0, 1, nil, '☘️<b>Messages Viewed</b>', 1, 'html')
            end
          end
        end
        ---
if msg.content_.reply_markup_ then
          if redis:get('mute_keyboard:Araz'..chat_id) or redis:get('mute_all:Araz'..msg.chat_id_) then
            if  msg.content_.reply_markup_ and not is_mod(msg) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
            end
          end
        end
        --------------------------------------------------__

        function check_username(extra,result,success)
          --vardump(result)
          local username = (result.username_ or '')
          local svuser = 'user:'..result.id_
          if username then
            redis:hset(svuser, 'username', username)
          end
          if username and username:match("(.*)[Bb][Oo][Tt]$") then
            if redis:get('lock_bots:Araz'..msg.chat_id_) and not is_mod(msg) then
              chat_kick(msg.chat_id_, result.id_)
              return false
            end
          end
        end

if msg.content_.entities_ and msg.content_.entities_[0] then
	if msg.content_.entities_[0].ID == "MessageEntityUrl" or msg.content_.entities_[0].ID == "MessageEntityTextUrl" then
 if redis:get('mute_weblink:Araz'..msg.chat_id_) then
	  if is_mod(msg) then
            return
          else
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end
        end
end

---Msg Checks
	if msg.content_.entities_[0].ID == "MessageEntityBold" or msg.content_.entities_[0].ID == "MessageEntityCode" or msg.content_.entities_[0].ID == "MessageEntityPre" or msg.content_.entities_[0].ID == "MessageEntityItalic" then

        if redis:get('mute_markdown:Araz'..msg.chat_id_) then
          if is_mod(msg) then
            return
          else
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end
        end
        end
end
--Check Forwarded
if msg.content_.ID == "MessageForwarded" then


	if redis:get('lock_forward:Araz'..msg.chat_id_) or redis:get('mute_all:Araz'..msg.chat_id_) then
              tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end



if redis:get('lock_link:Araz'..chat_id) and msg.content_.text_:find("[Hh]ttps://[Tt][Ee][Ll][Ee][Gg][Rr][Aa][Mm].[Mm][Ee]/(.*)") and not is_mod(msg) or redis:get('lock_link:Araz'..chat_id) and msg.content_.text_:find("[Hh]ttps://[Tt].[Mm][Ee]/(.*)") and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

          if redis:get('lock_tag:Araz'..chat_id) and msg.content_.text_:find("#") and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

          if redis:get('lock_username:Araz'..chat_id) and msg.content_.text_:find("@") and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

          if redis:get('lock_persian:Araz'..chat_id) and msg.content_.text_:find("[\216-\219][\128-\191]") and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end



          local is_english_msg = msg.content_.text_:find("[a-z]") or msg.content_.text_:find("[A-Z]")
          if redis:get('lock_english:Araz'..chat_id) and is_english_msg and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

          local is_curse_msg = msg.content_.text_:find("کیر") or msg.content_.text_:find("کص") or msg.content_.text_:find("کون") or msg.content_.text_:find("جنده") or msg.content_.text_:find("قهبه") or msg.content_.text_:find("گایید") or msg.content_.text_:find("سکس") or msg.content_.text_:find("kir") or msg.content_.text_:find("kos") or msg.content_.text_:find("kon")
          if redis:get('lock_curse:Araz'..chat_id) and is_curse_msg and not is_mod(msg) then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

            local is_emoji_msg = input:match("😀") or input:match("😬") or input:match("😁") or input:match("😂") or  input:match("😃") or input:match("😄") or input:match("😅") or input:match("☺️") or input:match("🙃") or input:match("🙂") or input:match("😊") or input:match("😉") or input:match("😇") or input:match("😆") or input:match("😋") or input:match("😌") or input:match("😍") or input:match("😘") or input:match("😗") or input:match("😙") or input:match("😚") or input:match("🤗") or input:match("😎") or input:match("🤓") or input:match("🤑") or input:match("😛") or input:match("😏") or input:match("😶") or input:match("😐") or input:match("😑") or input:match("😒") or input:match("🙄") or input:match("🤔") or input:match("😕") or input:match("😔") or input:match("😡") or input:match("😠") or input:match("😟") or input:match("😞") or input:match("😳") or input:match("🙁") or input:match("☹️") or input:match("😣") or input:match("😖") or input:match("😫") or input:match("😩") or input:match("😤") or input:match("😲") or input:match("😵") or input:match("😭") or input:match("😓") or input:match("😪") or input:match("😥") or input:match("😢") or input:match("🤐") or input:match("😷") or input:match("🤒") or input:match("🤕") or input:match("😴") or input:match("💋") or input:match("❤️")
          if redis:get('lock_emoji:Araz'..chat_id) and is_emoji_msg and not is_mod(msg)  then
            tdcli.deleteMessages(chat_id, {[0] = msg.id_})
          end

	end


	     local _nl, ctrl_chars = string.gsub(msg.content_.text_, "%c", "")
            local _nl, real_digits = string.gsub(msg.content_.text_, "%d", "")
            if redis:get('lock_spam:Araz'..msg.chat_id_)  and  string.len(msg.content_.text_) > tonumber(redis:get('maxspam:Araz'..msg.chat_id_)) and not is_mod(msg)  then
              tdcli.deleteMessages(msg.chat_id_, {[0] = msg.id_})
            end

--AntiFlood
  if redis:get('lock_flood:Araz'..msg.chat_id_) then
    local hash = 'user:'..msg.sender_user_id_..':msgs'
    local msgs = tonumber(redis:get(hash) or 0)
     local user = msg.sender_user_id_
	local chat = msg.chat_id_
if not redis:get('floodnum:Araz'..msg.chat_id_) then
          NUM_MSG_MAX = tonumber(5)
        else
          NUM_MSG_MAX = tonumber(redis:get('floodnum:Araz'..msg.chat_id_))
        end
if not redis:get('floodtime:Araz'..msg.chat_id_) then
          TIME_CHECK = tonumber(5)
        else
          TIME_CHECK = tonumber(redis:get('floodtime:Araz'..msg.chat_id_))
        end
    if msgs > NUM_MSG_MAX then
  if is_mod(msg) then
    return
  end
if redis:get('sender:'..user..':flood') then
return
else
                  tdcli.deleteMessages(msg.chat_id_, {[0] = msg.id_})
                  tdcli.changeChatMemberStatus(msg.chat_id_, msg.sender_user_id_, 'Kicked')
	if redis:hget("lang:Araz"..msg.chat_id_) == "en" then
	text = "☘️<b>User :</b> "..get_info(msg.sender_user_id_).." <b>Has been Kicked Because of Flooding !</b>"
	else
	text = "☘️<i>کاربر :</i> "..get_info(msg.sender_user_id_).." <i>بدليل دادن پيام رگباري غير مجاز از گروه حذف شد !</i>"
	end
            tdcli.sendText(chat_id, msg.id_, 0, 1, nil, text, 1, 'html')
redis:setex('sender:'..user..':flood', 30, true)
    end
end
    redis:setex(hash, TIME_CHECK, msgs+1)
      end

--CheckEdited
end
        elseif data.ID == "UpdateMessageEdited" then
          vardump(data)
          if redis:get('lock_edit:Araz'..data.chat_id_) then
            tdcli.deleteMessages(data.chat_id_, {[0] = tonumber(data.message_id_)})
          end
        elseif data.message_ and data.message_.content_.members_ and data.message_.content_.members_[0].type_.ID == 'UserTypeBot' then --IS bot
          local gid = tonumber(data.message_.chat_id_)
          local uid = data.message_.sender_user_id_
          local aid = data.message_.content_.members_[0].id_
          local id = data.message_.id_
          if redis:get('lock_bots:Araz'..data.chat_id_) then
            tdcli.changeChatMemberStatus(gid, aid, 'Kicked')
          end


        elseif (data.ID == "UpdateOption" and data.name_ == "my_id") then


          tdcli_function ({
            ID="GetChats",
            offset_order_="9223372036854775807",
            offset_chat_id_=0,
            limit_=20
          }, dl_cb, nil)
        end
      end

--ArazV8.5
--Programmer:Hamidreza Eslamzadeh(@Hamidreza_Esh)
--Copyright ©2018 By NeTGuarD Team

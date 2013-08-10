
$window = $(window)

{ Button, StringInput } = window.Doodad
{ View, Model, Collection } = window.Backbone






class Channel extends Model
    sendNewMessage: (body, cb) =>
        console.log @get('messages_url'), body
        $.post @get('messages_url'), { body: body }, (success) ->
            active_channel_messages.fetch()
            cb()

    getType: ->
        if @get('inbox_count')?
            if @get('outbox_count')?
                return 'message'
            return 'subscription'
        return 'broadcast'

class ChannelCollection extends Collection
    model: Channel


active_channel = null
channel_collection = new ChannelCollection()
channel_collection.url = '/channels'

channel_collection.on 'sync', ->
    console.log 'reset!', channel_collection


class ListItem extends View
    className: 'ListItem'
    tagName: 'li'
    render: -> @el

class ChannelListItem extends ListItem
    render: ->
        total = 0
        if @model.get('inbox_count')?
            total += @model.get('inbox_count')
            @$el.addClass('has_inbox')
        if @model.get('outbox_count')
            total += @model.get('outbox_count')
            @$el.addClass('has_outbox')?
        @$el.text(@model.get('name'))
        @$el.append("<span class='count'>#{ total }</span>")
        return super
    events:
        'click': '_activate'

    _activate: ->
        $(".#{ @className }.active").removeClass('active')
        @$el.addClass('active')
        activateChannel(@model)

ONE_WEEK = 1000 * 60 * 60 * 24 * 7

class MessageListItem extends ListItem
    render: ->
        @$el.addClass("box-#{ @model.get('box') }")
        console.log @model.attributes
        message_date = new Date(@model.get('date'))

        _renderDate = ->
            _pad = (n) ->
                if n < 10
                    return "0#{ n }"
                return "#{ n }"

            if (new Date() - message_date) > ONE_WEEK
                readable_time = "#{ message_date.getFullYear() }-#{ message_date.getMonth() + 1 }-#{ message_date.getDate() }"
            else
                readable_time = message_date.toRelativeTime()
            return """
                <time datetime="#{ message_date }" title="#{ message_date.toString() }">#{ readable_time }</time>
            """

        _renderLink = ->
            return """
                <a class="permalink" href="/##{ message_date.getTime() }">∞</a>
            """

        from = if @model.get('box') is 'inbox' then @model.channel.get('name') else 'me'

        @$el.html """
            <div class="meta">
                <span class="from">#{ from }</span>
                #{ _renderDate() }
            </div>
            <div class="body">
                #{ markdown.toHTML(@model.get('body')) }
            </div>
        """
        if @model.get('attachments_url')
            @$el.addClass('has-attachments')
            @_displayAttachments()

        return @el

    _displayAttachments: =>
        console.log '_displayAttachments'
        $attachments_el = $('<ul class="attachments"></ul>')
        @$el.append($attachments_el)
        $.getJSON @model.get('attachments_url'), (attachments) ->
            console.log attachments
            attachments.forEach (attachment) ->
                $attachments_el.append """
                    <li class="attachment">#{ renderAttachmentContent(attachment) }</li>
                """



renderAttachmentContent = (attachment) ->
    markup = "<a href='#{ attachment.url }' target='_blank'>"
    if attachment.type.indexOf('image') is 0
        markup += "<img src='#{ attachment.url }' title='#{ attachment.name }'>"
    else
        markup += attachment.name
    markup += '</a>'
    return markup



class ListView extends View
    className: 'ListView'
    tagName: 'ul'

    initialize: (opts) ->
        @_collection = opts.collection
        if opts.item_view
            @_item_view = opts.item_view
        else
            @_item_view = ListItem
        if opts.filter?
            @_list_filter = opts.filter
        else
            @_list_filter = -> true
        @listenTo(@_collection, 'sync', @render)

    render: =>
        @$el.empty()

        @_collection.each (item) =>
            if @_list_filter(item)
                item_view = new @_item_view
                    model: item
                @$el.append(item_view.render())
        return @el




withinRange = (n, min, max) ->
    if n < min
        return min
    if n > max
        return max
    return n

active_channel = new Channel()
active_channel_messages = new Collection()

active_channel_messages.on 'sync', ->
    active_channel_messages.each (msg) ->
        msg.channel = active_channel

activateChannel = (channel) ->
    active_channel.set(channel.toJSON())
    active_channel_messages.url = active_channel.get('messages_url')
    active_channel_messages.fetch()




class NewMessageForm extends View
    initialize: ->

        @listenTo(@model, 'change', @render)

        MESSAGE_PANEL_DEFAULT_SIZE = 50
        new_message_field = new StringInput
            multiline: true
            placeholder: 'New message...'
            size:
                width: '100%'
                height: MESSAGE_PANEL_DEFAULT_SIZE
            on:
                focus: (si, val) =>
                    send_message_button.show()
                    _.defer =>
                        new_height = withinRange(si._ui.input[0].scrollHeight, 200, 500)
                        new_message_field.setSize(height: new_height)
                        @_setListHeight()

                blur: (si, val) =>
                    unless val
                        send_message_button.hide()
                        _.defer -> new_message_field.setSize(height: MESSAGE_PANEL_DEFAULT_SIZE)
                        @_setListHeight()

            action: (si, value) =>
                if value
                    new_height = withinRange(si._ui.input[0].scrollHeight, 200, 500)
                    _.defer =>
                        send_message_button.enable()
                        new_message_field.setSize(height: new_height)
                        @_setListHeight()
                else
                    send_message_button.disable()
                    new_message_field.setSize(height: MESSAGE_PANEL_DEFAULT_SIZE)

        send_message_button = new Button
            id: 'send_message_button'
            label: 'Send Message'
            spinner: true
            enabled: false
            action: =>
                new_message_field.disable()
                active_channel.sendNewMessage new_message_field.value, =>
                    console.log 'sent message'
                    send_message_button.disable().hide()
                    new_message_field.setValue('')
                    new_message_field.setSize(height: MESSAGE_PANEL_DEFAULT_SIZE)
                    @_setListHeight()

        @_new_message_field = new_message_field
        @_send_message_button = send_message_button
        send_message_button.hide()

    render: =>
        if @model.getType() is 'subscription'
            @$el.hide()
        else
            @$el.show()
        @$el.empty()
        @$el.append(@_new_message_field.render())
        @$el.append(@_send_message_button.render())
        @_setListHeight()
        

    _setListHeight: =>
        $list_el = $('#channel_messages_list')
        _.defer ->
            console.log 'updating list height'
            height = $window.height() - $list_el.offset().top - 20
            $list_el.css
                height: height



setUpInterface = ->

    $('#app').html """
        <div id="panel_channels">
            <div class="label">Messages</div>
            <ul id="channel_messages"></ul>

            <div class="label">Broadcasts</div>
            <ul id="channel_broadcasts"></ul>
            
            <div class="label">Subscriptions</div>
            <ul id="channel_subscriptions"></ul>
        </div>
        <div id="panel_messages">
            <div id="new_message_form"></div>
            <ul id="channel_messages_list"></ul>
        </div>
    """

    new ListView
        collection: channel_collection
        el: $('#channel_messages')
        filter: (c) -> c.getType() is 'message'
        item_view: ChannelListItem

    new ListView
        collection: channel_collection
        el: $('#channel_broadcasts')
        filter: (c) -> c.getType() is 'broadcast'
        item_view: ChannelListItem

    new ListView
        collection: channel_collection
        el: $('#channel_subscriptions')
        filter: (c) -> c.getType() is 'subscription'
        item_view: ChannelListItem

    new NewMessageForm
        model: active_channel
        el: $('#new_message_form')

    new ListView
        collection: active_channel_messages
        item_view: MessageListItem
        el: $('#channel_messages_list')


    

setUpInterface()
channel_collection.fetch()

{ Button, StringInput } = window.Doodad
{ View, Model, Collection } = window.Backbone






class Channel extends Model
    sendNewMessage: (body, cb) =>
        console.log @get('messages_url'), body
        $.post @get('messages_url'), { body: body }, (success) ->
            active_channel_messages.fetch()
            cb()
    getType: ->
        if @get('has_inbox')
            if @get('has_outbox')
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
        if @model.get('has_inbox')
            @$el.addClass('has_inbox')
        if @model.get('has_outbox')
            @$el.addClass('has_outbox')
        @$el.text(@model.get('name'))
        return super
    events:
        'click': '_activate'

    _activate: ->
        $(".#{ @className }.active").removeClass('active')
        @$el.addClass('active')
        activateChannel(@model)

class MessageListItem extends ListItem
    render: ->
        @$el.addClass("box-#{ @model.get('box') }")

        _format = (date) ->
            d = new Date(date)
            _pad = (n) ->
                if n < 10
                    return "0#{ n }"
                return "#{ n }"
            return "#{ d.getFullYear() }-#{ d.getMonth() + 1 }-#{ d.getDate() } #{ d.getHours() }:#{ _pad(d.getMinutes()) }:#{ _pad(d.getSeconds()) }"

        @$el.html """
            <div class="body">
                #{ markdown.toHTML(@model.get('body')) }
            </div>
            <time datetime="#{ @model.get('date') }">#{ _format(@model.get('date')) }</time>
        """
        return @el



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
                focus: (si, val) ->
                    send_message_button.show()
                    _.defer ->
                        new_height = withinRange(si._ui.input[0].scrollHeight, 200, 500)
                        new_message_field.setSize(height: new_height)

                blur: (si, val) ->
                    unless val
                        send_message_button.hide()
                        _.defer -> new_message_field.setSize(height: MESSAGE_PANEL_DEFAULT_SIZE)

            action: (si, value) ->
                if value
                    new_height = withinRange(si._ui.input[0].scrollHeight, 200, 500)
                    _.defer ->
                        send_message_button.enable()
                        new_message_field.setSize(height: new_height)
                else
                    send_message_button.disable()
                    new_message_field.setSize(height: MESSAGE_PANEL_DEFAULT_SIZE)

        send_message_button = new Button
            id: 'send_message_button'
            label: 'Send Message'
            spinner: true
            enabled: false
            action: ->
                new_message_field.disable()
                active_channel.sendNewMessage new_message_field.value, ->
                    console.log 'sent message'
                    send_message_button.disable().hide()
                    new_message_field.setValue('')
                    new_message_field.setSize(height: MESSAGE_PANEL_DEFAULT_SIZE)

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





setUpInterface = ->

    $('#app').html """
        <div id="panel_channels">
            <ul id="channel_messages"></ul>
            <ul id="channel_broadcasts"></ul>
            <ul id="channel_subscriptions"></ul>
        </div>
        <div id="panel_messages">
            <h1 id="channel_title"></h1>
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
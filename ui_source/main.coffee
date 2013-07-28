
# { Layout } = require 'Layout'
{ Layout } = window.Layout
{ View, Model } = window.Backbone

layout = new Layout
    el: $('#app')
    row_first: false
    layout: [
        [200,    [200, 200, 'flex']]
        ['flex', [30, 200, 'flex']]
    ]


class Button extends View
    className: 'Button'
    tagName: 'BUTTON'
    initialize: ({@label}) ->

    render: ->
        @$el.text(@label)
        return @el





class ModelValue extends View
    className: 'ModelValue'
    initialize: ({ @property }) ->
        @listenTo(@model, "change:#{ @property }", @render)
    render: =>
        @$el.html(@model.get(@property))
        return @el



class StringInput extends View
    className: 'StringInput'
    tagName: 'textarea'
    render: => @el
    getValue: => @$el.val()
    setValue: (value) => @$el.val(value)



class Channel extends Model




active_channel = new Channel
    name: 'public-btmessage'

layout.setPanelContent 1,0,
    new ModelValue
        model: active_channel
        property: 'name'


layout.setPanelContent 1,1,
    new StringInput()
    new Button
        label: 'Send Message'



# layout.setPanelContent(1,1, )

setTimeout ->
    active_channel.set('name', 'DJASNDJKASN')
, 1000


layout.render()
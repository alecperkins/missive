
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


class Channel extends Model


layout.render()
layout.setPanelContent(0,0, new Button(label:'Clickity'))
layout.setPanelContent(0,2, new Button(label:'Clickity'))


$window = $(window)

class Panel extends Backbone.View
    className: 'Panel'
    initialize: (@layout) ->
    render: ->
        console.log 'Panel.render'
        return @el

    setLayout: (@layout) ->
        @$el.css
            width: @layout.width
            height: @layout.height
            position: 'absolute'
            left: @layout.left
            top: @layout.top
            background: @layout.background

    setContent: (contents) ->
        @$el.empty()
        _.each contents, (item) =>
            @$el.append(item.render())



class Layout extends Backbone.View
    className: 'Layout'
    initialize: ({@row_first, @layout}) ->
        @panels = []
        @$el.css
            position: 'absolute'
            top: 0
            left: 0
            right: 0
            bottom: 0
            background: 'rgba(240,240,240,0.5)'

        @layout.forEach (col, icol) =>
            col_list = []
            @panels.push(col_list)
            col[1].forEach (row, irow) ->
                col_list.push new Panel()

        $(window).on('resize', _.debounce(@resize, 50))
    render: ->
        console.log 'Layout.render'
        @$el.empty()

        @panels.forEach (col) =>
            col.forEach (panel) =>
                @$el.append(panel.render())

        @resize()



    resize: =>
        console.log 'Layout.resize'
        window_width = $(window).width()
        window_height = $(window).height()
        if not @row_first
            [window_height, window_width] = [window_width, window_height]
        num_flex_rows = 0
        fixed_row_size = 0
        _.each @layout, (row) ->
            if row[0] is 'flex'
                num_flex_rows += 1
            else
                fixed_row_size += row[0]
        h_so_far = 0
        row_flex_size = (window_height - fixed_row_size) / num_flex_rows
        num_panels = 0
        _.each @layout, (row, irow) =>
            [row_height, cols] = row
            h = if row_height is 'flex' then row_flex_size else row_height
            num_flex_cols = 0
            fixed_col_size = 0
            _.each cols, (col) ->
                if col is 'flex'
                    num_flex_cols += 1
                else
                    fixed_col_size += col
            col_flex_size = (window_width - fixed_col_size) / num_flex_cols
            w_so_far = 0
            _.each cols, (col, icol) =>
                w = if col is 'flex' then col_flex_size else col
                num_panels += 1
                if @row_first
                    layout_to_set =
                        left: w_so_far
                        width: w
                        top: h_so_far
                        height: h
                else
                    # Swap the dimensions since it's specified column-first.
                    # (Yes, the labels are now wrong. Deal with it.)
                    layout_to_set =
                        top: w_so_far
                        height: w
                        left: h_so_far
                        width: h
                layout_to_set.background = "rgba(255,0,0,0.#{ num_panels })"
                @panels[irow][icol].setLayout(layout_to_set)
                w_so_far += w
            h_so_far += h

    getPanel: (i, j) ->
        return @panels[i][j]

    setPanelContent: (i, j, contents...) ->
        @panels[i][j].setContent(contents)


# layout = new Layout
#     el: $('#app')
#     row_first: false
#     layout: [
#         [200,    [200, 200, 'flex']]
#         ['flex', [200, 'flex']]
#     ]




# [200, [lt 300, ]]

# col 200,
#     row 100
#     row gt 100
#     row gt 100 lt 200
#     row 1




# module.exports =
window.Layout =
    Layout: Layout
    Panel: Panel

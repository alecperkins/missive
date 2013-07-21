
HTMLElement::_style = (style) ->
    @style[k] = v for k, v of style
    return this
HTMLElement::_text = (text) ->
    @innerText = text
    return this
HTMLElement::_html = (html) ->
    @innerHTML = html
    return this

_elID = (id) -> document.getElementById(id)
_makeEl = (tag_name, kwargs={}) ->
    el = document.createElement(tag_name)
    el.setAttribute(k, v) for k, v of kwargs
    return el




renderMessagesFor = (contact_messages) ->
    messages = []
    for box in ['inbox', 'outbox']
        for m in contact_messages[box]
            messages.push
                date    : new Date(m.date)
                body    : m.body
                box     : box
    messages.sort (a,b) -> b.date - a.date

    els.message_list.innerHTML = ''
    for m in messages
        message_el = _makeEl('li')
        message_el.className = m.box
        date_el = _makeEl('time')
        date_el._text(m.date.toISOString())
        body_el = _makeEl('p')
        body_el._text(m.body)

        message_el.appendChild(date_el)
        message_el.appendChild(body_el)
        els.message_list.appendChild(message_el)



activateContact = (contact) ->
    els.new_message_contact.value = contact
    els.new_message_contact.removeAttribute('disabled')
    els.new_message_body.removeAttribute('disabled')
    els.submit_message.removeAttribute('disabled')
    renderMessagesFor(messages)



els = {}

els.left_panel = _makeEl('div', id: 'left_panel')
els.left_panel._html('<ul id="contact_list"></ul>')
els.right_panel = _makeEl('div', id: 'right_panel')
els.right_panel._html """
    <form id="new_message" method="POST" action="/messages/">
        <input id="new_message_contact" type="text" name="contact" disabled>
        <textarea id="new_message_body" name="body" disabled></textarea>
        <button id="submit_message" disabled>Send</button>
    </form>
    <ol id="message_list" reversed></ol>
"""
document.body.appendChild(els.left_panel)
document.body.appendChild(els.right_panel)
for id in ['contact_list', 'message_list', 'new_message_contact', 'new_message_body', 'submit_message']
    els[id] = _elID(id)

style_el = _makeEl('style')
style_el._html """
#left_panel {
    float: left;
    width: 200px;
}
#right_panel {
    float: right;
    width: calc(100% - 200px);
}
#new_message_contact, #new_message_body {
    display: block;
    width: 100%;
}
#submit_message {
    float: right;
}
#contact_list li {
    cursor      : pointer;
}
#contact_list li:hover {
    background  : rgba(240,240,240,1);
}
#message_list {
    margin-top  : 2em;
}
#message_list li {
    clear       : both;
    padding     : 0.5em 1em;
}
#message_list li.inbox {
    background  : rgba(240,255,240,1);
}
#message_list li.outbox {
    background  : rgba(240,240,255,1);
}
#message_list time {
    float       : right;
    color       : #888;
}
#message_list p {
    margin      : 0;
}
"""
document.body.appendChild(style_el)



for contact, messages of window.DATA
    contact_el = _makeEl('li')
    contact_el._text(contact)
    els.contact_list.appendChild(contact_el)
    contact_el.onclick = ->
        localStorage.setItem('active_contact', contact)
        activateContact(contact)



do ->
    prev_active_contact = localStorage.getItem('active_contact')
    if prev_active_contact
        activateContact(prev_active_contact)



from datetime import datetime
from bottle import get, post, run, template, request, redirect

import codecs
import json
import os


PORT = 8888
HOST = 'localhost'

MESSAGE_FOLDER = os.path.abspath('_messages')
FILENAME_FORMAT = '%Y-%m-%dT%H-%M-%SZ.txt'

if not os.path.exists(MESSAGE_FOLDER):
    os.mkdir(MESSAGE_FOLDER)


@get('/')
def index():
    data = { contact: loadMessagesFor(contact) for contact in discoverContacts() }
    index_file = """
        <body>
            <script>
                window.DATA = {data};
            </script>
            <script>
                {script}
            </script>
        </body>
    """.format(data=json.dumps(data), script=file('ui.js').read())
    return index_file

@post('/messages/')
def newMessage():
    sendMessage(contact=request.forms['contact'], body=request.forms['body'])
    redirect('/')


def discoverContacts():
    contacts = []
    for item in os.listdir(MESSAGE_FOLDER):
        if os.path.isdir(os.path.join(MESSAGE_FOLDER, item)) and item[0] != '.':
            contacts.append(item)
    return contacts

def loadMessagesFor(contact):
    def load(box):
        messages = []
        box_folder = os.path.join(MESSAGE_FOLDER, contact, box)
        for item in os.listdir(box_folder):
            full_path = os.path.join(box_folder, item)
            if os.path.isfile(full_path) and item[0] != '.':
                print full_path
                with codecs.open(full_path, 'r', 'utf-8') as message_file:
                    messages.append({
                            'date': datetime.strptime(item, FILENAME_FORMAT).strftime('%Y-%m-%dT%H:%M:%SZ'),
                            'body': message_file.read(),
                        })
        return messages
    all_messages = {
        'inbox': load('inbox'),
        'outbox': load('outbox'),
    }

    return all_messages

def sendMessage(body='', contact=''):
    print contact
    print body
    target_outbox = os.path.join(MESSAGE_FOLDER, contact, 'outbox')
    now = datetime.utcnow()
    target_file = now.strftime(FILENAME_FORMAT)
    with codecs.open(os.path.join(target_outbox, target_file), 'w', 'utf-8') as f:
        f.write(body)
    return


run(host=HOST, port=PORT, debug=True, reloader=True)

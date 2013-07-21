# BitMessage

A basic proof-of-concept of [BitTorrent Sync](http://labs.bittorrent.com/experiments/sync.html)-backed, secure messaging. Pull model, for now. Each user exchanges a read-only secret to an outbox. (A more public, write-only folder isn't possible, yet.)

## Setup

0. Install [BitTorrent Sync](http://labs.bittorrent.com/experiments/sync.html).
1. Create a base folder to store the message data: `~/BTSync/bitmessage/`.
2. Create a folder for a contact: `~/BTSync/bitmessage/<contact>`.
3. Inside the contact folder, create an inbox and an outbox:
    
        `~/BTSync/bitmessage/<contact>/inbox`
        `~/BTSync/bitmessage/<contact>/outbox`

4. In BitTorrent Sync, add the contact outbox and give your contact the read-only secret.
5. Add your contact inbox to BT Sync, using the read-only secret your contact gives you.
6. Start the app: `$ python app.py` and visit `[localhost:8888](http://localhost:8888)`.

(A lot of steps, many which will hopefully be unnecessary when the [BitTorrent Sync API](http://forum.bittorrent.com/topic/18176-sync-api-wishlist/) is available.)

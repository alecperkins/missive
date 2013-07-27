# BTMessage

A basic proof-of-concept of [BitTorrent Sync](http://labs.bittorrent.com/experiments/sync.html)-backed, secure messaging. Pull model, for now. Each user exchanges a read-only secret to an outbox. (A more public, write-only folder isn't possible, yet.)

## Setup

0. Install [BitTorrent Sync](http://labs.bittorrent.com/experiments/sync.html).
1. Create a base folder to store the message data: `btmessage/_messages`.
2. Create a folder for a contact: `btmessage/_messages/<contact>`.
3. Inside the contact folder, create an inbox and an outbox:
    
        `btmessage/_messages/<contact>/inbox`
        `btmessage/_messages/<contact>/outbox`

4. In BitTorrent Sync, add the contact outbox and give your contact the read-only secret.
5. Add your contact inbox to BT Sync, using the read-only secret your contact gives you.
6. Start the app: `$ python app.py` and visit [`localhost:8888`](http://localhost:8888).

(A lot of steps, many which will hopefully be unnecessary when the [BitTorrent Sync API](http://forum.bittorrent.com/topic/18176-sync-api-wishlist/) is available.)

## As channels

Since the process involves exchanging read-only keys with potentially asymmetric relationships, this could also be used for one-to-many messages (blogging, microblogging). Really, each "contact" is just a pair of dedicated one-way channels. Adding a contact that has only an outbox, then publicizing the read-only key, would be creating an outgoing channel to any number of readers. The readers subscribe to that channel by adding a contact with only an inbox. What's doubly neat is that read-only peers still exchange data (presumably unless they change their copy). This means the distributed benefit of BitTorrent is still in effect, and the originator of the message need not be online all the time for the message to spread to new subscribers. There is also no central point of failure — at least for messages that have already been sent. Also, multiple trusted users could contribute to the same channel by sharing the master key for the outbox.

Try it out by creating a `btmessage/_messages/public-btmessage/inbox` folder and adding it to BT Sync with the key `B2CNYVXULNUVYH42J5DN6YTHJT6ESXOR3`. For now, the UI just color codes the contacts differently, depending on the presence of an inbox and/or outbox. A proper UI would better differentiate between the types.
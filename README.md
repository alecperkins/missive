# Missive

A basic proof-of-concept of [BitTorrent Sync](http://labs.bittorrent.com/experiments/sync.html)-backed, distributed, secure messaging. Pull model, for now. Each user exchanges a read-only secret to an outbox. (A more public, write-only folder isn't possible, yet.)

## Mechanism

Each contact — *message channel* — gets a folder that contains and inbox folder and an outbox folder. The user adds the outbox for the contact to BT Sync as a master folder, and gives the recipient the read-only key. The other party then gives the user a read-only key for their outbox, which the user uses to add the channel inbox to BT Sync. It can also be used in a one-to-many capacity, through a *broadcast channel*, simply by sharing the read-only key to an outbox more widely. Likewise, users create *subscription channels* (the other end of the *broadcast* ones), by adding only an inbox to the channel’s folder.

The actual messages are exchanged via a single plain text file per message, with the filename an ISO-like timestamp (adjusted to allow for OS filename character restrictions). Attachments MAY be added to the message by creating a folder with the same timestamp, and placing arbitrary files inside it. So, the file `2013-08-11T14-34-37Z.txt` contains the message, and the folder `2013-08-11T14-34-37Z/` contains related attachments.

### One-to-one messaging


    Azureen                              Brando
      brando/                              azureen/
        inbox/    <-------READ ONLY-------   outbox/
        outbox/   --------READ ONLY------>   inbox/


### One-to-many messaging


                                       Brando
                                         azureens-blog/
    Azureen                  +--------->   inbox/
      azureens-blog/         |
        outbox/   -READ ONLY-+
                             |         Cooper
                             |           azureens-blog/
                             +--------->   inbox/
                             |
                             |
                             |         Delilah
                             |           azureens-blog/
                             +--------->   inbox/


Because of the way BitTorrent works, Brando, Cooper, and Delilah will also exchange pieces of the message from Azureen with each other. If Brando in online and has already received a complete copy of the message, Cooper and Delilah will still receive the message even if Azureen is not online. However, since their access is read-only, any changes they make to their copy will not be propagated to the swarm.



## Installation

This mechanism doesn’t actually require any software beyond BT Sync, just a text editor to create flat text files in folders. This project just provides a helpful interface for the process.

### Requires

(And assumed familiarity with)

* [BitTorrent Sync](http://labs.bittorrent.com/experiments/sync.html).
* [node.js](http://nodejs.org/)

### Setup

1. Clone the repo to wherever you like: `$ git clone git@github.com:alecperkins/missive.git`
2. Install the dependencies: `$ npm install`
3. Create a base folder to store the message data (hardcoded to this for now, sorry): `~/missive_data`.
4. Start the app: `$ node server/main.js` and visit [`localhost:3000`](http://localhost:3000).

### Usage

Obviously, Missive is only useful if there are channels set up. To add a *message*-type channel:

1. Create a folder for a contact: `~/missive_data/<contact>`.
2. Inside the contact folder, create an inbox and an outbox:
    
        `~/missive_data/<contact>/inbox`
        `~/missive_data/<contact>/outbox`

3. In BitTorrent Sync, add the contact outbox and give your contact the read-only secret.
4. Add your contact inbox to BT Sync, using the read-only secret your contact gives you.

To add a *broadcast* or *subscription* channel, simply omit the inbox or outbox, respectively. A lot of steps, unfortunately. Proper packaging will obviate the setup, and hopefully the pending [BitTorrent Sync API](http://forum.bittorrent.com/topic/18176-sync-api-wishlist/) will take care of the usage steps, which can be automated.

*Note: channel names MUST be URL-friendly (for now).*


## As one-way channels

Since the process involves exchanging read-only keys with potentially asymmetric relationships, this could also be used for one-to-many messages (blogging, microblogging). Really, each contact is just a channel with an input and an output. Adding a channel that has only an outbox, then publicizing the read-only key, would be creating an outgoing channel to any number of readers. The readers subscribe to that channel by adding a contact with only an inbox. What's doubly neat is that read-only peers still exchange data (presumably unless they change their copy). This means the distributed benefit of BitTorrent is still in effect, and the originator of the message need not be online all the time for the message to spread to new subscribers. There is also no central point of failure — at least for messages that have already been sent. Also, multiple trusted users could contribute to the same channel by sharing the master key for the outbox.

Try it out by creating a `~/missive_data/public-missive/inbox` folder and adding it to BT Sync with the key `B2CNYVXULNUVYH42J5DN6YTHJT6ESXOR3`. Or, create a `~/missive_data/my-posts/outbox` folder, add it to BT Sync, and share the read-only key.

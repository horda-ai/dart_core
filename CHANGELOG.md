## 0.14.0

 - **FEAT**: add entityName to QueryDef and QueryDefBuilder.
 - **FEAT**: add entityName and subKey to ActorViewSub.
 - **FEAT**: add entityName to ChangeEnvelop.

## 0.13.2

 - **FIX**: fix ValueViewChanged not being matched when registering factory

## 0.13.1

 - **DOCS**: readme file
 - **DOCS**: doc comments for all public classes

## 0.13.0

 - **BREAKING CHANGE**: rename public API
 - **CHORE**: remove dead code

## 0.12.18

 - **FEAT**: service type.

## 0.12.17+1

 - **FIX**: fix ValueViewChanged fromJson.

## 0.12.17

 - **FEAT**: scale http server.

## 0.12.16

 - **FEAT**: remove flow subs.

## 0.12.15

 - **FEAT**: sync actor start.

## 0.12.14

 - **FIX**: watcher callback is called on unmounted element.
 - **FIX**: fixes for prod host.
 - **FIX**: honor query subscribe value.
 - **FEAT**: update RPC messages to improve server logs.
 - **FEAT**: update fluir client to fluir 2.
 - **FEAT**: pulsar actor client call reply.
 - **FEAT**: fluir client v2.
 - **FEAT**: pulsar client triggered flows.
 - **FEAT**: change v2.
 - **FEAT**: pulsar flow context.
 - **FEAT**: pulsar actor context.
 - **FEAT**: pulsar flow host.
 - **FEAT**: redis view store.
 - **FEAT**: implement unsubscribe actor functionality.
 - **FEAT**: view cache.

## 0.12.13

 - **FEAT**: update RPC messages to improve server logs.

## 0.12.12

 - **FEAT**: update fluir client to fluir 2.

## 0.12.11+1

 - **FIX**: fixes for prod host.

## 0.12.11

 - **FEAT**: pulsar actor client call reply.

## 0.12.10

 - **FEAT**: fluir client v2.

## 0.12.9

 - **FEAT**: pulsar client triggered flows.

## 0.12.8

 - **FEAT**: change v2.

## 0.12.7

 - **FEAT**: pulsar flow context.

## 0.12.6

 - **FEAT**: pulsar actor context.

## 0.12.5

 - **FEAT**: pulsar flow host.

## 0.12.4

 - **FEAT**: redis view store.

## 0.12.3

 - **FIX**: honor query subscribe value.
 - **FEAT**: implement unsubscribe actor functionality.
 - **FEAT**: view cache.

## 0.12.2

 - **FEAT**: implement unsubscribe actor functionality.

## 0.12.1+1

 - **FIX**: honor query subscribe value.

## 0.12.1

 - **FEAT**: view cache.

## 0.12.0

- renamed public type ListViewItemAttr to RefIdNamePair

## 0.11.0

- added ListView.addItemIfAbsent()

## 0.10.0

- added empty change envelops
- reworked SubscribeViews<u>Res</u>WsMsg into SubscribeViews<u>Ack</u>WsMsg

## 0.9.0

- added change types to support attributes

## 0.8.0

- added FlowResult to be returned by Flow handlers
- rename eventFrom of FlowContext to senderId

## 0.7.0

- refactored messages into remote and local messages
- removed SingletonCommand

## 0.6.0

- refactored view related Events into Changes
- added ChangeRecord and ChangeEnvelop

## 0.5.0

- move non-core code to other packages

## 0.4.0

- added reconnect() method to FluirSystem class

## 0.3.0

- added senderId to ActorContext

## 0.2.0

- added subscribeActor to client flow
- callAfter must be used by client flow only
- fix FluirError json serialization error
- use new Logger for actor logging

## 0.1.2

- added license
- added package publish ci job

## 0.1.1

- fixed fluir_client dependency resolution error

## 0.1.0

- initial release
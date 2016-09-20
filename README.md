# A GroupMe Client in Swift

This is a simple POC GroupMe iOS client writne in Swift and talking to the public GroupMe API. It uses Oauth to authenticate against your existing GroupMe account.

## Building

The client depends on Alamofire, SwiftyJSON, WebImage, and SocketRocket. To get the dependencies cd into the project root and

```
carthage update
```

This is very much a WIP. You will be able to see your frequent groups and send and receive text messages but not much else.
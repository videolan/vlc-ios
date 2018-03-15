This is a fork for use within VLC for iOS, since the original project is no longer maintained.

Patches from third parties will be happily merged!

------
# CocoaHTTPServer

[![Build Status](https://travis-ci.org/robbiehanson/CocoaHTTPServer.svg)](https://travis-ci.org/robbiehanson/CocoaHTTPServer)
 [![Version](http://img.shields.io/cocoapods/v/CocoaHTTPServer.svg?style=flat)](http://cocoapods.org/?q=CocoaHTTPServer)
 [![Platform](http://img.shields.io/cocoapods/p/CocoaHTTPServer.svg?style=flat)]()
 [![License](http://img.shields.io/cocoapods/l/CocoaHTTPServer.svg?style=flat)](https://github.com/robbiehanson/CocoaHTTPServer/blob/master/LICENSE)

CocoaHTTPServer is a small, lightweight, embeddable HTTP server for Mac OS X or iOS applications.

Sometimes developers need an embedded HTTP server in their app. Perhaps it's a server application with remote monitoring. Or perhaps it's a desktop application using HTTP for the communication backend. Or perhaps it's an iOS app providing over-the-air access to documents. Whatever your reason, CocoaHTTPServer can get the job done. It provides:

-   Built in support for bonjour broadcasting
-   IPv4 and IPv6 support
-   Asynchronous networking using GCD and standard sockets
-   Password protection support
-   SSL/TLS encryption support
-   Extremely FAST and memory efficient
-   Extremely scalable (built entirely upon GCD)
-   Heavily commented code
-   Very easily extensible
-   WebDAV is supported too!

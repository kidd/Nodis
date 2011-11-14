Smalltalk current createPackage: 'Nodis' properties: #{}!
Object subclass: #NServer
	instanceVariableNames: 'http url router'
	category: 'Nodis'!

!NServer methodsFor: 'not yet classified'!

initialize
	http := require value: 'http'.
	url := require value: 'url'.
!

runDefault
	console log: 'listening at port', 1800 ,String cr.
	(http createServer:[ :request :response | 
					 	console log: request method, ' ', request url.
						request setEncoding: 'utf8'.]) listen: 1800
!

runOnPort: aPort withRoutes: aNRouter
	console log: 'listening at port', aPort ,String cr.
	(http createServer:[ :request :response | 
					 	console log: request method, ' ', request url.
						request setEncoding: 'utf8'.
						(router routeForMethod: request method on: (url parse: request url) following: aNRouter)  value: request returning: response]) listen: aPort
!

runOnPort: aPort
	console log: 'listening at port', aPort ,String cr.
	(http createServer:[ :request :response |
					 	console log: request method, ' ', request url.
						request setEncoding: 'utf8'.
						console log: request url class.
						 "NRedisHandler new manage: request returning: response ."
						(TestHandler with:request returning: response) manage. ]) 
		listen: aPort
! !

!NServer class methodsFor: 'not yet classified'!

main
	^self new runOnPort: 1892
! !

Object subclass: #TestHandler
	instanceVariableNames: 'querystring redis request response'
	category: 'Nodis'!

!TestHandler methodsFor: 'not yet classified'!

handle: request
	console log: request url
!

initialize
	"super initialize."
	querystring := require value: 'querystring'.
	redis := (require value: 'redis') createClient.
!

notFound
	self response writeHead: 404.
	self response end.
!

notFound: response
	response writeHead: 404.
	 response end.
!

request: aRequest
	request := aRequest
!

response: aResponse	
	response := aResponse
!

manage
	|regex regexResult routes methodDict |
	routes := #{ 'GET' -> #{  '^/([^/]+)/?$' -> [:rresult |self collectionOf: (rresult at:2)  ].
						   '^/([^/]+)/(\d+)/?$' -> [:rresult | self memberOf: (rresult at: 2) index: (rresult at: 3)]
						} .
				'POST'  -> #{
							} }.
	console log: 'managing a request'.
	console log: 'response is a', self request url .

	methodDict := (routes at: (self request method)) .

	methodDict keys do: [:x || matches |
						 matches := (RegularExpression fromString:x) test: self request url .
						console log: matches.
						matches ifTrue:[( methodDict at: x) value:  ((RegularExpression fromString:x) exec: self request url)].
						].
!

request
	^request
!

response
	^response
!

collectionOf: aModel
	console log: 'collection of ',aModel.
	redis lrange:aModel from:0 to: -1 eachDo: [:error :val | 
										console log: 'value is ', val.
										console log: error.
										(val isKindOf: Array)
										ifTrue: [self responseOkWithVal: ('[',val,']') ]
										ifFalse: [self notFound] 
 ].
!

memberOf: aModel index:index
	console log: 'member of ',aModel, 'index: ' , index.
	redis lindex:aModel index: index eachDo: [:error :val | 
										console log: 'value is ', val.
										console log: error.
										(val isNil not)
										ifTrue: [self responseOkWithVal: val ]
										ifFalse: [self notFound] 
 ].
!

responseOk
	self response writeHead:200 
	withContent: #{'Content-Type' -> 'application/json; charset=utf-8'} .
!

responseOkWithVal: val 
	self responseOk.
	 self response end: val encoding: 'utf8'
! !

!TestHandler class methodsFor: 'not yet classified'!

with: aRequest returning: aResponse
	|t|
	t := self new.
	t request: aRequest.
	t response: aResponse.
	^t.
! !


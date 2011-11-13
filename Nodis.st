Smalltalk current createPackage: 'Nodis' properties: #{}!
Object subclass: #NServer
	instanceVariableNames: 'http url router'
	category: 'Nodis'!

!NServer methodsFor: 'not yet classified'!

initialize
	http := require value: 'http'.
	url := require value: 'url'.
	router := NHandlerRouter new.
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
	|a|
	console log: 'listening at port', aPort ,String cr.
	a := (router routeForMethod: 'GET' on: 'hola') new.
	
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

Object subclass: #NHandler
	instanceVariableNames: 'request response'
	category: 'Nodis'!

!NHandler methodsFor: 'not yet classified'!

request
	^request
!

request: aRequest
	request := aRequest
!

response
	^ response
!

response: aResponse
	response := aResponse
!

notFound
	self response writeHead: 404.
	self response end.
! !

!NHandler class methodsFor: 'not yet classified'!

request: aRequest response: aResponse
	"Create a new Handler instance with a request and response objects"
	|handler|
	handler := self new.
	handler request: aRequest.
	handler response: aResponse.
	^ handler
! !

Object subclass: #NApp
	instanceVariableNames: ''
	category: 'Nodis'!

Object subclass: #NRouter
	instanceVariableNames: ''
	category: 'Nodis'!

!NRouter methodsFor: 'not yet classified'!

routeForMethod: aMethod on: aPath following: aRoutes
	"aNRouter migth be a hash"
	^(aRoutes routes at: aMethod) detect: [:re| <new RegExp(re).test(aPath)>]
					  	    ifNone: [ aRoutes defaultRoute].
!

routeForMethod: aMethod on: aPath
	"returns the method to call for a given method and path"
	|dict|
	dict := #{  'GET' -> [self get: aPath].
			'POST' -> [self post: aPath].
			'PUT' -> [ self put: aPath]}.

	^ (dict at: aMethod) value .

"detect: [:re| <new RegExp(re).test(aPath)>]
					  	    ifNone: [ self defaultRoute]."
!

defaultRoute
	console log: 'Default handler'.
	response writeHead: 404.
	response end.
! !

Object subclass: #Nodis
	instanceVariableNames: ''
	category: 'Nodis'!

!Nodis class methodsFor: 'not yet classified'!

run
	console log: 'fpo;'
!

main
	console log: 'fpo;'
! !

NRouter subclass: #NDefaultRouter
	instanceVariableNames: ''
	category: 'Nodis'!

!NDefaultRouter methodsFor: 'not yet classified'!

get: aPath
!

post: aPath
!

put: aPath
! !

NRouter subclass: #NHandlerRouter
	instanceVariableNames: 'mapper'
	category: 'Nodis'!

!NHandlerRouter methodsFor: 'not yet classified'!

routeRequest: aRequest
	|a b c url|	
	url := aRequest url.
	true ifTrue:[^NRedisHandler]
!

routeForMethod: aMethod on: anUrl
	|a b c url|	
	true ifTrue:[^NRedisHandler]
!

initialize
	super initialize.
	mapper := #{ 'regex1' -> ''  }
! !

NHandler subclass: #NRedisHandler
	instanceVariableNames: 'querystring redis methodHash'
	category: 'Nodis'!

!NRedisHandler methodsFor: 'not yet classified'!

manage: request returning: response
	|regex regexResult meth|
	console log: 'managing a request'.
	console log: 'response is a', request url .
	regex := RegularExpression fromString: '^/([^/]*)/?$'.
	regexResult := (regex exec: request url). 
	regexResult isNil ifFalse:[self collectionOf: (regexResult at:2) ]
				ifTrue: [self notFound]
!

initialize
	"super initialize."
	querystring := require value: 'querystring'.
	redis := (require value: 'redis') createClient.
!

collectionOf: aModel 
	console log: 'collection of',aModel.
	redis lrange:aModel from:0 to: -1 eachDo: [:error :val | 
										console log: val.
										console log: error.
										val isKindOf: Array
										ifTrue: [self responseOkWitVal: val asJSON]
										ifFalse: [self notFound] 
 ].
!

responseOk
	response writehead:200
	withContent: #{'Content-Type' -> 'application/json; charset=utf-8'} .
!

responseOkWithVal: val
	self responseOk.
	self response end: val asJSON encoding: 'utf8'
!

memberOf: aModel withId: aNumber
	self redis lindex: aModel 
			at: aNumber 
			do: [:err :val |
				val size >0
					ifTrue: [self responseOkWithVal: val asJSON]
					ifFalse: [self notFound]]
!

handle: request
	console log: request url
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

manage: request returning: response
	|regex regexResult routes methodDict |
	routes := #{ 'GET' -> #{  '^/([^/]+)/?$' -> [:rresult |self collectionOf: (rresult at:2) responseAt: response ].
						   '^/([^/]+)/(\d+)/?$' -> [:rresult | self memberOf: (rresult at: 2) index: (rresult at: 3) responseAt: response]
						} .
				'POST'  -> #{
							} }.
	console log: 'managing a request'.
	console log: 'response is a', request url .

	methodDict := (routes at: (request method)) .

	methodDict keys do: [:x || matches |
						 matches := (RegularExpression fromString:x) test: request url .
						console log: matches.
						matches ifTrue:[( methodDict at: x) value:  ((RegularExpression fromString:x) exec: request url)].
						].
!

notFound
	self response writeHead: 404.
	self response end.
!

collectionOf: aModel responseAt: response
	console log: 'collection of ',aModel.
	redis lrange:aModel from:0 to: -1 eachDo: [:error :val | 
										console log: 'value is ', val.
										console log: error.
										(val isKindOf: Array)
										ifTrue: [self responseOkWithVal: ('[',val,']') responseAt: response]
										ifFalse: [self notFound: response] 
 ].
!

responseOkWithVal: val responseAt: response
	self responseOk: response.
	 response end: val encoding: 'utf8'
!

responseOk: response
	response writeHead:200 
	withContent: #{'Content-Type' -> 'application/json; charset=utf-8'} .
!

notFound: response
	response writeHead: 404.
	 response end.
!

memberOf: aModel index:index responseAt: response
	console log: 'member of ',aModel, 'index: ' , index.
	redis lindex:aModel index: index eachDo: [:error :val | 
										console log: 'value is ', val.
										console log: error.
										(val isNil not)
										ifTrue: [self responseOkWithVal: val responseAt: response]
										ifFalse: [self notFound: response] 
 ].
!

request: aRequest
	request := aRequest
!

response: aResponse	
	response := aResponse
!

manage
	|regex regexResult routes methodDict |
	routes := #{ 'GET' -> #{  '^/([^/]+)/?$' -> [:rresult |self collectionOf: (rresult at:2) responseAt: self response ].
						   '^/([^/]+)/(\d+)/?$' -> [:rresult | self memberOf: (rresult at: 2) index: (rresult at: 3) responseAt: self response]
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
! !

!TestHandler class methodsFor: 'not yet classified'!

with: aRequest returning: aResponse
	|t|
	t := self new.
	t request: aRequest.
	t response: aResponse.
	^t.
! !


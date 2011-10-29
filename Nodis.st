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
	console log: 'listening at port', aPort ,String cr.
	(http createServer:[ :request :response | 
					 	console log: request method, ' ', request url.
						request setEncoding: 'utf8'.
						(router routeForMethod: request method on: (url parse: request url)) new manage: request returning: response]) 
		listen: aPort
! !

!NServer class methodsFor: 'not yet classified'!

main
	^self new runOnPort: 1892
! !

Object subclass: #NHandler
	instanceVariableNames: ''
	category: 'Nodis'!

!NHandler methodsFor: 'not yet classified'!

notFound: aResponse
	aResponse writeHead: 404.
	aResponse end.
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
!

get: aPath
	self subclassResponsability
!

post: aPath
	self subclassResponsability
!

put: aPath
	self subclassResponsability
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
	instanceVariableNames: ''
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
! !

NHandler subclass: #NRedisHandler
	instanceVariableNames: 'querystring redis methodHash'
	category: 'Nodis'!

!NRedisHandler methodsFor: 'not yet classified'!

manage: request returning: response
	|regex regexResult meth|
	console log: 'managing a request'.
	meth := methodHash detect: [:k :v | (RegularExpression fromString: k) test: request url] 
	self perform: meth value.
	
	regex := RegularExpression fromString: '^/([^/]*)/?$'.
	regexResult := (regex exec: request url). 
	regexResult isNil ifFalse:[self collectionOf: (regexResult at:2)
							requestedOn: request
							andReturnedIn: response  ]
				ifTrue: [self notFound: response]
!

collection: aModel
	^ 'foo' asJSON
!

collectionOf: aModel requestedOn: aRequest andReturnedIn: aResponse 
	console log: 'collection of',aModel.
	redis lrange:aModel from:0 to: -1 eachDo: [:error :val | 
										console log: val.
										console log: error.
										val isKindOf: Array
										ifTrue: [aResponse writehead:200
											     withContent: #{'Content-Type' -> 'application/json; charset=utf-8'} .
											      aResponse end: val asJSON encoding: 'utf8']
										ifFalse: [self notFound: aResponse] 
 ].
!

initialize
	super initialize.
	querystring := require value: 'querystring'.
	redis := (require value: 'redis') createClient.
	methodHash := #{ '^/([^/]*)/?$' -> 'collectionOf:requestedOn:andReturnedIn:'}.
! !


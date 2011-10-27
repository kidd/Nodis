Smalltalk current createPackage: 'Nodis' properties: #{}!
Object subclass: #NServer
	instanceVariableNames: 'http url route'
	category: 'Nodis'!

!NServer methodsFor: 'not yet classified'!

initialize
	http := require value: 'http'.
	url := require value: 'url'.
	route := NRouter new.
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
						(route routeForMethod: request method on: (url parse: request url) following: aNRouter)  value: request returning: response]) listen: aPort
! !

!NServer class methodsFor: 'not yet classified'!

main
	^self new runOnPort: 1892 withRoutes: Routes new
! !

Object subclass: #NHandler
	instanceVariableNames: ''
	category: 'Nodis'!

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
! !

Object subclass: #Routes
	instanceVariableNames: 'routes'
	category: 'Nodis'!

!Routes methodsFor: 'not yet classified'!

initialize
	super initialize.
	routes := Dictionary new.
	routes at: 'GET' put: (Dictionary new at: '/libros' put: self libros).
!

libros
	console log: 'libros route'.
	^ 'hola'
!

defaultRoute
	console log: 'default route'.
	^'default'
!

routes
	^routes
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


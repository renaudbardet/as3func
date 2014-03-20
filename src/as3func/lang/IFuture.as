package as3func.lang
{
	
	/** 
	 * @author renaudbardet
	 * 
	 * A Future is a utility class that brings functional style programing features
	 * 
	 * ------ use case :
	 * // initiating an asynchronous process
	 * var f = new Future();
	 * 
	 * // referencing a callback
	 * f.onSuccess( myFunction );
	 * 
	 * // end of the process
	 * f.dispatch( myResult );
	 * 
	 * // the result will be cached so that if you reference another callback after the result is
	 * // obtained the callback will be seamlessly called with the result
	 * 
	 * examples :
	 * ----- animation
	 * 
	 * 		var animationDone:Future = new Future();
	 * 		var myClip:MovieClip = new MyClip();
	 * 		myClip.addEventListener( Event.ENTER_FRAME, function(e:Event):void { if(myClip.currentFrame == 10) f.complete() } );
	 * 		myClip.play();
	 * 		animationDone.onSuccess( // do something, like relaunch another animation );
	 * 
	 * ----- server calls
	 * 
	 * 		function callServer():Future
	 * 		{
	 * 			var serverResponded:Future = new Future();
	 * 			var myRequest:ServerRequest = new ServerRequest();
	 * 			myRequest.addEventListener( ServerEvent.RESPONSE, function(e:ServerEvent) { serverResponded.complete( e.data ); } );
	 * 			return serverResponded;
	 * 		}
	 * 
	 * usage
	 * 		var myServerData:Future = callServer();
	 * 		myServerData.onSuccess( treatServerData );
	 * 
	 * handling Errors
	 * future handles natively the error process, because so many things could go wrong once you go asynchronous
	 * 		myServerData.onError( treatError );
	 * 
	 * handling custom error
	 * 		myServerData.onResult( treatResponseOrError );
	 * 
	 * ----- filtering, combining, mapping
	 * 
	 * 		function createFoo( json:String ):String {
	 * 			return new Foo( JSON.decode( json ) );
	 * 		} 
	 * 		var myFoo:Future = callServer().map( createJibbidyBoo );
	 * 
	 * this can be used to refine errors as well
	 * 		
	 * 		function handleJsonError( result:Either ):Either {
	 * 			
	 * 			if ( result.isLeft() )
	 * 				return result;
	 * 			
	 * 			var data = JSON.decode( result.getRight() );
	 * 			if ( data.error )
	 * 				return Either.Left( data.error ); // convert valid result into an error result
	 * 			else
	 * 				return Either.Right( data ); // return the decoded JSON
	 * 			
	 * 		}
	 * 		var myRes = callServer.mapResult( handleJsonError );
	 * 
	 */
	public interface IFuture
	{
		
		/**
		 * @return	true if data or error has been received, false otherwise
		 */
		function get isComplete() : Boolean;
		
		/**
		 * @param f		a function to be called when the future is reached
		 * 				can be of type function(data):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		function onSuccess( f:Function ):IFuture;
		
		/**
		 * @param f		a function to be called when the future fails
		 * 				can be of type function(error):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		function onError( f:Function ):IFuture;
		
		/**
		 * @param f		a function to be called when data or error is received
		 * 				can be of type function(Either):void or function():void
		 * @return 		this instance (builder pattern)
		 */
		function onResult( f:Function ):IFuture;
		
		/**
		 * converts the resulting data of a Future throught a mapping function following the pattern
		 * 
		 * this					X - - - - -> A
		 * this.map(mapper)		X - - - - -> B
		 * 
		 * @param mapper	a function of type function( data:A ):B or function():B
		 * 					where A is the type returned by this Future and B the type you want to get
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(data) rather than data itself
		 * 
		 */
		function map( mapper:Function ):IFuture;
		
		/**
		 * idem map but surrounded with try catch and if an error occurs we fail with the Error as content
		 */
		function mapTry( mapper:Function ):IFuture;
		
		/**
		 * 
		 * same as map but expects the mapper function to take the Either result rather than the data ( sim. to onResult comp. to onSuccess )
		 *  
		 * @param mapper	a function of type function( res:Either<A,error> ):Either<B,error> or function():Either<B,error>
		 * 					where A is the data expected in this Future and B the data you want, error is of any kind
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(result)
		 * 
		 */
		function mapResult( mapper:Function ) : IFuture;
		
		/**
		 * onSucess we process the data throught a mapper function that converts the result to an Either
		 * this is the same as using mapResult althought you don't need to care about the case were the result is already faulty
		 *  
		 * @param mapper	a function of type function( data:A ):Either<B,error> or function():Either<B,error>
		 * 					where A is the data expected in this Future and B the data you want, error is of any kind
		 * 
		 * @return 			a new Future that will be completed when this Future is completed but with the return of mapper(result)
		 * 
		 */
		function refine( mapper:Function ) : IFuture;
		
		/** 
		 * allows for joint asynchronous call patterns like
		 * 
		 * 	this			X - - - - -> A
		 * 	f2				X - - - - - - -> B
		 * 	f1.join(f2)		X - - - - - - -> (A,B)
		 * 
		 * @param f2	another Future completed or not
		 * @return 		a Future that will be completed on
		 * 
		 */
		function join( f2 : IFuture ) : IFuture;
		
		/**
		 * return a Future that will be completed by either this Future or f2, depending on wich is completed first
		 * and that will fail only if both fail
		 * 
		 * @param f2	a Future
		 * @return 		a new Future
		 * 
		 */
		function or( f2:IFuture ):IFuture;
		
		/**
		 * fail this Future if f2 is complete first
		 * the error result will be the data result of f2
		 * 
		 * this produces the two following scenarios :
		 * 
		 * this					X - - - -> A
		 * f2					X - - -> B
		 * this.unless( f2 )	X - - -> Error(B)
		 * 
		 * or
		 * 
		 * this					X - - -> A
		 * f2					X - - - - -> B
		 * this.unless( f2 )	X - - -> A
		 * 
		 * @param f2	a Future
		 * @return 		a new Future
		 * 
		 */
		function unless( f2:IFuture ) : IFuture;
		
		/**
		 * creates a copy of this Future that will be triggered at the same time with the same result (data or error)
		 * @return 	a new Future
		 * 
		 */
		function copy() : IFuture;
		
		/**
		 * 
		 * this chaining function allows for patterns like
		 * 
		 * 		X - - - - -> A -> X - - - - -> B
		 * 		X - - - - - - - - - - - - - -> B
		 * 
		 * for example play( "anim1" ).chain( F.callback( play, "anim2" ) )
		 * will wait for anim1 to complete then play anim2
		 * the Future returned by this expression will be completed once anim2 is done
		 * 
		 * @param func	a function of type function( data:* ):Future or function():Future
		 * 				where result is the data resulting of this Future's completion
		 * 				func will be called once this future is completed
		 * @return 		a Future that will be completed once both this Future and the Future returned by func are completed
		 * 
		 */
		function chain( func:Function ):IFuture;
		
		/**
		 * This is the same as chain but the passed function should use the Either result rather than the data ( sim. to onResult comp. to onSuccess )
		 * @param func	a function of type function( result:Either ):Future or function():Future
		 * 				where result is result in this Future upon result completion
		 * @return 		a Future that will be completed this Future then func's returned Future are completed
		 */
		function chainResult( func:Function ):IFuture;
		
		function traceResult(flag:String):IFuture;
		
	}
	
}

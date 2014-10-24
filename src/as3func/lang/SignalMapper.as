package as3func.lang
{
	import flash.utils.Dictionary;

	public class SignalMapper implements ISignal
	{
		
		private var _s:ISignal;
		private var _f:Function;
		
		private var listeners:Dictionary;
		
		private var _filter:Boolean;
		
		public function SignalMapper( s:ISignal, f:Function, filter:Boolean = false )
		{
			this._s = s;
			this._f = f;
			this._filter = filter;
			listeners = new Dictionary();
		}
		
		public function add( listener:Function, once:Boolean=false ):void
		{
			
			var innerListener:Function;
			if( listeners[listener] != null )
				innerListener = listeners[listener]; 
			else{
				if( _filter ) {
					innerListener = function( e:* ):void{
						var mapped:Either = _f(e);
						if( mapped.isRight() )
							listener( mapped.getRight() );
						else if (once) // restore the listener for next dispatch
							_s.add( listeners[listener], true )
					};
				}
				else {
					innerListener = function( e:* ):void {
						listener( _f(e) );
					};
				}
				listeners[listener] = innerListener;
			}
			_s.add( innerListener, once );
			
		}
		
		public function map( mapper:Function ):ISignal
		{
			return new SignalMapper( this, mapper );
		}
		
		public function filter( mapper:Function ):ISignal
		{
			return new SignalMapper( this, mapper, true );
		}
		
		public function nextDispatch():IFuture { return Future.nextSignal( this ); }
		
		public function remove( listener:Function ):Boolean
		{
			
			if( listeners[listener] == null )
				return false;
			var innerListener:Function = listeners[listener]; 
			_s.remove( innerListener );
			if( !_s.hasListener( innerListener ) )
				delete listeners[listener];
			return true;
			
		}
		
		public function hasListener( listener:Function ):Boolean
		{
			
			if( listeners[listener] == null )
				return false;
			var innerListener:Function = listeners[listener];
			return _s.hasListener( innerListener );
			
		}
		
		public function removeAll():void
		{
			for ( var l:Function in listeners )
			{
				do {
					var haslistener:Boolean = _s.remove( listeners[l] );
				} while( haslistener )
				delete listeners[l];
			}
		}
		
		public function or( s2:ISignal ):ISignal {
			var jointS:Signal = new Signal();
			this.add( jointS.dispatch );
			s2.add( jointS.dispatch );
			return jointS;
		}
		
	}
}
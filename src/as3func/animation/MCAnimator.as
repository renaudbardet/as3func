package as3func.animation
{
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import as3func.lang.BaseFuture;
	import as3func.lang.Context;
	import as3func.lang.Either;

	FUTURE::debug {
		import as3func.lang.getCallerInfo;
	}

	public class MCAnimator extends BaseFuture
	{
		
		private var context:Context;
		private var mc:MovieClip;
		private var to:int;
		
		public function MCAnimator( context:Context, mc:MovieClip, from:* = 0, to:*=null )
		{
			
			super();
			
			if(mc.__animator != null)
				throw "mc is already animated by an MCAnimator";
			
			this.context = context;
			this.mc = mc;
			if(to == null) this.to = mc.totalFrames;
			if(to is int) this.to = Math.min( to, mc.totalFrames );
			if(to is String) {
				mc.gotoAndStop( to );
				this.to = mc.currentFrame;
			}
			
			context.registerEventListener( mc, Event.ENTER_FRAME, onEnterFrame );
			context.registerPauser( onPause );
			context.registerResumer( onResume );
			context.registerCleaner( onClose );
			
			mc.__animator = this;
			mc.gotoAndPlay(from);
			if( from == to ) mc.stop();
			
			FUTURE::debug {
				__debug_stack[0].pos = getCallerInfo();
			}
			
		}
		
		private function onEnterFrame(e:Event):void
		{
			if (this.to == mc.currentFrame)
				_complete(null);
		}
		
		private function onPause():void
		{
			mc.stop();
		}
		
		private function onResume():void
		{
			mc.play();
		}
		
		private function onClose():void
		{
			_fail( "context closed" );
		}
		
		override protected function _completeEither(res:Either):void
		{
			
			context.unregisterEventListener( mc, Event.ENTER_FRAME, onEnterFrame );
			context.unregisterPauser( onPause );
			context.unregisterResumer( onResume );
			context.unregisterCleaner( onClose );
			
			mc.stop();
			delete mc.__animator;
			
			super._completeEither(res);
			
		}
		
		public static function animate(mc:MovieClip, context:Context, from:*=0, to:*=null):MCAnimator
		{
			
			return new MCAnimator(context, mc, from, to);
			
		}
		
	}
}
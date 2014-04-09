package as3func.animation
{
	import flash.display.MovieClip;
	import flash.events.Event;
	
	import as3func.lang.BaseFuture;
	import as3func.lang.Context;
	import as3func.lang.callback;
	import as3func.lang.getCallerInfo;

	public class MCAnimator extends BaseFuture
	{
		
		private var context:Context;
		private var mc:MovieClip;
		private var to:*;
		
		public function MCAnimator( context:Context, mc:MovieClip, from:* = 0, to:*=null )
		{
			
			super();
			
			if(mc.__animator != null)
				throw "mc is already animated by an MCAnimator";
			
			this.context = context;
			this.mc = mc;
			this.to = to;
			if(this.to == null) this.to = mc.totalFrames;
			
			context.registerEventListener( mc, Event.ENTER_FRAME, onEnterFrame );
			context.registerPauser( onPause );
			context.registerResumer( onResume );
			context.registerCleaner( callback( _fail, "context closed" ) );
			
			mc.__animator = this;
			mc.gotoAndPlay(from);
			
			FUTURE::debug {
				__debug_stack[0].pos = getCallerInfo();
			}
			
		}
		
		private function onEnterFrame(e:Event):void
		{
			if(this.to is int && this.to == mc.currentFrame)
				_complete(null);
			else if (this.to is String && this.to == mc.currentFrameLabel)
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
		
		override protected function _complete(d:*):void
		{
			
			context.unregisterEventListener( mc, Event.ENTER_FRAME, onEnterFrame );
			
			mc.stop();
			delete mc.__animator;
			
			super._complete(d);
			
		}
		
		public static function animate(mc:MovieClip, context:Context, from:*=0, to:*=null):MCAnimator
		{
			
			return new MCAnimator(context, mc, from, to);
			
		}
		
	}
}
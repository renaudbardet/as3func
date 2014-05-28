package as3func.animation
{
	import as3func.lang.BaseProgressor;
	import as3func.lang.Context;
	import as3func.lang.Either;
	import as3func.lang.ISignal;
	FUTURE::debug{
		import as3func.lang.getCallerInfo;
	}

	public class Tween extends BaseProgressor
	{
		
		public static var juggler:ISignal;
		
		private var updateFct:Function;
		private var time:Number;
		private var duration:Number;
		private var ctx:Context;
		
		public function Tween(ctx:Context, duration:Number, updateFct:Function)
		{
			super();
			autoComplete = true;
			this.ctx = ctx;
			this.duration = duration;
			this.updateFct = updateFct;
			this.time = 0;
			ctx.registerCleaner(abort);
			
			FUTURE::debug {
				__debug_stack[0].pos = getCallerInfo();
			}
		}
		
		public function play():void
		{
			// ctx is null once completed
			if(ctx == null) return;
			if(juggler == null)
				throw "no juggler";
			ctx.registerSignal(juggler, update);
			if ( isPaused() )
				_resume();
			update(0);
		}
		
		public function pause():void
		{
			if( !isPaused() )
				_pause();
			if(ctx == null) return;
			ctx.unregisterSignal(juggler, update);
		}
		
		private function abort():void
		{
			_fail("context closed before tween ended");
		}
		
		private function update(dt:Number):void
		{
			time += dt;
			if(time > duration) time=duration;
			if(duration <= 0)
				_updateProgress(1);
			else
				_updateProgress(time/duration);
		}
		
		override protected function _updateProgress(prog:Number):void
		{
			updateFct(prog);
			super._updateProgress(prog);
		}
		
		override protected function _completeEither(res:Either):void
		{
			pause();
			ctx=null;
			super._completeEither(res);
		}	
		
		public static function tweenProperty(ctx:Context, object:Object, prop:String, from:Number, to:Number, duration:Number, ease:Function=null):Tween
		{
			
			var t:Tween = new Tween(
				ctx,
				duration,
				function(prog:Number):void{
					if(ease!=null)
						prog = ease(prog);
					object[prop] = from + (to - from)*prog;
				});
			t.play();
			return t;
			
		}
		
		/**
		 * properties is an array of objects like:
		 * {
		 * 		object:Object,
		 * 		prop:String,
		 * 		from:Number,
		 * 		to:Number,
		 * 		duration:Number,
		 * 		(optional) ease:Function,
		 * 		(optional) delay:Number		delay before starting the tween
		 * }	
		 */
		public static function tweenProperties(ctx:Context, properties:Array):Tween
		{
			
			var maxDuration:Number = 0;
			for each ( var property:Object in properties ) {
				if( property.duration ) {
					var propDuration:Number = property.duration + (property.delay ? property.delay : 0);
					if( propDuration > maxDuration )
						maxDuration = propDuration;
				}
			}
			
			var t:Tween = new Tween(
				ctx,
				maxDuration,
				function(prog:Number):void{
					
					for each ( var property:Object in properties ) {
						
						var propDuration:Number = property.duration ? property.duration : maxDuration;
						var delayProg:Number = property.delay ? (property.delay / maxDuration):0;
						if( prog < delayProg ) continue;
						var scaledProg:Number = (prog - delayProg) / (propDuration / maxDuration);
						if( scaledProg > 1 ) continue;
						
						if( property.ease != null )
							scaledProg = property.ease(scaledProg);
						
						property.object[property.prop] = property.from + (property.to - property.from)*scaledProg;
						
					}
					
				});
			t.play();
			return t;
			
		}
		
		public static function makeElasticEase(rebounds:Number):Function
		{
			return function elasticEase(prog:Number):Number {
				return Math.cos(prog*((2*rebounds+1)*Math.PI))*(Math.sqrt(prog)-1)+1; 
			};
		}
		
	}
}
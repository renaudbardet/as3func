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

		public static const LOOP:String = "Tween.looptype.LOOP";
		public static const ROUND:String = "Tween.looptype.ROUND";

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
			if(ctx != null)
				ctx.unregisterSignal(juggler, update);
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
			for each ( var p:Object in properties ) {
				if( p.duration ) {
					var propDuration:Number = p.duration + (p.delay ? p.delay : 0);
					if( propDuration > maxDuration )
						maxDuration = propDuration;
				}
				if( !(p is Function) && p.from == undefined ) {
					p.from = p.object[p.prop];
				}
			}
			
			var t:Tween = new Tween(
				ctx,
				maxDuration,
				function(prog:Number):void{
					
					for each ( var p:Object in properties ) {
						
						if( p is Function ) {
							if( (p as Function).length == 1 )
								p( prog );
							else
								p();
							continue;
						}
						
						var propDuration:Number = p.duration ? p.duration : maxDuration;
						var delayProg:Number = p.delay ? (p.delay / maxDuration):0;
						if( prog < delayProg ) continue;
						var scaledProg:Number = (prog - delayProg) / (propDuration / maxDuration);
						if( scaledProg > 1 ) continue;
						
						if( p.ease != null )
							scaledProg = p.ease(scaledProg);
						
						p.object[p.prop] = p.from + (p.to - p.from)*scaledProg;
						
					}
					
				});
			t.play();
			return t;
			
		}
		
		public static function tween( ctx:Context, duration:Number, updateFunction:Function ):Tween
		{
			var t:Tween = new Tween( ctx, duration, updateFunction );
			t.play();
			return t;
		}

		public static function loopProperty( ctx:Context, obj:Object, prop:String, from:Number, to:Number, duration:Number, delay:Number = 0, loopType:String = LOOP, ease:Function = null):void {

			loop(	ctx,
					duration + delay,
					function(prog:Number):void {

						prog = Number.min( 1, prog*(duration+delay)/duration )
						prog = ease != null ? ease( prog ) : prog;
						obj[prop] = from + (to - from)*prog;

					},
					loopType
			);

		}

		public static function loopProperties( ctx:Context, properties:Array ):void {

			var maxDuration:Number = 0;
			for each ( var p:Object in properties ) {
				if( p.duration ) {
					var propDuration:Number = p.duration + (p.delay ? p.delay : 0);
					if( propDuration > maxDuration )
						maxDuration = propDuration;
				}
			}

			for each ( p in properties ) {

				if( p is Function ) {
					loop( ctx, maxDuration, p as Function, LOOP );
				}
				else {
					loopProperty(
							ctx,
							p.object,
							p.prop,
							p.from != undefined ? p.from : p.object[p.prop],
							p.to,
							p.duration,
							p.delay,
							p.loopType,
							p.ease
					);
				}

			}

		}

		public static function loop( ctx:Context, duration:Number, updateFunction:Function, loopType:String = LOOP ):void {

			var forward:Boolean = true;
			var prog:Number = 0;
			ctx.registerSignal( juggler, function(dt:Number):void {

				if( forward ) {

					prog += dt/duration;
					if( prog >= 1 ){
						if( loopType == LOOP )
							prog -= 1;
						if( loopType == ROUND ){
							prog = 1;
							forward = false;
						}
					}

				} else {

					prog -= dt/duration;
					if( prog <= 0 ) {
						if( loopType == LOOP ) prog += 1; // this should not be possible as of now
						if( loopType == ROUND ){
							prog = 0;
							forward = true;
						}
					}

				}

				updateFunction( prog );

			});

		}
		
		public static function makeElasticEase(rebounds:Number):Function
		{
			return function elasticEase(prog:Number):Number {
				return Math.cos(prog*((2*rebounds+1)*Math.PI))*(Math.sqrt(prog)-1)+1; 
			};
		}

	}
}
package as3func.lang
{
	import flash.utils.Dictionary;

	public class Factory
	{
		
		private var config:Dictionary;
		private var rExp:Dictionary;
		
		public function Factory( config:Dictionary, eRegs:Dictionary = null )
		{
			
			this.config = config;
			this.rExp = (eRegs != null) ? eRegs : new Dictionary();
			
		}
		
		public function loadConfig( additionalConfig:Object ):void {
			
			for ( var k:* in additionalConfig ) {
				this.config[k] = additionalConfig[k];
			}
			
		}
		
		/**
		 * add a regular expression matcher
		 * a regular expression matcher will be tested upon when calling create() with a String id
		 * if an exact match exists for the given id regular expression matchers will not be tested
		 * if multiple regular expressions match the same id, the result is undetermined
		 * 
		 * if the provided value is a Function, it should expect the matched id as first parameter
		 * 
		 * @param r		a regular expression that should catch the required id to create
		 * @param value	a Class to instanciate OR a singleton of any type OR a builder Function
		 * 				in the case of a Function, it should expect the matched id as its first parameter
		 */		
		public function addRExp( r:RegExp, value:* ):void {
			
			rExp[r] = value;
			
		}
		
		public function create( id:*, ...params ):Object
		{
			
			var builder:* = config[id]; 
			
			// if we have a string id, try to match on eRegs
			if(builder == undefined && id is String) {
				for ( var r:RegExp in rExp ) {
					if( r.test( id ) ) {
						builder = rExp[r];
						if( builder is Function ) builder = callback( builder, id );
						break;
					}
				}
			}
			
			if(builder is Class) return __ugliest_factory_funciton_ever__(builder, params);
			if(builder is Function) return builder.apply(null, params);
			
			// if no match but we can instanciate the requested id
			if(builder == undefined && id is Class) return __ugliest_factory_funciton_ever__(id, params);
			
			// builder is a singleton or is undefined, return it
			return builder;
			
		}
		
		public static function buildWithMatrix( data:Array ):Factory
		{
			
			var dict:Dictionary = new Dictionary();
			
			for each ( var kv:Array in data )
				dict[kv[0]] = kv[1];
			
			return new Factory( dict );
			
		}
		
		private static function __ugliest_factory_funciton_ever__(cl:Class, p:Array):Object
		{
			
			if(p.length == 0 ) return new cl();
			if(p.length == 1 ) return new cl(	p[0] );
			if(p.length == 2 ) return new cl(	p[0],p[1] );
			if(p.length == 3 ) return new cl(	p[0],p[1],p[2] );
			if(p.length == 4 ) return new cl(	p[0],p[1],p[2],p[3] );
			if(p.length == 5 ) return new cl(	p[0],p[1],p[2],p[3],p[4] );
			if(p.length == 6 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5] );
			if(p.length == 7 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6] );
			if(p.length == 8 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7] );
			if(p.length == 9 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8] );
			if(p.length == 10 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9] );
			if(p.length == 11 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10] );
			if(p.length == 12 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11] );
			if(p.length == 13 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12] );
			if(p.length == 14 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13] );
			if(p.length == 15 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14] );
			if(p.length == 16 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15] );
			if(p.length == 17 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16] );
			if(p.length == 18 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17] );
			if(p.length == 19 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],
												p[18] );
			if(p.length == 20 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],
												p[18],p[19] );
			if(p.length == 21 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],
												p[18],p[19],p[20] );
			if(p.length == 22 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],
												p[18],p[19],p[20],p[21] );
			if(p.length == 23 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],
												p[18],p[19],p[20],p[21],p[22] );
			if(p.length == 24 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],
												p[18],p[19],p[20],p[21],p[22],p[23] );
			if(p.length == 25 ) return new cl(	p[0],p[1],p[2],p[3],p[4],p[5],p[6],p[7],p[8],p[9],
												p[10],p[11],p[12],p[13],p[14],p[15],p[16],p[17],
												p[18],p[19],p[20],p[21],p[22],p[23],p[24] );
			
			// how many args do you need srsly!
			return null;
			
		}
		
	}
}
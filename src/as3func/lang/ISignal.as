package as3func.lang
{
	public interface ISignal
	{
		function add( listener:Function, once:Boolean=false ):void;
		function map( mapper:Function ):ISignal;
		function filter( mapper:Function ):ISignal;
		function remove( listener:Function ):Boolean;
		function removeAll():void;
		function hasListener( listener:Function ):Boolean;
		function nextDispatch():IFuture;
	}
}
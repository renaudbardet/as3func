package as3func.lang
{
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	
	public function getClass(o:Object):Class
	{
		
		return getDefinitionByName(getQualifiedClassName(o)) as Class;
		
	}
	
}
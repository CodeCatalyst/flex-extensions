////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2011 CodeCatalyst, LLC - http://www.codecatalyst.com/
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.	
////////////////////////////////////////////////////////////////////////////////

package com.codecatalyst.factory
{
	import com.codecatalyst.data.Property;
	import com.codecatalyst.util.EventDispatcherUtil;
	import com.codecatalyst.util.PropertyUtil;
	
	import flash.events.IEventDispatcher;
	
	import mx.core.IDataRenderer;
	import mx.events.FlexEvent;
	
	
	/**
	 * This RendererFactory is used as a generator within Lists, Grids, and Populators where the developer needs to customize settings 
	 * on each renderer instance based on current values of that instance's assigned "data" object. This means that renderer instances   
	 * can now easily respond to runtime changes [of the 'data' object values]. 
	 * 
	 * The DataRendererFactory supports creation of any class instances but will NOT perform any construction or runtime configuration 
	 * of the "styles" for the instances. In such cases the StyleableRendererFactory should be used.
	 * 
	 * @see StyleableRendererFactory 
	 * 
	 * @example
	 * 
	 * <mx:DataGrid width="100%" height="100%" >
	 *   <mx:DataGridColumn 
	 *		width="100"
	 *		headerText="Result"
	 *		sortable="false">
	 * 
	 *		<mx:itemRenderer>
	 * 
	 * 		  <!-- Notice, here we do not use the  Component wrapper "trick" -->
	 * 
	 *		  <fe:DataRendererFactory
	 * 				generator="{ USFlagSprite }"
	 * 				properties="{ { x : this.width/2, 
	 * 								y : this.height/2 
	 * 							} }"
	 * 				eventListeners="{ { mouseDown : function (e:MouseEvent):void {
	 * 													var render : USFlagSprite = event.target as USFlagSprit;
	 * 													    render.alpha = 0.2;
	 * 												}, 
	 * 									mouseOver : function (e:MouseEvent):void {
	 * 													// some other custom code here...
	 * 													// Notice the "this" is scoped to the DataGrid...
	 * 												} 
	 * 								   } }"
	 * 				runtimeProperties="{ { visible : function (data:Object):Boolean {
	 * 													return (data.citizenship == 'USA');
	 * 												 } 
 	 * 								   } }" 
	 * 				xmlns:fe="http://www.codecatalyst.com/2011/flex-extensions" />
	 *		</mx:itemRenderer>
	 * 
	 *	 </mx:DataGridColumn>
	 * </mx:DataGrid>
	 *  
	 * 
	 * @author Thomas Burleson
	 * @author John Yanarella
	 * 
	 * 
	 */
	
	public class DataRendererFactory extends ClassFactory
	{
		// ========================================
		// Public properties
		// ========================================
		
		/**
		 * Hashmap of property key / value pairs evaluated and applied to resulting instances during each data change/assignment.
		 */
		public var runtimeProperties:Object = null;
		
		// ========================================
		// Constructor
		// ========================================
		
		/**
		 * Constructor.
		 */
		public function DataRendererFactory( generator			:Object = null, 
											 parameters			:Array  = null, 
											 properties			:Object = null, 
											 eventListeners		:Object = null, 
											 runtimeProperties	:Object = null )
		{
			super( generator, parameters, properties, eventListeners );
			
			this.runtimeProperties = runtimeProperties;
		}
		
		// ========================================
		// Public methods
		// ========================================
		
		/**
		 * @inheritDoc
		 */
		public override function newInstance():*
		{
			// Create instance with applied construction properties and eventListeners
			
			var instance:Object = super.newInstance();
			
			if ( instance is IEventDispatcher ) {
				
				// Add FlexEvent.DATA_CHANGE handler to apply runtime properties 
				
				( instance as IEventDispatcher ).addEventListener( FlexEvent.DATA_CHANGE, renderer_dataChangeHandler, false, 0, true );
			}
			
			return instance;
		}
		
		// ========================================
		// Protected methods
		// ========================================
		
		/**
		 * Handle FlexEvent.DATA_CHANGE.
		 */
		protected function renderer_dataChangeHandler( event:FlexEvent ):void
		{
			PropertyUtil.applyProperties( event.target, runtimeProperties, false, true );
		}

	}
}
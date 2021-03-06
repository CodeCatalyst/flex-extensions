////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2010 CodeCatalyst, LLC - http://www.codecatalyst.com/
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

package com.codecatalyst.component.behavior.ui
{
	import com.codecatalyst.component.behavior.AbstractBehavior;
	import com.codecatalyst.component.behavior.IBehavior;
	import com.codecatalyst.util.CollectionViewUtil;
	import com.codecatalyst.util.FactoryPool;
	
	import flash.display.DisplayObject;
	import flash.events.Event;
	
	import mx.collections.ICollectionView;
	import mx.core.Container;
	import mx.core.IDataRenderer;
	import mx.core.IFactory;
	import mx.events.CollectionEvent;
	import mx.events.CollectionEventKind;
	import mx.events.PropertyChangeEvent;
	
	[DefaultProperty("dataProvider")]
	public class Populator extends AbstractBehavior implements IBehavior
	{
		// ========================================
		// Protected properties
		// ========================================
		
		/**
		 * Backing variable for <code>target</code> property.
		 */
		protected var _target:Container;
		
		/**
		 * Backing variable for <code>dataProvider</code> property.
		 */
		protected var _dataProvider:Object;
		
		/**
		 * Backing variable for <code>itemRenderer</code> property.
		 */			
		protected var _itemRenderer:IFactory;
		
		/**
		 * An ICollectionView that represents the data provider.
		 */
		protected var collection:ICollectionView;
		
		/**
		 * Indicates the <code>target</code> property changed and must be committed.
		 */
		protected var targetChanged:Boolean;
		
		/**
		 * Indicates the <code>dataProvider</code> property changed and must be committed.
		 */
		protected var dataProviderChanged:Boolean;
		
		/**
		 * Indicates the <code>itemRenderer</code> property changed and must be committed.
		 */
		protected var itemRendererChanged:Boolean;
		
		/**
		 * Item renderer object pool.
		 */
		protected var itemRendererPool:FactoryPool;	
		
		// ========================================
		// Public properties
		// ========================================
		
		[Bindable( "targetChanged" )]
		/**
		 * Target container.
		 */
		public function get target():Container
		{
			return _target;	
		}
		
		public function set target( value:Container ):void
		{
			if ( _target != value )
			{			
				_target = value;
				
				targetChanged = true;
				
				invalidateProperties();
				
				dispatchEvent( new Event( "targetChanged" ) );
			}
		}
		
		[Bindable( "dataProviderChanged" )]
		/**
		 * Data provider.
		 */		
		public function get dataProvider():Object
		{
			return _dataProvider;
		}
		
		public function set dataProvider( value:Object ):void
		{
			if ( _dataProvider != value )
			{
				_dataProvider = value;
				
				dataProviderChanged = true;
				
				invalidateProperties();
				
				dispatchEvent( new Event( "dataProviderChanged" ) );
			}
		}
		
		[Bindable( "itemRendererChanged" )]
		/**
		 * Custom view to use to render the data.
		 * 
		 * @see mx.core.IDataRenderer IDataRenderer
		 */	
		public function get itemRenderer():IFactory
		{
			return _itemRenderer;
		}
		
		public function set itemRenderer( value:IFactory ):void
		{
			if ( _itemRenderer != value )
			{
				_itemRenderer = value;
				
				if ( itemRendererPool != null )
					itemRendererPool.reset();
				
				itemRendererPool = new FactoryPool( value );
				
				itemRendererChanged = true;
				
				invalidateProperties();
				
				dispatchEvent( new Event( "itemRendererChanged" ) );
			}
		}
		
		// ========================================
		// Constructor
		// ========================================
		
		/**
		 * Constructor.
		 */	
		public function Populator()
		{
			super();
		}
		
		// ========================================
		// Protected methods
		// ========================================
		
		/**
		 * @inheritDoc
		 */
		override protected function commitProperties():void
		{
			super.commitProperties();
			
			if ( dataProviderChanged )
			{
				if ( collection != null )
					collection.removeEventListener( CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler );
				
				collection = CollectionViewUtil.create( _dataProvider );
				
				collection.addEventListener( CollectionEvent.COLLECTION_CHANGE, collectionChangeHandler, false, 0, true );
			}
			
			if ( dataProviderChanged || itemRendererChanged  || targetChanged )
			{
				reset();
				
				dataProviderChanged = false;
				itemRendererChanged = false;
				targetChanged = false;
			}
		}
		
		/**
		 * Reset
		 */
		protected function reset():void
		{
			// Force a reset.
			
			var event:CollectionEvent = new CollectionEvent(CollectionEvent.COLLECTION_CHANGE);
			event.kind = CollectionEventKind.RESET;
			
			collectionChangeHandler( event );
		}
		
		/**
		 * CollectionEvent.COLLECTION_CHANGE handler.
		 */
		protected function collectionChangeHandler( event:CollectionEvent ):void
		{
			if ( target == null )
				return;
			
			switch ( event.kind )
			{
				case CollectionEventKind.ADD:
					addTargetItems( event.items, event.location );
					break;				
				
				case CollectionEventKind.MOVE:
					moveTargetItem( event.oldLocation, event.location );
					break;
				
				case CollectionEventKind.REMOVE:
					removeTargetItems( event.items, event.location );
					break;
				
				case CollectionEventKind.REPLACE:
					replaceTargetItems( event.items, event.location );
					break;
				
				case CollectionEventKind.REFRESH:
				case CollectionEventKind.RESET:
					populateTarget();
					break;
				
				case CollectionEventKind.UPDATE:
					// Nothing required.
					break;
			}
		}
		
		/**
		 * Add the specified target items at the specified location.
		 */
		protected function addTargetItems( items:Array, location:int ):void
		{
			var itemCount:int = items.length;
			for ( var itemIndex:int = 0; itemIndex < itemCount; itemIndex++ )
			{
				target.addChildAt( createItemRenderer( items[ itemIndex ] ) as DisplayObject, location + itemIndex );
			}
		}
		
		/**
		 * Move the specified target items at the specified old location to the specified new location.
		 */
		protected function moveTargetItem( oldLocation:int, newLocation:int ):void
		{
			target.setChildIndex( target.getChildAt( oldLocation ), newLocation );
		}
		
		/**
		 * Remove the specified target items at the specified location.
		 */
		protected function removeTargetItems( items:Array, location:int ):void
		{
			var itemCount:int = items.length;
			for ( var itemIndex:int = 0; itemIndex < itemCount; itemIndex++ )
			{
				destroyItemRenderer( target.removeChildAt( location ) as IDataRenderer );
			}
		}
		
		/**
		 * Replace the specified target items at the specified location.
		 */
		protected function replaceTargetItems( items:Array, location:int ):void
		{
			var itemCount:int = items.length;
			for ( var itemIndex:int = 0; itemIndex < itemCount; itemIndex++ )
			{
				var event:PropertyChangeEvent = items[ itemIndex ] as PropertyChangeEvent;
				
				var renderer:IDataRenderer = target.getChildAt( location + itemIndex ) as IDataRenderer; 
				renderer.data = event.newValue;
			}
		}
		
		/**
		 * Populate the target with item renderers.
		 */
		protected function populateTarget():void
		{
			// Remove all item renderers from the target.
			
			var targetChildCount:int = target.numChildren;
			for ( var targetChildIndex:int = 0; targetChildIndex < targetChildCount; targetChildIndex++ )
			{
				destroyItemRenderer( target.getChildAt( targetChildIndex ) as IDataRenderer );
			}
			if ( targetChildCount > 0 )
				target.removeAllChildren();
			
			// Add item renderers for the new items to the target.
			
			for each ( var item:Object in collection )
			{
				target.addChild( createItemRenderer( item ) as DisplayObject );
			}
		}
		
		/**
		 * Create (or grab from the item renderer pool) an item renderer for the specified item.
		 */
		protected function createItemRenderer( item:Object ):IDataRenderer
		{
			var itemRendererInstance:IDataRenderer = itemRendererPool.acquireInstance() as IDataRenderer;
			itemRendererInstance.data = item;
			
			return itemRendererInstance;
		}
		
		/**
		 * Destroy the specified item renderer - adds (or returns) the item renderer to the item renderer pool.
		 */
		protected function destroyItemRenderer( itemRendererInstance:IDataRenderer ):void
		{
			itemRendererPool.releaseInstance( itemRendererInstance );
		}
	}
}

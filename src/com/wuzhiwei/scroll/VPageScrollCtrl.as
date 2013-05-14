package com.wuzhiwei.scroll
{
	import com.greensock.TweenLite;
	import com.greensock.easing.Strong;
	import com.greensock.plugins.ThrowPropsPlugin;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TouchEvent;
	import flash.geom.Rectangle;
	import flash.text.TextField;
	import flash.utils.getDefinitionByName;
	import flash.utils.getTimer;
	
	public class VPageScrollCtrl extends ScrollCtrl
	{
		protected var _initX:Number;
		protected var _initY:Number;
		protected var _gapY:Number;
		protected var _curIdx:int;
		protected var _maxIdx:int;
		protected var _dataList:*;
		protected var _unitPool:Vector.<DisplayObject>;
		protected var _dataFunc:Function;
		protected var _maxUnitNum:uint;
		protected var _needPageScroll:Boolean;
		protected var _scrollMode:uint;
		protected var _knowMode:Boolean;
		protected var _tarX:Number;
		protected var _tarY:Number;
		protected var _pageTf:TextField;
		protected var _leftBuoy:Sprite;
		protected var _rightBuoy:Sprite;
		
		protected static const VMODE:uint = 0;
		protected static const HMODE:uint = 1;
		
		/**
		 * 可纵向滑动，横向翻页的纵向滑移类 
		 * @param scrollBg - 滑移背景
		 * @param scrollObj - 滑移目标
		 * @param maskRect - 滑移目标的mask
		 * @param unitLink - 滑移目标内部填充的单元链接
		 * @param initX - 滑移目标内部单元的初始X
		 * @param initY - 滑移目标内部单元的初始Y
		 * @param gapY - 滑移目标内部单元之间的Y轴间距
		 * @param maxUnitNum - 一页最多可以有的滑移单元数
		 * @param dataFunc - 滑移单元的数据设置函数
		 * @param pageTf - 滑移的页标，用于翻页时更新
		 * @param leftBuoy - 滑移的左翻页标示
		 * @param rightBuoy - 滑移的右翻页标识
		 * @param useBlitMask
		 * @param needSideBar
		 * @param sideBarColor
		 * @param sideBarOffsetX
		 * @param sideBarOffsetY
		 * @param speedFactor
		 * @param resistance
		 * @param tweenMaxDuration
		 * @param tweenMinDuration
		 * @param minXOffset
		 * @param maxXOffset
		 * @param minYOffset
		 * @param maxYOffset
		 * 
		 */		
		public function VPageScrollCtrl( scrollBg:Sprite,
										 scrollObj:Sprite,
										 maskRect:Rectangle,
										 unitLink:*,
										 initX:Number,
										 initY:Number,
										 gapY:Number,
										 maxUnitNum:uint,
										 dataFunc:Function,
										 pageTf:TextField,
										 leftBuoy:Sprite = null,
										 rightBuoy:Sprite = null,
										 useBlitMask:Boolean=false,
										 needSideBar:Boolean=true,
										 sideBarColor:uint=0xffffff,
										 sideBarOffsetX:Number=-20,
										 sideBarOffsetY:Number=-20,
										 speedFactor:Number=1.0,
										 resistance:Number=20.0,
										 tweenMaxDuration:Number=2.0,
										 tweenMinDuration:Number=0.2,
										 minXOffset:Number=0,
										 maxXOffset:Number=0,
										 minYOffset:Number=0,
										 maxYOffset:Number=0 )
		{
			_tarX = scrollObj.x;
			_tarY = scrollObj.y;
			
			var i:int;
			var cls:* = ( unitLink is Class ? 
				unitLink : getDefinitionByName( unitLink ) );
			_unitPool = new Vector.<DisplayObject>;
			_maxUnitNum = maxUnitNum;
			var unit:DisplayObject;
			for( i = 0; i < maxUnitNum; i++ )
			{
				unit = new cls;
				_unitPool.push( unit );
				(unit as MovieClip).gotoAndStop( 1 );
			}
			
			_curIdx = 0;
			_initX = initX;
			_initY = initY;
			_gapY = gapY;
			_dataFunc = dataFunc;
			_pageTf = pageTf;
			_leftBuoy = leftBuoy;
			_rightBuoy = rightBuoy;
			
			super( scrollBg, scrollObj, maskRect, ScrollDirection.VECTORIAL, useBlitMask, 
				needSideBar, sideBarColor, sideBarOffsetX, sideBarOffsetY, 
				speedFactor, resistance, tweenMaxDuration, tweenMinDuration, 
				minXOffset, maxXOffset, minYOffset, maxYOffset );
		}
		
		/**
		 * 更新滑移数据列表 
		 * 重置滑移对象的位置和内部的滑移单元
		 * 更新滑移边界条件和滑移条
		 */		
		public function set dataList( list:* ):void
		{
			_dataList = list;
			if( _dataList )
			{
				_curIdx = 0;
				TweenLite.killTweensOf( _target );
				_target.x = _tarX;
				_target.y = _tarY;
				_maxIdx = ( (_dataList.length - 1 < 0 ? 0 : _dataList.length - 1) / _maxUnitNum );
				_target.removeChildren();
				//set first page
				var i:int;
				var unit:DisplayObject;
				var pageRange:int = Math.min(_dataList.length, _maxUnitNum);
				for( i = 0; i < pageRange; i++ )
				{
					unit = _unitPool[i];
					unit.visible = true;
					unit.x = _initX;
					unit.y = _initY + i * (_gapY + unit.height);
					_dataFunc.apply( null, [ unit, _dataList[i] ] ); 
					_target.addChild( unit );
				}
				_needPageScroll = (_maxIdx >= 1);
				forceUpdate();
			}
		}
		
		
		override protected function mouseDownHandler(e:Event):void
		{
			_knowMode = false;
			_scrollMode = VMODE;
			super.mouseDownHandler( e );
		}
		
		override protected function mouseMoveHandler(e:Event):void
		{
			if( _isMouseDown )
			{
				var newX:Number = Math.ceil(_bg.mouseX - _offsetPt.x);
				var newY:Number =  Math.ceil(_bg.mouseY - _offsetPt.y);
				
				var moveX:Number = Math.abs(newX - _target.x);
				var moveY:Number = Math.abs(newY - _target.y);
				
				if( !_knowMode && _needPageScroll )
				{
					//判定滑移模式，若X轴滑移距离大于2倍Y轴滑移距离，则断定是想翻页
					_scrollMode = (moveX > 2 * moveY ? HMODE : VMODE);
					_knowMode = true;
					trace( "Scroll Mode :", _scrollMode );
					trace( moveX, moveY );
				}
				
				var isScrollOn:Boolean = false;
				
				if( ( _scrollMode == HMODE && moveX > MAX_CLICK_MOVE_DIST )
					|| ( _scrollMode == VMODE && moveY > MAX_CLICK_MOVE_DIST )
				)
				{
					isScrollOn = true;
				}
				
				if( !_isMouseMoved && isScrollOn )
				{
					if( _needUpdateWhenMove )
					{
						_bg.addEventListener( Event.ENTER_FRAME, updateHandler, false, 0, true );
					}
					_isMouseMoved = true;
					enableBlitMask();
					disableTargetMouse();
				}
				
				if( _scrollMode == HMODE )
				{
					if( newX > _maxX )
					{
						_target.x = (newX + _maxX) * 0.5;
					}else if( newX < _minX )
					{
						_target.x = (newX + _minX ) * 0.5;
					}else
					{
						_target.x = newX;
					}
				}
				else if(  _scrollMode == VMODE )
				{
					if( newY > _maxY )
					{
						_target.y = (newY + _maxY) * 0.5;
					}else if( newY < _minY )
					{
						_target.y = (newY + _minY) * 0.5;
					}else
					{
						_target.y = newY;
					}
				}
				
				if( _blitMask )
				{
					_blitMask.update();
				}
				var t:uint = getTimer();
				if( t - _t2 > 50 )
				{
					_p2.copyFrom( _p1 );
					_t2 = _t1;
					_p1.setTo( _target.x, _target.y );
					_t1 = t;
				}
				updateSideBar();
				if( e is MouseEvent )
				{
					(e as MouseEvent).updateAfterEvent();					
				}
				else if( e is TouchEvent )
				{
					(e as TouchEvent).updateAfterEvent();					
				}
			}
		}
		
		override protected function tweenAfterRelease():void
		{
			AirScroll.log( "tweenAfterRelease." );
			enableTargetMouse();
			
			var time:Number = ( getTimer() - _t2 ) * 0.001;
			var xVelocity:Number = _speedFactor * ( _target.x - _p2.x ) / time;
			var yVelocity:Number = _speedFactor * ( _target.y - _p2.y ) / time;
			
			if( _scrollMode == VMODE )
			{
				var throwProps:Object = {};
				throwProps["y"] = { velocity:yVelocity, max:_maxY, min: _minY, resistance:_resistance };
				ThrowPropsPlugin.to( _target, 
					{ throwProps:throwProps, ease:Strong.easeOut,
						onUpdate:updateHandler, onComplete:stopAll },
					_tweenMaxDuration, _tweenMinDuration, 0.2 );
			}
			else if( _scrollMode == HMODE )
			{
				//切页判定
				trace( xVelocity, _target.x, _tarX, _maxX, _minX ); 
				if( Math.abs(xVelocity) > 50 || Math.abs(_target.x) > 300 )
				{
					xVelocity < 0 ? pageRight() : pageLeft();					
				}
				else
				{
					TweenLite.to( _target, 0.2, { x:_tarX } );
				}
			}
		}
		
		override public function forceUpdate():void
		{
			super.forceUpdate();
			//更新页签
			if( _pageTf )
			{
				_pageTf.text = (_curIdx+1)+"/"+(_maxIdx+1);		
			}
			if( _leftBuoy )
			{
				_leftBuoy.visible = _needPageScroll;
			}
			if( _rightBuoy )
			{
				_rightBuoy.visible = _needPageScroll;
			}
		}
		
		/**
		 * 左翻页 
		 * 
		 */		
		protected function pageLeft():void
		{
			_curIdx --;
			if( _curIdx < 0 )
			{
				_curIdx = _maxIdx;
			}
			switchToPage();
		}
		
		/**
		 * 右翻页 
		 * 
		 */		
		protected function pageRight():void
		{
			_curIdx ++;
			if( _curIdx > _maxIdx )
			{
				_curIdx = 0;
			}
			switchToPage();
		}
		
		/**
		 * 进行翻页操作 
		 * 
		 */		
		protected function switchToPage():void
		{
			AirScroll.log("switchToPage");
			_target.y = _tarY;
			_target.x = _tarX;
			_target.removeChildren();
			var initIdx:int = _maxUnitNum * _curIdx;
			var lastIdx:int = Math.min( _dataList.length, initIdx + _maxUnitNum );
			var i:int;
			var j:int = 0;
			var unit:DisplayObject;
			for( i = initIdx; i < lastIdx; i++, j++ )
			{
				unit = _unitPool[j];
				unit.visible = true;
				unit.x = _initX;
				TweenLite.from( unit, 0.1+0.05*(j+1), { x:"+400" } );
				unit.y = _initY + j * (_gapY + unit.height);
				_dataFunc.apply( null, [ unit, _dataList[i] ] ); 
				_target.addChild( unit );
			}
			forceUpdate();
			//TweenLite.to( _target, 0.2, { x:_tarX } );
			trace( (_curIdx+1)+"/"+(_maxIdx+1) );
		}
		
	}
}
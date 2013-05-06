package com.wuzhiwei.scroll
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	
	public class HortSimScrollCtrl extends ScrollCtrl
	{
		
		protected var _unitList:Vector.<Sprite>;
		protected var _unitWidth:Number;
		
		protected var _initX:Number;
		protected var _initY:Number;
		protected var _xGap:Number;
		protected var _gapWidth:Number;
		
		protected var _dataList:*;
		protected var _idx:int;
		protected var _initIdx:int;
		protected var _leftIdx:int = 0;
		protected var _rightIdx:int = 0;
		protected var _offsetLX:Number;
		protected var _offsetRX:Number;
		protected var _lastX:Number;
		
		protected var _lastIdx:uint;
		
		protected var _dataFunc:Function;
		
		private static const OFFSET_FIX:Number = 0.000001234567;
		/**
		 * 模拟横向滑移类 
		 * @param scrollBg 滑移背景，侦听鼠标事件以更改滑移行为
		 * @param scrollObj 滑移内容，承载用于显示滑移的容器
		 * @param maskRect 遮罩矩形
		 * @param diretion 滑移方向
		 * @param unitLink 滑移单元的链接名或类名
		 * @param unitNum 同屏最多可显示的滑移单元的个数
		 * @param initX 第一个滑移单元的x
		 * @param initY 第一个滑移单元的y
		 * @param xGap 滑移单元之间的X间距
		 * @param dataFunc 滑移单元设置数据函数
		 * @param useBlitMask 是否开启blitMask渲染
		 * @param needSideBar 是否显示滑移块
		 * @param sideBarColor 滑移块的颜色
		 * @param speedFactor 鼠标释放后的缓动加速因子
		 * @param resistance 鼠标释放后的缓动的阻尼系数
		 * @param tweenMaxDuration 鼠标释放后的缓动的最大时间
		 * @param tweenMinDuration 鼠标释放后的缓动的最小时间
		 * @param minXOffset X轴的最小值的“偏移”量
		 * @param maxXOffset X轴的最大值的“偏移”量
		 */	
		public function HortSimScrollCtrl(scrollBg:Sprite,
									  scrollObj:Sprite,
									  maskRect:Rectangle,
									  unitLink:*,
									  unitNum:uint,
									  initX:Number,
									  initY:Number,
									  xGap:Number,
									  dataFunc:Function,
									  useBlitMask:Boolean=false,
									  needSideBar:Boolean=false,
									  sideBarColor:uint = 0xffffff,
									  sideBarOffsetX:Number = -20,
									  sideBarOffsetY:Number = -20,
									  speedFactor:Number=1,
									  resistance:Number=20,
									  tweenMaxDuration:Number=1.6,
									  tweenMinDuration:Number=0.25,
									  minXOffset:Number = 0,
									  maxXOffset:Number = 0)
		{
			_initX = initX;
			_initY = initY;
			_xGap = xGap;
			_dataFunc = dataFunc;
			_bounds = maskRect;
			
			var cls:* = ( unitLink is Class ? 
				unitLink : getDefinitionByName( unitLink ) );
			_unitList = new Vector.<Sprite>;
			
			var unit:Sprite;
			for( var i:int = 0; i < unitNum; i++ )
			{
				unit = new cls;
				_unitWidth = unit.width;
				_gapWidth = _unitWidth + _xGap;
				unit.x = _initX + i * _gapWidth;
				unit.y = _initY;
				scrollObj.addChild( unit );
				_unitList.push( unit );
				if( unit.x < _bounds.right && unit.x + _unitWidth > _bounds.right )
				{
					_lastIdx = i;
				}
			}
			
			calOffsetX( _lastIdx );
			
			super( scrollBg, scrollObj, maskRect, ScrollDirection.HORIZONTAL, 
				useBlitMask, needSideBar, sideBarColor, sideBarOffsetX, sideBarOffsetY,
				speedFactor, resistance, tweenMaxDuration, tweenMinDuration,
				minXOffset, maxXOffset );
			
			_needUpdateWhenMove = true;
		}
		
		override protected function calOverLap():void
		{
			if( _dataList )
			{
				_minX = -( _dataList.length - _initIdx ) * _gapWidth + _bounds.width - _minXOffset;
				_maxX = _initIdx * _gapWidth + _maxXOffset;
			}
		}
		
		/**
		 * 计算左右滑移偏移距，做为是否越界更新的依据 
		 * @param lastIdx
		 * 
		 */		
		protected function calOffsetX( lastIdx:int ):void
		{
			_offsetLX = _unitList[lastIdx].x + _unitWidth - _bounds.right + OFFSET_FIX;
			_offsetRX = _unitList[0].x - _bounds.left + OFFSET_FIX;
		}
		
		/**
		 * 重设target的x为0
		 * 重设滑移模拟位置 
		 * 
		 */		
		public function resetAll():void
		{
			_target.x = 0;
			_leftIdx = _rightIdx = 0;
			_lastX = 0;
		}
		
		/**
		 * 设置模拟滑移的数据列表和初始位置  
		 * @param dataList
		 * @param initIndex
		 * 
		 */		
		public function setDataList( dataList:*, initIndex:int = 0 ):void
		{
			if( initIndex >= dataList.length || initIndex < 0 )
			{
				trace( "Error: initIndex "+ initIndex +" is illegal!" );
				return;
			}
			
			removeAllListeners();
			resetAll();
			
			_dataList = dataList;
			_idx = initIndex;
			_initIdx = _idx;
			
			var i:int;
			var dataIdx:int= 0;
			for( i = 0; i < _unitList.length; i++ )
			{
				_unitList[i].x = _initX + i * _gapWidth;
				_unitList[i].y = _initY;
				dataIdx = _initIdx - 1 + i;
				if( dataIdx < 0 || dataIdx >= _dataList.length )
				{
					_unitList[i].visible = false;
				}
				else
				{
					_unitList[i].visible = true;
					_dataFunc.apply( null, [ _unitList[i], _dataList[dataIdx] ] );
				}
				if( _unitList[i].x < _bounds.right && _unitList[i].x + _unitWidth > _bounds.right )
				{
					_lastIdx = i;
				}
			} 
			
			calOffsetX( _lastIdx );
			calOverLap();
			forceUpdate();
			
			disableBlitMask();
			addMouseDownListener();
		}
		
		override protected function updateHandler( e:Event = null ):void
		{
			//越界，更新面板位置
			var r:Number = ( _target.x + _offsetRX ) / _gapWidth;
			var l:Number = ( _target.x + _offsetLX ) / _gapWidth;
			
			var unit:Sprite;
			var i:int = 0;
			var mvOffsetX:Number = _target.x - _lastX;
			
			var leftdataIdx:int;
			var rightdataIdx:int;
			//左滑移越界
			if( l <= _leftIdx )
			{
				for ( i = 0; i <= int(_leftIdx - l); i++ )
				{
					_rightIdx --;
					if( mvOffsetX < 0 )
					{
						leftdataIdx = _idx + _lastIdx;
						unit = _unitList.shift();
						unit.visible = ( leftdataIdx >= 0 && leftdataIdx < _dataList.length );
						_dataFunc.apply( null, [ unit, leftdataIdx >= _dataList.length ? null : _dataList[leftdataIdx] ] );
						unit.x = _unitList[ _unitList.length - 1 ].x + _gapWidth;
						_unitList.push( unit );
						
						_idx ++;
					}
				}
				_leftIdx = ( l < 0 ? int(l)-1 : int(l) );
			}
			//右滑移越界
			if( r >= _rightIdx )
			{
				for ( i = 0; i <= int(r - _rightIdx); i++ )
				{
					_leftIdx ++;
					if( mvOffsetX > 0 )
					{
						_idx --;
						
						unit = _unitList.pop();
						unit.visible = ( _idx > 0 && _idx <= _dataList.length );
						_dataFunc.apply( null, [ unit, _idx > 0 ? _dataList[_idx-1] : null ] );
						unit.x = _unitList[0].x - _gapWidth;
						_unitList.unshift( unit );
						
					}
				}
				_rightIdx = ( r < 0 ? int(r) : int(r)+1 );
			}
			_lastX = _target.x;
			
			if( _blitMask )
			{
				_blitMask.update();
			}
			updateSideBar();
		}
		
	}
}
package com.wuzhiwei.scroll
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Rectangle;
	import flash.utils.getDefinitionByName;
	
	public class VectSimScrollCtrl extends ScrollCtrl
	{
		
		protected var _unitList:Vector.<Sprite>;
		protected var _unitHeight:Number;
		
		protected var _initX:Number;
		protected var _initY:Number;
		protected var _yGap:Number;
		protected var _gapHeight:Number;
		
		protected var _dataList:*;
		protected var _idx:int;
		protected var _initIdx:int;
		protected var _upIdx:int = 0;
		protected var _downIdx:int = 0;
		protected var _offsetUY:Number;
		protected var _offsetDY:Number;
		protected var _lastY:Number;
		
		protected var _lastIdx:uint;
		
		protected var _dataFunc:Function;
		
		private static const OFFSET_FIX:Number = 0.000001234567;
		/**
		 * 模拟纵向滑移类 
		 * @param scrollBg 滑移背景，侦听鼠标事件以更改滑移行为
		 * @param scrollObj 滑移内容，承载用于显示滑移的容器
		 * @param maskRect 遮罩矩形
		 * @param diretion 滑移方向
		 * @param unitLink 滑移单元的链接名或类名
		 * @param unitNum 同屏最多可显示的滑移单元的个数
		 * @param initX 第一个滑移单元的x
		 * @param initY 第一个滑移单元的y
		 * @param yGap 滑移单元之间的Y间距
		 * @param dataFunc 滑移单元设置数据函数
		 * @param useBlitMask 是否开启blitMask渲染
		 * @param needSideBar 是否显示滑移块
		 * @param sideBarColor 滑移块的颜色
		 * @param speedFactor 鼠标释放后的缓动加速因子
		 * @param resistance 鼠标释放后的缓动的阻尼系数
		 * @param tweenMaxDuration 鼠标释放后的缓动的最大时间
		 * @param tweenMinDuration 鼠标释放后的缓动的最小时间
		 * @param minYOffset Y轴的最小值的“偏移”量
		 * @param maxYOffset Y轴的最大值的“偏移”量
		 */	
		public function VectSimScrollCtrl(scrollBg:Sprite,
									  scrollObj:Sprite,
									  maskRect:Rectangle,
									  unitLink:*,
									  unitNum:uint,
									  initX:Number,
									  initY:Number,
									  yGap:Number,
									  dataFunc:Function,
									  useBlitMask:Boolean=false,
									  needSideBar:Boolean=false,
									  sideBarColor:uint = 0xffffff,
									  sideBarOffsetX:Number = -20,
									  sideBarOffsetY:Number = -20,
									  speedFactor:Number=2,
									  resistance:Number=20,
									  tweenMaxDuration:Number=1.6,
									  tweenMinDuration:Number=0.25,
									  minYOffset:Number = 0,
									  maxYOffset:Number = 0)
		{
			_initX = initX;
			_initY = initY;
			_yGap = yGap;
			_dataFunc = dataFunc;
			_bounds = maskRect;
			
			var cls:* = ( unitLink is Class ? 
				unitLink : getDefinitionByName( unitLink ) );
			_unitList = new Vector.<Sprite>;
			
			var unit:Sprite;
			for( var i:int = 0; i < unitNum; i++ )
			{
				unit = new cls;
				_unitHeight = unit.height;
				_gapHeight = _unitHeight + _yGap;
				unit.x = _initX;
				unit.y = _initY + i * _gapHeight;
				scrollObj.addChild( unit );
				_unitList.push( unit );
				if( unit.y < _bounds.bottom && unit.y + _unitHeight > _bounds.bottom )
				{
					_lastIdx = i;
				}
			}
			
			calOffsetY( _lastIdx );
			
			super( scrollBg, scrollObj, maskRect, ScrollDirection.VECTORIAL, 
				useBlitMask, needSideBar, sideBarColor, sideBarOffsetX, sideBarOffsetY,
				speedFactor, resistance, tweenMaxDuration, tweenMinDuration, 
				0, 0, minYOffset, maxYOffset );
			
			_needUpdateWhenMove = true;
		}
		
		override protected function calOverLap():void
		{
			if( _dataList )
			{
				_minY = -( _dataList.length - _initIdx ) * _gapHeight + _bounds.height - _minYOffset;
				_maxY = _initIdx * _gapHeight + _maxYOffset;				
			}
		}
		
		/**
		 * 计算上下滑移偏移距，做为是否越界更新的依据 
		 * @param lastIdx
		 * 
		 */	
		protected function calOffsetY( lastIdx:int ):void
		{
			_offsetUY = _unitList[lastIdx].y + _unitHeight - _bounds.bottom + OFFSET_FIX;
			_offsetDY = _unitList[0].y - _bounds.top + OFFSET_FIX;
		}
		
		/**
		 * 重设target的y为0
		 * 重设滑移模拟位置 
		 * 
		 */	
		public function resetAll():void
		{
			_target.y = 0;
			_upIdx = _downIdx = 0;
			_lastY = 0;
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
				_unitList[i].x = _initX;
				_unitList[i].y = _initY + i * _gapHeight;
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
				if( _unitList[i].y < _bounds.bottom && _unitList[i].y + _unitHeight > _bounds.bottom )
				{
					_lastIdx = i;
				}
			} 
			
			calOffsetY( _lastIdx );
			calOverLap();
			forceUpdate();
			
			disableBlitMask();
			addMouseDownListener();
		}
		
		override protected function updateHandler( e:Event = null ):void
		{
			//越界，更新面板位置
			var u:Number = ( _target.y + _offsetUY ) / _gapHeight;
			var d:Number = ( _target.y + _offsetDY ) / _gapHeight;
			
			var unit:Sprite;
			var i:int = 0;
			var mvOffsetY:Number = _target.y - _lastY;
			
			var updataIdx:int;
			var downdataIdx:int;
			//上滑移越界
			if( u <= _upIdx )
			{
				for ( i = 0; i <= int(_upIdx - u); i++ )
				{
					_downIdx --;
					if( mvOffsetY < 0 )
					{
						updataIdx = _idx + _lastIdx;
						unit = _unitList.shift();
						unit.visible = ( updataIdx >= 0 && updataIdx < _dataList.length );
						_dataFunc.apply( null, [ unit, updataIdx >= _dataList.length ? null : _dataList[updataIdx] ] );
						unit.y = _unitList[ _unitList.length - 1 ].y + _gapHeight;
						_unitList.push( unit );
						
						_idx ++;
					}
				}
				_upIdx = ( u < 0 ? int(u)-1 : int(u) );
			}
			//下滑移越界
			if( d >= _downIdx )
			{
				for ( i = 0; i <= int(d - _downIdx); i++ )
				{
					_upIdx ++;
					if( mvOffsetY > 0 )
					{
						_idx --;
						
						unit = _unitList.pop();
						unit.visible = ( _idx > 0 && _idx <= _dataList.length );
						_dataFunc.apply( null, [ unit, _idx > 0 ? _dataList[_idx-1] : null ] );
						unit.y = _unitList[0].y - _gapHeight;
						_unitList.unshift( unit );
						
					}
				}
				_downIdx = ( d < 0 ? int(d) : int(d)+1 );
			}
			_lastY = _target.y;
			
			if( _blitMask )
			{
				_blitMask.update();
			}
			updateSideBar();
		}
		
	}
}
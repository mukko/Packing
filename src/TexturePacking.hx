package ;

import TexturePacking.SubTexture;
import flash.geom.Rectangle;
import UInt;
import Math;
import flash.geom.Point;
import flash.display.Shape;
import flash.Lib;

using Lambda;
/**
*true	回転する
*false	回転しない
**/
/** どこにどう配置するか */
typedef Region = {
x:Int, y:Int, width:Int, height:Int, rotated:Bool,
}

/** 敷き詰めるサブテクスチャ */
typedef SubTexture = {
width:Int, height:Int,
}

class TexturePacking
{
	//12個以上だとタイムアウトエラー発生しやすい
	static inline var TEXTURE_NUMBER = 4;
	static inline var MAX_WIDTH = 200;
	static inline var MAX_HEIGHT = 200;
	static inline var DEFAULT_AREA_SIZE = 1000000;
	//書き込み、読み出しはどこからでも可能
	static public var fieldWidth(default, default) = 32;
	static public var fieldHeight(default, default) = 32;
	static public var size(default, default) = 2;

	public function new()
	{
		// 3つのサブテクスチャを作る
		var subTextures = createVariousSubTextures(TEXTURE_NUMBER, MAX_WIDTH, MAX_HEIGHT);
		var regions:Array<Region> = [];
		//高さ順にソート
		sortHeightHigher(subTextures);
		trace(subTextures);
		//var size = 2;
		var s0 = subTextures[0];
		var value:Int = subTextures[0].height;
		if(subTextures[0].height < subTextures[0].width) value = subTextures[0].width;
		size = field_check(size,value);
		trace(size);
		var areas:Array<Rectangle> = [new Rectangle(Math.floor(0), Math.floor(0), size, size)];
		var region:Region = {x:0,y:0,width:s0.width,height:s0.height,rotated:false};
		regions.push(region);
		subTextures.remove(s0);
		var sizes:Array<Int> = make_power_of_two_array(size);
		make_new_rectangle(areas, areas[0], region);
		areas.remove(areas[0]);
		//trace(areas);
		//regions = test_algorithm(subTextures, regions, areas, sizes);
		regions = algorrithm(subTextures, regions, areas, sizes);
		//trace(regions);
		trace(regions);
		trace(size);
		
		drawLine(size, size);

		drawRegions(regions);

	}

	/**
	 * 任意の数のランダムな大きさのサブテクスチャを生成する
	 * @param	numSubTextures 生成するサブテクスチャの数
	 * @param	maxWidth サブテクスチャの最大の幅 [px]
	 * @param	maxHeight サブテクスチャの最大の高さ [px]
	 * @return 生成されたサブテクスチャ集合
	 */

	private static function createVariousSubTextures(numSubTextures:Int, maxWidth:Int, maxHeight:Int):Array<SubTexture>
	{
		return [for (i in 0...numSubTextures)
	{ width : Std.random(maxWidth) + 1, height : Std.random(maxHeight) + 1 } ];
	}

	/**
	 * 複数のサブテクスチャの合計の表面積を算出する
	 * @param	subTextures サブテクスチャの集合
	 * @return 合計の表面積
	 */

	private static function totalSurfaceArea(subTextures:Array<SubTexture>):Int
	{
		return subTextures
		.map(function(s:SubTexture) return s.width * s.height)
		.fold(function(a:Int, b:Int) return a + b, 0);
	}

	/**
	*全サブテクスチャの幅の合計値を算出する
	* @param	subTextures サブテクスチャの集合
	* @return	幅の合計
**/

	private static function totalTextureWidth(subTextures:Array<SubTexture>):Int
	{
		return subTextures.map(function(s:SubTexture) return s.width).fold(function(a:Int, b:Int)return a + b, 0);
	}

	/**
*長方形をソート昇順にソート
* @param	rectangles 長方形の集合
**/

	private static function sortRectHigher(rectangles:Array<Rectangle>):Void
	{
		rectangles.sort(function(a:Rectangle, b:Rectangle) return Math.floor(b.height - a.height));
	}

	/**
	*複数のサブテクスチャを高さの昇順にソートする
	* @param	subTextures サブテクスチャの集合
**/

	private static function sortHeightHigher(subTextures:Array<SubTexture>):Void
	{
		subTextures.sort(function(a:SubTexture, b:SubTexture) return b.height - a.height);
	}

	private static function sort_areaHeightHigher(subTextures:Array<Rectangle>):Void
	{
		subTextures.sort(function(a:Rectangle, b:Rectangle) return Math.floor(b.height - a.height));
	}

	/**
	*複数のサブテクスチャを幅の昇順にソートする
	* @param	subTextures サブテクスチャの集合
**/

	private static function sortWidthHigher(subTextures:Array<SubTexture>):Void
	{
		subTextures.sort(function(a:SubTexture, b:SubTexture) return b.width - a.width);
	}

	/**
	*複数のサブテクスチャの位置を決定し、regionsに突っ込む
	* @param	subTextures サブテクスチャの集合
	* @param	regions 描画する領域の集合
	* @param	fieldHeight 幅の値
	* とりあえず高さをずらしてみている
**/

	private static function configureTexturesheight(subTextures:Array<SubTexture>, regions:Array<Region>, fieldWidth:Int)
	{
		var totalHeight = 0;
		var totalWidth = 0;
		var saveHeight = 0;
		var counter = 0;
		for (i in 0 ... subTextures.length)
		{
			if (totalWidth < fieldWidth)
			{
				regions[i] = {
				x:totalWidth, y:totalHeight, width:subTextures[i].width, height:subTextures[i].height, rotated:false
				}
				totalWidth += regions[i].width;
				if (counter == 0) saveHeight = regions[i].height;
				counter++;
			} else
			{
				totalHeight += saveHeight;
				totalWidth = 0;
				regions[i] = {
				x:totalWidth, y:totalHeight, width:subTextures[i].width, height:subTextures[i].height, rotated:false
				}
				totalWidth = regions[i].width;
				saveHeight = regions[i].height;
				counter = 1;
			}
		}
	}

	/**
	*フィールドに納まらなければ、納まる大きさまでフィールドを拡張するメソッド
	* 拡張する大きさは自分で変えられるように、メソッドを分けた
	* @param	field 幅、もしくは高さ
	* @param	value 入れたいオブジェクトの大きさを足した合計の高さ
**/

	private static function field_check(field:Int, value:Int):Int
	{
		while (field <= value)
		{
			field = field_double_expand(field);
		}
		return field;
	}
	/**
	*二倍した値を返すメソッド
	* 今回はfield_checkの拡張幅を2乗の値にしたかったので
**/

	private static function field_double_expand(field:Int):Int
	{
		return field *= 2;
	}
	/**
	*もっとも近いレベルの大きさを返すメソッド
	*どれも当てはまらなければ-1が返る
**/

	private static function search_nearest_level(levels:Array<Int>, point:Int):Int
	{
		var deg:UInt = 10000;
		var nearest_number:UInt = 0;
		for (level in levels)
		{
			var temp:UInt = level - point;
			if (temp > 0 && temp < deg)
			{
				deg = temp;
				nearest_number = level;
			}
		}
		return nearest_number;
	}
	/**
*配列が空かどうかをチェック
* @param	array サブテクスチャ配列
* @return	あればfalse,無ければtrue
**/

	private static function check_subTextures_empty(array:Array<SubTexture>):Bool
	{
		if (array.length == 0) return true;
		return false;
	}

	/**
	*絶対値を返すメソッド
	* @param	値
	* @rerturn	|値|
**/

	private static function getAbsoluteValue(num:Int):Int
	{
		return num < 0 ? -num : num;
	}

	private static function push_pop_process(subTextures:Array<SubTexture>, regions:Array<Region>, points:Array<Point>, point:Point,
											 sub:SubTexture):Void
	{
		var point_x:UInt = Math.floor(point.x);
		var point_y:UInt = Math.floor(point.y);
		var sub_width:UInt = sub.width;
		var sub_height:UInt = sub.height;
		var region:Region = {x:point_x, y:point_y, width:sub_width, height:sub_height, rotated:false};
		regions.push(region);
		points.remove(point);
		var p_push1:Point = new Point(point_x, point_y + sub_height + 1);
		points.push(p_push1);
		var p_push2:Point = new Point(point_x + sub_width + 1, point_y);
		points.push(p_push2);
		subTextures.remove(sub);
	}

	/**
	* fieldとの面積の差を返す
	* @param	width 幅
	* @param	height 高さ
	* @param	field フィールドとなっている長方形
**/

	private static function calc_gap(width:Int, height:Int, field:Rectangle):Int
	{
		var height_gap:Int = Math.floor(field.height) - height;
		var width_gap:Int = Math.floor(field.width) - width;
		if(height_gap < 0 && width_gap < 0)	return -1;
		else return height_gap * width_gap;
		
	}
	
	/**
	*新たな長方形領域を算出,そして突っ込む
	* @param	areas	長方形領域の集合
	* @param	region	作ったregion
	* @oaram	size	大きさの限界値
**/

	private static function make_new_rectangle(areas:Array<Rectangle>, area:Rectangle, region:Region):Void
	{
		var bottom = region.y + region.height;
		var right = region.x + region.width;
		var rect1:Rectangle;
		var rect2:Rectangle;
		if(region.rotated){
		rect1 = new Rectangle(region.x, region.y, Math.floor(area.width) - region.x, Math.floor(area.height)-region.height);
		rect2 = new Rectangle(bottom, right, Math.floor(area.width)-right, region.width);
		}
		else{
		rect1 = new Rectangle(region.x, bottom, Math.floor(area.width) - region.x, Math.floor(area.height)-region.height);
		rect2 = new Rectangle(right, region.y, Math.floor(area.width) - region.width, region.height);
		}
		areas.push(rect1);
		areas.push(rect2);
	}
	/**
	*areasの上限をsizeの変更に従い変更する
	* @param	areas	長方形領域の集合
	* @param	size	今の大きさ
**/

	private static function change_rect_size(areas:Array<Rectangle>, size:Int):Void
	{
		for (area in areas)
		{
			var value_width:Int = Math.floor(area.x + area.width);
			var value_height:Int = Math.floor(area.y + area.height);
			if (value_width == size) area.width += size;
			if (value_height == size) area.height += size;
		}
	}
	/**
	*値を二倍して返す
	* @param	value	二倍したい値
	* @return	valueを二倍した値
**/
	private static function value_double(value:Int):Int
	{
		return value *= 2;
	}
	/**
	*2のn乗の配列を返す
	* @param	min_size	配列[0]の要素になり、最も小さな値となる
	* @return	2のn乗の値が入った配列
**/
	private static function make_power_of_two_array(min_size:Int):Array<Int>
	{
	 var size_array:Array<Int> = [min_size];
	 var size:Int = min_size;
	 while(true)
	 {
	 	size *= 2;
	 	if(size <=2048) size_array.push(size);
	 	else return size_array;
	 }
	}
	 /**
	 * 再々スタートもう負けない
**/
	private static function algorrithm(subTextures:Array<SubTexture>, regions:Array<Region>, areas:Array<Rectangle>, sizes:Array<Int>
										   ):Array<Region>
	{
	var area_num:Int = 0;
	var sub_num:Int = 0;
	var bool:Bool = false;
	var minimum:Int;
	var region_array:Array<Region> = [];
	var area_array:Array<Rectangle> = [];
	var sub_array:Array<SubTexture> = [];
	
	for(s_num in 0...sizes.length)
	{
		size = sizes[s_num];
		region_array = regions.copy();
		area_array = areas.copy();
		sub_array = subTextures.copy();
		
		sort_areaHeightHigher(area_array);
		minimum = DEFAULT_AREA_SIZE;
		for(a_num in 0...area_array.length)
		{
		var area:Rectangle = area_array[a_num];
		for(s_num in 0...sub_array.length)
		{
		var sub:SubTexture = sub_array[s_num];
		var value:Int = calc_gap(sub.width,sub.height,area);
		if(value > 0 && value < minimum){
		area_num = a_num;
		sub_num = s_num;
		minimum = value;
		bool = false;
		}
		value = calc_gap(sub.height,sub.width,area);
		if(value > 0 && value < minimum){
		area_num = a_num;
		sub_num = s_num;
		minimum = value;
		bool = true;
		}
		}
		}
		if(minimum == DEFAULT_AREA_SIZE){
		}else{
		var area:Rectangle = area_array[area_num];
		var sub:SubTexture = sub_array[sub_num];
		var region:Region = {x:Math.floor(area.x), y:Math.floor(area.y), width:sub.width, height:sub.height, rotated:bool};
		region_array.push(region);
		sub_array.remove(sub);
		area_array.remove(area);
		make_new_rectangle(area_array,area,region);
		}
		if(check_subTextures_empty(sub_array)) break;
		}
		trace("success!");
		return region_array;
	}
	
	/**
	*再スタートしたアルゴリズム
**/
/*
	private static function test_algorithm(subTextures:Array<SubTexture>, regions:Array<Region>, areas:Array<Rectangle>, sizes:Array<Int>
										   ):Array<Region>
	{
		var rect_num:Int = 0;
		var sub_num:Int = 0;
		var bool:Bool = false;
		var minimum;
		var region_array:Array<Region> = [];
		var area_array:Array<Rectangle> = [];
		for(s in sizes)
		{
			size = s;
			var sub_array:Array<SubTexture> = subTextures.copy();
			region_array = regions.copy();
			area_array = areas.copy();
			for(num in 0...sub_array.length)
			{
			sortRectHigher(area_array);
			trace(area_array);
			minimum = DEFAULT_AREA_SIZE;
			for (i in 0...area_array.length)
			{
				var area:Rectangle = area_array[i];
				for (j in 0 ...sub_array.length)
				{
					var sub:SubTexture = sub_array[j];
					var right = area.x + sub.width;
					var bottom = area.y + sub.height;
					var check_w = size - right;
					var check_h = size - bottom;
					var value = calc_gap(sub.width, sub.height, area);
					if (value > 0 && value < minimum && check_w > 0 && check_h > 0)
					{
						rect_num = i;
						sub_num = j;
						minimum = value;
						bool = false;
					}
					right = area.x + sub.height;
					bottom = area.y + sub.width;
					check_w = size - right;
					check_h = size - bottom;
					value = calc_gap(sub.height, sub.width, area);
					if (value > 0 && value < minimum && check_w > 0 && check_h > 0)
					{
						rect_num = i;
						sub_num = j;
						minimum = value;
						bool = true;
					}
				}
			}
			if(minimum != DEFAULT_AREA_SIZE){
				var area:Rectangle = area_array[rect_num];
				var area_x:Int = Math.floor(area.x);
				var area_y:Int = Math.floor(area.y);
				var subtexture = sub_array[sub_num];
				var region:Region;
				region = {x:area_x, y:area_y, width:subtexture.width, height:subtexture.height, rotated:bool};
				region_array.push(region);
				sub_array.remove(subtexture);
				make_new_rectangle(areas, region, size);
				area_array.remove(area);
			}
		}
		if (check_subTextures_empty(sub_array))
			{
				trace("success!!!!");
				break;
			}
	}
	return region_array;
	}
*/
	/**
	 * （確認用）領域をステージ（flash.display.Stage）に描画する
	 * @param	regions 描画する領域の集合
	 */

	private static function drawRegions(regions:Array<Region>):Void
	{
		for (region in regions)
		{
			var shape:Shape = new Shape();
			shape.graphics.lineStyle(0, 0x000000);
			shape.graphics.beginFill(Std.random(0xFFFFFF), 0.2);
			shape.graphics.drawRect(0, 0, region.width, region.height);
			shape.graphics.endFill();
			shape.graphics.lineStyle(0, 0xFF0000);
			shape.graphics.moveTo(0, 0);
			shape.graphics.lineTo(region.width, region.height);
			shape.x = region.x;
			shape.y = region.y;
			shape.graphics.lineTo(region.width, region.height);
			if (region.rotated)
			{
				shape.rotation = 90;
				shape.x = shape.x + shape.width;
			}
			Lib.current.stage.addChild(shape);
		}
	}

	private static function drawLine(width:Int, height:Int)
	{
		var w:Shape = new Shape();
		w.graphics.lineStyle(1, 0x00FF00);
		w.graphics.moveTo(0, height);
		w.graphics.lineTo(width, height);
		var h:Shape = new Shape();
		h.graphics.lineStyle(1, 0x00FF00);
		h.graphics.moveTo(width, 0);
		h.graphics.lineTo(width, height);
		Lib.current.stage.addChild(w);
		Lib.current.stage.addChild(h);
	}
}

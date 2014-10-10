package ;

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
	static inline var TEXTURE_NUMBER = 2;
	static inline var MAX_WIDTH = 100;
	static inline var MAX_HEIGHT = 100;

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
		var size = 2;
		var areas:Array<Rectangle> = [new Rectangle(Math.floor(0), Math.floor(0), Math.floor(2), Math.floor(2))];
		regions = test_algorithm(subTextures, regions, areas, size);
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
	*実装したアルゴリズム
**/

	private static function tomo_algorithm(subTextures:Array<SubTexture>, regions:Array<Region>, points:Array<Point>,
										   level_width:Array<Int>, level_height:Array<Int>):Void
	{
		var points = points.copy();
		while (check_subTextures_empty(subTextures) == true)
		{
			//入るとき用変数たち
			var level_num:UInt = 0;
			var minimum:Int = 1000;
			var min_point:Point = new Point(0, 0);
			var min_sub:SubTexture = {width:0, height:0};
			//入らないとき用変数たち
			var out_number:UInt = 0;
			var out_minimum:UInt = 100000;
			var out_point:Point = new Point(0, 0);
			var out_sub:SubTexture = {width:0, height:0};

			for (i in 0...points.length)
			{
				var point:Point = points[i];
				var px:UInt = Math.floor(point.x);
				var py:UInt = Math.floor(point.y);
				//もっとも近いレベルを保持
				var level_h:Int = search_nearest_level(level_height, py);
				var level_w:Int = search_nearest_level(level_width, px);
				var dw:Int;
				var dh:Int;
				for (j in 0...subTextures.length)
				{
					var st:SubTexture = subTextures[j];
					dw = level_w - px - st.width;
					dh = level_h - py - st.height;
					if (dw > 0 && dh > 0 && dh < minimum)
					{
						minimum = dh;
						min_point = point;
						min_sub = st;
					} else if ((dw < 0 && dh > 0) || (dw > 0 && dh < 0) || (dw < 0 && dh < 0))
					{
						var dimention:UInt = getAbsoluteValue(dw * dh);
						if (dimention < out_minimum)
						{
							out_minimum = dimention;
							out_point = point;
							out_sub = st;
						}
					}
				}
			}
			if (minimum == 1000)
			{
				var check_w:Int = Math.floor(out_point.x + out_sub.width);
				var check_h:Int = Math.floor(out_point.y + out_sub.height);
				fieldWidth = field_check(fieldWidth, check_w);
				fieldHeight = field_check(fieldHeight, check_h);
				level_width.pop();
				level_width.push(fieldWidth);
				level_height.remove(level_height[0]);
				level_height.insert(0, fieldHeight);
			} else
			{
				level_height.push(Math.floor(min_point.y + min_sub.height));
				push_pop_process(subTextures, regions, points, min_point, min_sub);
			}
		}
	}

	/**
	* fieldとの面積の差を返す
	* @param	width 幅
	* @param	height 高さ
	* @param	field フィールドとなっている長方形
**/

	private static function calc_gap(width:Int, height:Int, field:Rectangle):Int
	{
		return Math.floor((field.width * field.height) - (width * height));
	}
	/**
	*新たな長方形領域を算出,そして突っ込む
	* @param	areas	長方形領域の集合
	* @param	rect	使った長方形
	* @oaram	size	大きさの限界値
**/

	private static function make_new_rectangle(areas:Array<Rectangle>, rect:Rectangle, size:Int):Void
	{
		var ry = rect.y + rect.height;
		var rx = rect.x + rect.width;
		var rect1:Rectangle = new Rectangle(rect.x, ry, size - rx, size - ry);
		var rect2:Rectangle = new Rectangle(rx, rect.y, size - rx, size - ry);
		areas.push(rect1);
		areas.push(rect2);
		areas.remove(rect);
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
			if (value_width == size) area.width = size * 2 - area.x;
			if (value_height == size) area.height = size * 2 - area.y;
		}
	}

	/**
	*再スタートしたアルゴリズム
**/

	private static function test_algorithm(subTextures:Array<SubTexture>, regions:Array<Region>, areas:Array<Rectangle>,
										   size:Int):Array<Region>
	{
		var rect_num:Int;
		var sub_num:Int = 0;
		var bool:Bool = false;
		var minimum:Int;
		while (true)
		{
			sortRectHigher(areas);
			trace(size);
			rect_num = 0;
			minimum = 1000000;
			for (i in 0...areas.length)
			{
				var area:Rectangle = areas[i];
				for (j in 0 ...subTextures.length)
				{
					var sub:SubTexture = subTextures[j];
					var value:Int = calc_gap(sub.width, sub.height, area);
					if (value > 0 && value < minimum)
					{
						rect_num = i;
						sub_num = j;
						minimum = value;
						bool = false;
					}
					value = calc_gap(sub.height, sub.height, area);
					if (value > 0 && value < minimum)
					{
						rect_num = i;
						sub_num = j;
						minimum = value;
						bool = true;
					}
				}
			}
			if (minimum == 1000000)
			{
				change_rect_size(areas, size);
				trace(areas);
				//ここでsizeの変更をすると0になってしまう
				size *= 2;
			} else
			{
				var area:Rectangle = areas[rect_num];
				var area_x:Int = Math.floor(area.x);
				var area_y:Int = Math.floor(area.y);
				var subtexture = subTextures[sub_num];
				var region:Region;
				region = {x:area_x, y:area_y, width:subtexture.width, height:subtexture.height, rotated:bool};
				regions.push(region);
				subTextures.remove(subtexture);
				make_new_rectangle(areas, area, size);
				trace(subTextures);
			}
			if (check_subTextures_empty(subTextures))
			{
				trace("success!!!!");
				return regions;
			}
		}
	}

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

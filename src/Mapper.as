/*

   Auto Mapper v0.4

   1- Create basic texture from vector
   2- generate normal , speculare, occlusion from bitmap

   Code by LoTh
   3dflashlo@gmail.com - http://3dflashlo.wordpress.com/

   Pixel bender filter: Jan-C.F, S.Kimura

 */
package {
    import flash.filters.DisplacementMapFilter;
    import away3d.textures.BitmapCubeTexture;
    import flash.display.DisplayObject;
    import flash.filters.ShaderFilter;
    import flash.geom.ColorTransform;
    import flash.display.BitmapData;
    import flash.display.Bitmap;
    import flash.display.Shader;
    import flash.display.Sprite;
    import flash.geom.Matrix;
    import flash.geom.Point;
    
    public class Mapper extends Sprite {
        [Embed(source="/../embeds/filters/sharpen.pbj",mimeType="application/octet-stream")]
        private var BumpClass:Class;
        [Embed(source="/../embeds/filters/NormalMap.pbj",mimeType="application/octet-stream")]
        private var NormalClass:Class;
        [Embed(source="/../embeds/filters/Outline.pbj",mimeType="application/octet-stream")]
        private var LumaClass:Class;
        
        private var _shaders:Vector.<Shader>;
        private var _bitmap:Vector.<Bitmap>;
        private var _bitdata:Vector.<BitmapData>;
        private var _skydata:Vector.<BitmapData>;
        private var _sky:BitmapCubeTexture;
        
        public function Mapper() {
        }
        
        //--------------------------------------------------------------------- AUTO MAP
        
        /**
         * auto mapper (normal, speculare, occlusion)
         */
        public function AutoMapper(origineMap:BitmapData=null):void {
            _shaders = new Vector.<Shader>();
            _bitmap = new Vector.<Bitmap>();
            _bitdata = new Vector.<BitmapData>();
            _bitmap.push(new Bitmap(origineMap), new Bitmap(origineMap), new Bitmap(origineMap))
            _shaders.push(new Shader(new BumpClass()), new Shader(new NormalClass()), new Shader(new LumaClass()))
            applyFilters();
        }
        
        /**
         * apply filters
         */
        private function applyFilters():void {
            // Bump
            _shaders[0].data.amount.value = [20];
            _shaders[0].data.radius.value = [.1];
            _bitmap[0].filters = [new ShaderFilter(_shaders[0])];
            // Normal
            _shaders[1].data.amount.value = [10]; //0 to 5
            _shaders[1].data.soft_sobel.value = [1]; //int 0 or 1
            _shaders[1].data.invert_red.value = [-1]; //-1 to 1
            _shaders[1].data.invert_green.value = [-1]; //-1 to 1
            _bitmap[1].filters = [new ShaderFilter(_shaders[1])];
            // Speculare
            /*_shaders[2].data.difference.value = [1,0.15];
               _shaders[2].data.color.value = [1,1,1,1];
               _shaders[2].data.bgcolor.value = [0, 0, 0, 1];
             */
            _shaders[2].data.difference.value = [1, 0.5];
            _shaders[2].data.color.value = [1, 1, 1, 1];
            _shaders[2].data.bgcolor.value = [0, 0, 0, 1];
            _bitmap[2].filters = [new ShaderFilter(_shaders[2])];
            
            _bitdata.push(bit(_bitmap[0]), bit(_bitmap[1]), bit(_bitmap[2]))
        }
        
        /**
         * get bitmapData
         */
        private function bit(B:Bitmap):BitmapData {
            var b:BitmapData = new BitmapData(B.width, B.height, true);
            b.draw(B);
            return b;
        }
        
        /**
         * return map
         */
        public function get bitdata():Vector.<BitmapData> {
            return _bitdata;
        }
        
        //--------------------------------------------------------------------- VECTOR SKY
        
        /**
         * create vector sky
         */
        public function vectorSky(COLOR:Array, quality:uint=8):void {
            var xl:uint = 128 * quality;
            var pinch:uint = xl / 3.6;
            // sky color from bottom to top;
            var color:Array = [brighten(COLOR[0], 50), darken(COLOR[0], 25), darken(COLOR[0], 5), darken(COLOR[1], 0), COLOR[1], COLOR[2], darken(COLOR[2], 25), darken(COLOR[2], 50)]; // clear
            var side:BitmapData = new BitmapData(xl, xl, false, color[1]);
            var top:BitmapData = new BitmapData(xl, xl, false, color[6]);
            var floor:BitmapData = new BitmapData(xl, xl, false, color[1]);
            // side
            var matrix:Matrix = new Matrix();
            matrix.createGradientBox(xl, xl, -Math.PI / 2)
            var g:Sprite = new Sprite();
            g.graphics.beginGradientFill('linear', [color[1], color[2], color[3], color[4], color[5], color[6]], [1, 1, 1, 1, 1, 1], [90, 110, 120, 126, 180, 230], matrix);
            g.graphics.drawRect(0, 0, xl, xl);
            g.graphics.endFill();
            var displacement_map:DisplacementMapFilter = new DisplacementMapFilter(pinchMap(xl, xl), new Point(0, 0), 4, 2, 0, pinch, "clamp")
            g.filters = [displacement_map];
            //g.addChild(_bitmap[2])
            side.draw(g);
            // top
            g = new Sprite;
            matrix = new Matrix();
            matrix.createGradientBox(xl, xl, 0, 0, 0);
            g.graphics.beginGradientFill('radial', [color[7], color[6]], [1, 1], [0, 255], matrix);
            g.graphics.drawEllipse(0, 0, xl, xl);
            g.graphics.endFill();
            
            top.draw(g);
            // bottom
            g = new Sprite;
            matrix = new Matrix();
            matrix.createGradientBox(xl, xl, 0, 0, 0);
            g.graphics.beginGradientFill('radial', [color[0], color[1]], [1, 1], [0, 255], matrix);
            g.graphics.drawEllipse(0, 0, xl, xl);
            g.graphics.endFill();
            floor.draw(g);
            
            _skydata = new Vector.<BitmapData>();
            _skydata.push(side, top, floor);
            if (_sky)
                _sky.dispose();
            _sky = new BitmapCubeTexture(side, side, top, floor, side, side);
        }
        
        /**
         * add sphericale distortion
         */
        private function pinchMap(w:int, h:int):BitmapData {
            var b:BitmapData = new BitmapData(w, h, false, 0x000000)
            var vx:int = w >> 1;
            var vy:int = h >> 1;
            for (var j:int = 0; j < h; j++) {
                for (var i:int = 0; i < w; i++) {
                    var BCol:Number = 127 + (i - vx) / (vx) * 127 * (1 - Math.pow((j - vy) / (vy), 2))
                    var GCol:Number = 127 + (j - vy) / (vy) * 127 * (1 - Math.pow((i - vx) / (vx), 2))
                    b.setPixel(i, j, (GCol << 8) | BCol)
                }
            }
            return b
        }
        
        /**
         * sky reference
         */
        public function get sky():BitmapCubeTexture {
            return _sky;
        }
        
        //--------------------------------------------------------------------- COLORS UTILS
        
        /**
         * brighten color
         */
        public function brighten(hexColor:Number, percent:Number):Number {
            if (isNaN(percent))
                percent = 0;
            if (percent > 100)
                percent = 100;
            if (percent < 0)
                percent = 0;
            var factor:Number = percent / 100, rgb:Object = hexToRgb(hexColor);
            rgb.r += (255 - rgb.r) * factor;
            rgb.b += (255 - rgb.b) * factor;
            rgb.g += (255 - rgb.g) * factor;
            return rgbToHex(Math.round(rgb.r), Math.round(rgb.g), Math.round(rgb.b));
        }
        
        /**
         * darken color
         */
        public function darken(hexColor:Number, percent:Number):Number {
            if (isNaN(percent))
                percent = 0;
            if (percent > 100)
                percent = 100;
            if (percent < 0)
                percent = 0;
            var factor:Number = 1 - (percent / 100), rgb:Object = hexToRgb(hexColor);
            rgb.r *= factor;
            rgb.b *= factor;
            rgb.g *= factor;
            return rgbToHex(Math.round(rgb.r), Math.round(rgb.g), Math.round(rgb.b));
        }
        
        /**
         * conversion
         */
        public function rgbToHex(r:Number, g:Number, b:Number):Number {
            return (r << 16 | g << 8 | b);
        }
        
        public function hexToRgb(hex:Number):Object {
            return {r: (hex & 0xff0000) >> 16, g: (hex & 0x00ff00) >> 8, b: hex & 0x0000ff};
        }
        
        /**
         * apply color to object
         */
        public function color(o:DisplayObject, c:int=0, a:Number=1):void {
            if (o) {
                var nc:ColorTransform = o.transform.colorTransform
                nc.color = c;
                nc.alphaMultiplier = a;
                if (c == 0)
                    o.transform.colorTransform = new ColorTransform()
                else
                    o.transform.colorTransform = nc
            }
        }
        
        //--------------------------------------------------------------------- MATH UTILS
        
        /**
         * random generator
         */
        private function Ran(max:Number=1, min:Number=0):Number {
            return Math.floor(Math.random() * (max - min + 1)) + min;
        }
    
    }
}
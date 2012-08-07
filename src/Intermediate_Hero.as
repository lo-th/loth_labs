/*

   AWD file loading example in Away3d

   Demonstrates:

   How to use the Loader3D object to load an embedded internal awd model.
   How to create character interaction
   How to set custom material on a model.

   Code, model and map by LoTh
   3dflashlo@gmail.com - http://3dflashlo.wordpress.com/

   Code reference https://github.com/away3d/away3d-examples-fp11/
   Intermediate_CharacterAnimation.as by Rob Bateman

   This code is distributed under the MIT License

   Copyright (c)

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the “Software”), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.

 */
package {
    import away3d.animators.transitions.CrossfadeStateTransition;
    import away3d.animators.SkeletonAnimationState;
    import away3d.animators.SkeletonAnimationSet;
    import away3d.animators.SkeletonAnimator;
    import away3d.animators.data.Skeleton;
    import away3d.lights.shadowmaps.NearDirectionalShadowMapper;
    import away3d.materials.methods.FilteredShadowMapMethod;
    import away3d.materials.methods.NearShadowMapMethod;
    import away3d.utils.Cast;
    
    import away3d.entities.Mesh;
    import away3d.debug.AwayStats;
    import away3d.primitives.SkyBox;
    import away3d.lights.LightBase;
    import away3d.loaders.Loader3D;
    import away3d.lights.LightProbe;
    import away3d.lights.PointLight;
    import away3d.events.LoaderEvent;
    import away3d.containers.View3D;
    import away3d.events.AssetEvent;
    import away3d.core.base.Geometry;
    import away3d.events.MouseEvent3D;
    import away3d.library.AssetLibrary;
    import away3d.materials.LightSources;
    import away3d.textures.BitmapTexture;
    import away3d.materials.ColorMaterial;
    import away3d.lights.DirectionalLight;
    import away3d.library.assets.AssetType;
    import away3d.loaders.parsers.AWD2Parser;
    import away3d.materials.methods.FogMethod;
    import away3d.materials.methods.EnvMapMethod;
    import away3d.materials.methods.LightMapMethod;
    import away3d.materials.methods.FresnelSpecularMethod;
    import away3d.materials.methods.TripleFilteredShadowMapMethod;
    import away3d.materials.lightpickers.StaticLightPicker;
    import away3d.cameras.lenses.PerspectiveLens;
    import away3d.materials.DefaultMaterialBase;
    import away3d.controllers.HoverController;
    import away3d.materials.TextureMaterial;
    import away3d.primitives.SphereGeometry;
    import away3d.primitives.PlaneGeometry;
    
    import flash.filters.DropShadowFilter;
    import flash.display.StageScaleMode;
    import flash.display.StageQuality;
    import flash.events.KeyboardEvent;
    import flash.display.BitmapData;
    import flash.display.StageAlign;
    import flash.display.MovieClip;
    import flash.events.MouseEvent;
    import flash.text.TextFormat;
    import flash.text.TextField;
    import flash.display.LoaderInfo;
    import flash.display.Bitmap;
    import flash.display.Loader;
    import flash.display.Sprite;
    import flash.geom.Vector3D;
    import flash.events.Event;
    import flash.geom.Matrix;
    import flash.ui.Keyboard;
    import flash.net.URLRequest;
    import flash.display.DisplayObject;
    import flash.events.ProgressEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    
    [SWF(backgroundColor="#333338",frameRate="60",quality="LOW",width="1600",height="768")]
    
    public class Intermediate_Hero extends Sprite {
        private var _signature:Bitmap;
        // demo color [ light color 1, light color 2, sky color, ground color]
        private var DemoColor:Array = [0xAAAAA9, 0x333338, 0x445465, 0x333338];
        private var DemoAmbiant:Array = [0.4, 0.2];
        private var DemoDiffuse:Array = [1, 0.5];
        private var DemoSpecular:Array = [1, 0.5];
        
        // mapping
        private const referenceMap:Array = ['onkba_N.png', 'onkba_NORM.jpg', 'onkba_OCL.jpg', 'gun_N.jpg', 'gun_NORM.jpg', 'gun_OCL.jpg', 'floor_N.jpg', 'floor_NORM.jpg', 'floor_OCL.jpg'];
        private var _mapList:Vector.<BitmapData>;
        private var n:Number = 0;
        
        //engine variables
        private var _view:View3D;
        private var _stats:AwayStats;
        private var _lightPicker:StaticLightPicker;
        private var _hoverCtrl:HoverController;
        private var _skyBox:SkyBox;
        
        //referency
        private var _materials:Vector.<DefaultMaterialBase>;
        private var _light:Array;
        
        //animation variables
        private var stateTransition:CrossfadeStateTransition = new CrossfadeStateTransition(0.5);
        private var animator:SkeletonAnimator;
        private var animationSet:SkeletonAnimationSet;
        private var currentRotationInc:Number = 0;
        private var movementDirection:Number;
        private var isRunning:Boolean;
        private var isMoving:Boolean;
        private var isJumping:Boolean;
        private var currentAnim:String;
        
        //animation constants
        private const ANIM_BREATHE:String = "Breathe";
        private const ANIM_WALK:String = "Walk";
        private const ANIM_RUN:String = "Run";
        private const ANIM_JUMP:String = "Jump";
        private const ANIM_FIGHT:String = "Fight";
        private const ANIM_BOXE:String = "Boxe";
        private const XFADE_TIME:Number = 0.5;
        private const ROTATION_SPEED:Number = 3;
        private const RUN_SPEED:Number = 2;
        private const WALK_SPEED:Number = 1;
        private const BREATHE_SPEED:Number = 1;
        private const JUMP_SPEED:Number = 1;
        private const BOXE_SPEED:Number = 1.6;
        private const FIGHT_SPEED:Number = 1.5;
        
        //scene objects
        private var hero:Mesh;
        private var gun:Mesh;
        private var ground:Mesh;
        
        //advanced eye 
        private var _heroPieces:Mesh;
        private var _eyes:Mesh;
        private var _eyeL:Mesh;
        private var _eyeR:Mesh;
        private var _eyesTarget:Mesh;
        private var _eyeCount:int = 0;
        private var _eyeMapClose:ColorMaterial;
        private var _eyeMapOpen:TextureMaterial;
        private var _eyeLook:Mesh;
        
        //navigation
        private var _prevMouseX:Number;
        private var _prevMouseY:Number;
        private var _mouseMove:Boolean;
        private var _cameraHeight:Number = 0;
        
        private var _eyePosition:Vector3D;
        private var cloneActif:Boolean = false;
        private var _mapper:Mapper;
        private var _text:TextField;
        
        private var _fog:FogMethod;
        private var _fog2:FogMethod;
        private var _reflect:EnvMapMethod;
        private var _specularMethod:FresnelSpecularMethod;
        private var _shadowMethod:NearShadowMapMethod;
        
        /**
         * Constructor
         */
        public function Intermediate_Hero() {
            if (stage)
                init();
            else
                addEventListener(Event.ADDED_TO_STAGE, init, false, 0, true);
        }
        
        /**
         * Global initialise function
         */
        private function init():void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            initEngine();
            initText();
            initLights();
            initListeners();
            
            // start by loading all bitmap
            _mapList = new Vector.<BitmapData>();
            load('assets/' + referenceMap[n]);
        }
        
        //--------------------------------------------------------------------- ENGINE
        
        /**
         * Initialise the engine
         */
        private function initEngine():void {
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            _view = new View3D();
            //_view.antiAlias = 4;
            _view.backgroundColor = DemoColor[3];
            
            _view.camera.lens = new PerspectiveLens(70);
            _view.camera.lens.far = 30000;
            _view.camera.lens.near = 1;
            
            _hoverCtrl = new HoverController(_view.camera, null, 180, 0, 1000, 10, 90);
            _hoverCtrl.tiltAngle = 0;
            _hoverCtrl.panAngle = 180;
            _hoverCtrl.minTiltAngle = -60;
            _hoverCtrl.maxTiltAngle = 60;
            _hoverCtrl.autoUpdate = false;
            
            addChild(_view);
            
            //away3d stat
            _stats = new AwayStats(_view, true, true);
            addChild(_stats);
            
            //material reference
            _materials = new Vector.<DefaultMaterialBase>();
            //light referency
            _light = [];
            
            //auto map generator
            _mapper = new Mapper();
        }
        
        //--------------------------------------------------------------------- LOOP
        
        /**
         * Render loop
         */
        private function onEnterFrame(event:Event):void {
            //update character animation
            if (hero) {
                hero.rotationY += currentRotationInc;
                updateEye();
                _hoverCtrl.lookAtPosition = new Vector3D(hero.x, _cameraHeight, hero.z);
            }
            //update camera controler
            _hoverCtrl.update();
            //update light
            _light[1].position = _view.camera.position;
            //update view
            _view.render();
        }
        
        //--------------------------------------------------------------------- LISTENER
        
        /**
         * Initialise the listeners
         */
        private function initListeners():void {
            //add render loop
            addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
            //add key listeners
            stage.addEventListener(KeyboardEvent.KEY_UP, onKeyUp, false, 0, true);
            stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown, false, 0, true);
            //navigation
            stage.addEventListener(MouseEvent.MOUSE_DOWN, onStageMouseDown, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_MOVE, onStageMouseMove, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_UP, onStageMouseLeave, false, 0, true);
            stage.addEventListener(MouseEvent.MOUSE_WHEEL, onStageMouseWheel, false, 0, true)
            stage.addEventListener(Event.MOUSE_LEAVE, onStageMouseLeave, false, 0, true);
            //add resize event
            stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
            onResize();
        }
        
        //--------------------------------------------------------------------- LIGHT
        
        /**
         * Initialise the lights
         */
        private function initLights():void {
            //create a light for shadows that mimics the sun's position in the skybox
            var sun:DirectionalLight = new DirectionalLight(-0.5, -1, 0.3);
            sun.castsShadows = true;
            sun.shadowMapper = new NearDirectionalShadowMapper(.1);
            _view.scene.addChild(sun);
            _light.push(sun);
            //create a light for ambient effect that mimics the sky
            var moon:PointLight = new PointLight();
            moon.y = 500;
            moon.radius = 1000;
            moon.fallOff = 2500;
            _view.scene.addChild(moon);
            _light.push(moon);
            makeSky();
        }
        
        //--------------------------------------------------------------------- SKY
        
        /**
         * sky change
         */
        private function randomSky():void {
            DemoColor = [0xFFFFFF * Math.random(), 0xFFFFFF * Math.random(), 0xFFFFFF * Math.random(), 0xFFFFFF * Math.random()];
            DemoAmbiant = [0.4, 0.3];
            DemoAmbiant = [Math.random(), Math.random()];
            DemoDiffuse = [Math.random(), Math.random()];
            DemoSpecular = [Math.random() * 4, Math.random() * 2];
            makeSky();
        }
        
        private function makeSky():void {
            if (_light[2]) {
                _view.scene.removeChild(_light[2]);
                _light.pop();
            }
            if (_skyBox) {
                _view.scene.removeChild(_skyBox);
                _skyBox.dispose();
            }
            //generate vector degrade sky
            _mapper.vectorSky([DemoColor[3], DemoColor[3], DemoColor[2]], 8);
            _skyBox = new SkyBox(_mapper.sky);
            _view.scene.addChild(_skyBox);
            //add new probe light
            var probe:LightProbe = new LightProbe(_mapper.sky);
            _view.scene.addChild(probe);
            _light.push(probe);
            
            _light[0].color = DemoColor[0];
            _light[0].ambient = DemoAmbiant[0];
            _light[0].diffuse = DemoDiffuse[0];
            _light[0].specular = DemoSpecular[0];
            _light[0].ambientColor = DemoColor[0];
            
            _light[1].color = DemoColor[1];
            _light[1].ambient = DemoAmbiant[1];
            _light[1].diffuse = DemoDiffuse[1];
            _light[1].specular = DemoSpecular[1];
            _light[1].ambientColor = DemoColor[1];
            
            _lightPicker = new StaticLightPicker(_light);
            
            for each (var o:DefaultMaterialBase in _materials) {
                if (o.name == 'ground') {
                    o.removeMethod(_fog);
                    o.removeMethod(_reflect);
                    _fog = new FogMethod(1000, 10000, DemoColor[3]);
                    //_reflect = new EnvMapMethod(_mapper.sky, 0.5)
                    o.addMethod(_fog);
                        //o.addMethod(_reflect);
                }
                o.lightPicker = _lightPicker;
            }
        }
        
        //--------------------------------------------------------------------- MATERIAL
        
        /**
         * Initialise the material
         */
        protected function initMaterial():void {
            log('humm')
            
            //global methode
            // _fog = new FogMethod(1000, 10000, DemoColor[3]);
            _fog = new FogMethod(0, _view.camera.lens.far, DemoColor[3]);
            // _fog2 = new FogMethod(1000, 10000, DemoColor[3]);
            _reflect = new EnvMapMethod(_mapper.sky, 0.5)
            _specularMethod = new FresnelSpecularMethod();
            _specularMethod.normalReflectance = 1.5;
            // _shadowMethod = new TripleFilteredShadowMapMethod(DirectionalLight(_light[0]));
            
            _shadowMethod = new NearShadowMapMethod(new FilteredShadowMapMethod(_light[0]));
            _shadowMethod.epsilon = .0007;
            
            var material:DefaultMaterialBase;
            
            // 0 - ground
            material = materialFromBitmap('ground', [_mapList[6], _mapList[7], _mapList[8]], true)
            // material = materialFromBitmap('ground', [_mapList[6]],true)
            material.ambient = 1;
            material.gloss = 30;
            material.specular = 1;
            material.repeat = true;
            material.addMethod(_fog);
            // 1 - Hero
            material = materialFromBitmap('hero', [_mapList[0], _mapList[1], _mapList[2]])
            material.gloss = 16;
            material.specular = 0.6;
            material.ambient = 1;
            //transparency
            material.alphaPremultiplied = true;
            material.alphaThreshold = 0.9;
            // 2 - gun
            material = materialFromBitmap('gun', [_mapList[3], _mapList[4], _mapList[5]])
            material.gloss = 16;
            material.specular = 0.6;
            material.ambient = 1;
            
            initObjects();
        }
        
        /**
         * Material from bitmap
         */
        protected function materialFromBitmap(name:String, Bitmaps:Array, Spec:Boolean=false):DefaultMaterialBase {
            // auto map if one bitmap
            if (Bitmaps.length == 1) {
                _mapper.AutoMapper(Bitmaps[0]);
                Bitmaps.push(_mapper.bitdata[1]);
                Bitmaps.push(_mapper.bitdata[0]);
            }
            var material:TextureMaterial = new TextureMaterial(new BitmapTexture(Bitmaps[0]));
            //  material.normalMap = new BitmapTexture(Bitmaps[1]);
            
            material.normalMap = Cast.bitmapTexture(Bitmaps[1]);
            //bodyMaterial.normalMap = Cast.bitmapTexture(BodyNormals);
            if (Spec)
                material.specularMap = new BitmapTexture(Bitmaps[2]);
            else
                material.addMethod(new LightMapMethod(new BitmapTexture(Bitmaps[2])));
            
            material.name = name;
            material.lightPicker = _lightPicker;
            //material.diffuseLightSources = LightSources.PROBES;
            material.specularLightSources = LightSources.LIGHTS;
            material.specularMethod = _specularMethod;
            material.shadowMethod = _shadowMethod;
            
            //push to reference
            _materials.push(material);
            return material;
        }
        
        /**
         * Initialise the scene objects
         */
        private function initObjects():void {
            ground = new Mesh(new PlaneGeometry(100000, 100000), _materials[0]);
            ground.geometry.scaleUV(160, 160);
            ground.y = -480;
            ground.castsShadows = false;
            _view.scene.addChild(ground);
            
            load("assets/onkba.awd");
        }
        
        //--------------------------------------------------------------------- GLOBAL LOADER
        
        /**
         * Global Load Binary file
         */
        private function load(url:String):void {
            var loader:URLLoader = new URLLoader();
            loader.dataFormat = URLLoaderDataFormat.BINARY;
            switch (url.substring(url.length - 3)) {
                case "AWD": 
                case "awd": 
                    loader.addEventListener(Event.COMPLETE, parseAWD, false, 0, true);
                    break;
                case "png": 
                case "jpg": 
                    loader.addEventListener(Event.COMPLETE, parseBitmap);
                    break;
            }
            loader.addEventListener(ProgressEvent.PROGRESS, loadProgress, false, 0, true);
            loader.load(new URLRequest(url));
        }
        
        /**
         * Display current load
         */
        private function loadProgress(e:ProgressEvent):void {
            var P:int = int(e.bytesLoaded / e.bytesTotal * 100);
            if (P != 100)
                log('Load : ' + P + ' % | ' + int((e.bytesLoaded / 1024) << 0) + ' ko\n');
            else
                message();
        }
        
        //--------------------------------------------------------------------- BITMAP DISPLAY
        
        private function parseBitmap(e:Event):void {
            log("out")
            var urlLoader:URLLoader = e.target as URLLoader;
            var loader:Loader = new Loader();
            loader.loadBytes(urlLoader.data);
            loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onBitmapComplete, false, 0, true);
            urlLoader.removeEventListener(Event.COMPLETE, parseBitmap);
            urlLoader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
            loader = null;
        }
        
        private function onBitmapComplete(e:Event):void {
            var loader:Loader = LoaderInfo(e.target).loader;
            loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onBitmapComplete);
            _mapList.push(e.target.content.bitmapData);
            loader.unload();
            loader = null;
            n++;
            if (referenceMap[n])
                load('assets/' + referenceMap[n]);
            else {
                initMaterial();
            }
        }
        
        //--------------------------------------------------------------------- AWD DISPLAY
        
        /**
         * Load AWD
         */
        private function parseAWD(e:Event):void {
            var loader:URLLoader = e.target as URLLoader
            var loader3d:Loader3D = new Loader3D(false);
            loader3d.addEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete, false, 0, true);
            loader3d.addEventListener(LoaderEvent.RESOURCE_COMPLETE, finalAWD, false, 0, true);
            loader3d.loadData(loader.data, null, null, new AWD2Parser());
            loader.removeEventListener(ProgressEvent.PROGRESS, loadProgress);
            loader.removeEventListener(Event.COMPLETE, parseAWD);
            loader = null;
        }
        
        /**
         * Listener function for asset complete event on loader
         */
        private function onAssetComplete(event:AssetEvent):void {
            var mesh:Mesh;
            var material:TextureMaterial;
            var specularMethod:FresnelSpecularMethod
            
            if (event.asset.assetType == AssetType.SKELETON) {
                //create a new skeleton animation set
                animationSet = new SkeletonAnimationSet(3);
                //wrap our skeleton animation set in an animator object and add our sequence objects
                animator = new SkeletonAnimator(animationSet, event.asset as Skeleton, true);
                
            } else if (event.asset.assetType == AssetType.ANIMATION_STATE) {
                //create state objects for each animation state encountered
                var animationState:SkeletonAnimationState = event.asset as SkeletonAnimationState;
                animationSet.addState(animationState.name, animationState);
                    //if (animationState.name == ANIM_BREATHE) stop();
            } else if (event.asset.assetType == AssetType.MESH) {
                
                mesh = Mesh(event.asset)
                
                if (mesh) {
                    if (mesh.name == "Onkba") {
                        hero = mesh;
                        hero.material = _materials[1];
                        hero.castsShadows = true;
                        hero.scale(10);
                    }
                    if (mesh.name == "Gun") {
                        gun = mesh;
                        gun.material = _materials[2];
                        gun.castsShadows = true;
                        gun.scale(10);
                        gun.z = -250;
                        gun.y = -470;
                        gun.rotationY = 0;
                        gun.rotationX = 0;
                    }
                    
                }
            }
        }
        
        /**
         * Check if all resourse loaded
         */
        private function finalAWD(e:LoaderEvent):void {
            //apply our animator to our mesh
            hero.animator = animator;
            //add dynamique eyes
            addHeroEye(10);
            //default to breathe sequence
            stop();
            
            var loader3d:Loader3D = e.target as Loader3D;
            loader3d.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
            loader3d.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, finalAWD);
            
            _view.scene.addChild(hero);
            _view.scene.addChild(gun);
        }
        
        /**
         * Test some Clone
         */
        private function makeClone(n:int=20):void {
            if (!cloneActif) {
                cloneActif = true;
                var g:Mesh;
                var decal:int = -(n * 400) / 2;
                for (var j:int = 1; j < n; j++) {
                    for (var i:int = 1; i < n; i++) {
                        g = Mesh(hero.clone());
                        g.x = decal + (400 * i);
                        g.z = (decal + (400 * j));
                        if (g.x != 0 || g.z != 0)
                            _view.scene.addChild(g);
                    }
                }
            }
        }
        
        /**
         * Character breath animation
         */
        private function stop():void {
            isMoving = false;
            //update animator speed
            animator.playbackSpeed = BREATHE_SPEED;
            //update animator sequence
            if (currentAnim == ANIM_BREATHE)
                return;
            currentAnim = ANIM_BREATHE;
            animator.play(currentAnim, stateTransition);
        }
        
        /**
         * Character fight animation
         */
        private function fight():void {
            //update animator sequence
            if (currentAnim == ANIM_FIGHT) {
                return;
            }
            animator.playbackSpeed = FIGHT_SPEED;
            currentAnim = ANIM_FIGHT;
            animator.play(currentAnim, stateTransition);
        }
        
        /**
         * Character fight animation
         */
        private function fight2():void {
            //update animator sequence
            if (currentAnim == ANIM_BOXE) {
                return;
            }
            animator.playbackSpeed = BOXE_SPEED;
            currentAnim = ANIM_BOXE;
            animator.play(currentAnim, stateTransition);
        }
        
        /**
         * Character jump animation
         */
        private function jump():void {
            isJumping = false;
        }
        
        /**
         * Character Mouvement
         */
        private function updateMovement(dir:Number):void {
            isMoving = true;
            //update animator speed
            animator.playbackSpeed = dir * (isRunning ? RUN_SPEED : WALK_SPEED);
            //update animator sequence
            var anim:String = isRunning ? ANIM_RUN : ANIM_WALK;
            if (currentAnim == anim)
                return;
            currentAnim = anim;
            animator.play(currentAnim, stateTransition);
        }
        
        //--------------------------------------------------------------------- KEYBORD
        
        /**
         * Key down listener for animation
         */
        private function onKeyDown(event:KeyboardEvent):void {
            switch (event.keyCode) {
                case Keyboard.SHIFT: 
                    isRunning = true;
                    if (isMoving)
                        updateMovement(movementDirection);
                    break;
                case Keyboard.UP: 
                case Keyboard.W: 
                case Keyboard.Z: //fr
                    updateMovement(movementDirection = 1);
                    break;
                case Keyboard.DOWN: 
                case Keyboard.S: 
                    updateMovement(movementDirection = -1);
                    break;
                case Keyboard.LEFT: 
                case Keyboard.A: 
                case Keyboard.Q: //fr
                    currentRotationInc = -ROTATION_SPEED;
                    break;
                case Keyboard.RIGHT: 
                case Keyboard.D: 
                    currentRotationInc = ROTATION_SPEED;
                    break;
                case Keyboard.E: 
                    fight2();
                    break;
                case Keyboard.SPACE: 
                case Keyboard.R: 
                    fight();
                    break;
                case Keyboard.N: 
                    randomSky();
                    break;
                case Keyboard.B: 
                    makeClone();
                    break;
            }
        }
        
        /**
         * Key up listener
         */
        private function onKeyUp(event:KeyboardEvent):void {
            switch (event.keyCode) {
                case Keyboard.SHIFT: 
                    isRunning = false;
                    if (isMoving)
                        updateMovement(movementDirection);
                    break;
                case Keyboard.UP: 
                case Keyboard.W: 
                case Keyboard.Z: //fr
                case Keyboard.DOWN: 
                case Keyboard.S: 
                case Keyboard.SPACE: 
                case Keyboard.E: 
                case Keyboard.R: 
                    stop();
                    break;
                case Keyboard.LEFT: 
                case Keyboard.A: 
                case Keyboard.Q: //fr
                case Keyboard.RIGHT: 
                case Keyboard.D: 
                    currentRotationInc = 0;
                    break;
            }
        }
        
        //--------------------------------------------------------------------- NAVIGATION
        
        /**
         * stage listener and mouse control
         */
        private function onResize(event:Event=null):void {
            _view.width = stage.stageWidth;
            _view.height = stage.stageHeight;
            _stats.x = stage.stageWidth - _stats.width;
            _signature.y = stage.stageHeight - _signature.height;
        }
        
        private function onStageMouseDown(ev:MouseEvent):void {
            _prevMouseX = ev.stageX;
            _prevMouseY = ev.stageY;
            _mouseMove = true;
        }
        
        private function onStageMouseLeave(event:Event):void {
            _mouseMove = false;
        }
        
        private function onStageMouseMove(ev:MouseEvent):void {
            if (_mouseMove) {
                _hoverCtrl.panAngle += (ev.stageX - _prevMouseX);
                _hoverCtrl.tiltAngle += (ev.stageY - _prevMouseY);
            }
            _prevMouseX = ev.stageX;
            _prevMouseY = ev.stageY;
        }
        
        /**
         * mouseWheel listener
         */
        private function onStageMouseWheel(ev:MouseEvent):void {
            _hoverCtrl.distance -= ev.delta * 5;
            if (_hoverCtrl.distance < 600) {
                if (ev.delta > 0)
                    _cameraHeight += 10;
                else
                    _cameraHeight -= 10;
            }
            if (_hoverCtrl.distance < 100)
                _hoverCtrl.distance = 100;
            else if (_hoverCtrl.distance > 2000)
                _hoverCtrl.distance = 2000;
        }
        
        //--------------------------------------------------------------------- EYE
        
        /**
         * Dynamique eye
         */
        public function addHeroEye(Scale:Number):void {
            if (_eyes)
                return;
            // texture
            _eyeMapClose = new ColorMaterial(0xA13D1E);
            _eyeMapClose.lightPicker = _lightPicker;
            _eyeMapClose.specularLightSources = LightSources.LIGHTS;
            _eyeMapClose.shadowMethod = new TripleFilteredShadowMapMethod(DirectionalLight(_light[0]));
            _eyeMapClose.gloss = 12;
            _eyeMapClose.specular = 0.6;
            _eyeMapClose.ambient = 1;
            _materials.push(_eyeMapClose);
            //get eye texture from reference bitmap
            var m:Matrix = new Matrix();
            m.translate(-283, -197);
            var b:BitmapData = new BitmapData(256, 256, false)
            b.draw(_mapList[0], m)
            
            _eyeMapOpen = new TextureMaterial(new BitmapTexture(b));
            _eyeMapOpen.lightPicker = _lightPicker;
            _eyeMapOpen.specularLightSources = LightSources.LIGHTS;
            _eyeMapOpen.addMethod(new EnvMapMethod(_mapper.sky, 0.1));
            _eyeMapOpen.shadowMethod = new TripleFilteredShadowMapMethod(DirectionalLight(_light[0]));
            _eyeMapOpen.gloss = 300;
            _eyeMapOpen.specular = 5;
            _eyeMapOpen.ambient = 1;
            _eyeMapOpen.repeat = true;
            _materials.push(_eyeMapOpen);
            // object
            _eyes = new Mesh(new Geometry());
            _eyesTarget = new Mesh(new Geometry());
            _eyeR = new Mesh(new SphereGeometry(1, 32, 24), _eyeMapClose);
            _eyeL = new Mesh(new SphereGeometry(1, 32, 24), _eyeMapClose);
            _eyeR.castsShadows = _eyeL.castsShadows = false;
            
            _eyes.addChild(_eyeR);
            _eyes.addChild(_eyeL);
            
            _eyeR.geometry.scaleUV(2, 1);
            _eyeL.geometry.scaleUV(2, 1);
            
            _eyeR.z = _eyeL.z = 3.68;
            _eyeR.x = _eyeL.x = 6;
            _eyeR.y = 1.90;
            _eyeL.y = -1.46;
            
            _heroPieces = new Mesh(new Geometry());
            _heroPieces.scale(Scale);
            _heroPieces.addChild(_eyesTarget);
            _heroPieces.addChild(_eyes);
            _eyeLook = new Mesh(new PlaneGeometry(0.3, 0.3, 1, 1), new ColorMaterial(0xFFFFFF, 1));
            _eyeLook.rotationX = 90;
            _eyeLook.visible = false;
            var h:ColorMaterial = new ColorMaterial(0xFFFFFF, 1)
            var zone:Mesh = new Mesh(new PlaneGeometry(12, 6, 1, 1), h);
            zone.castsShadows = false;
            zone.material.blendMode = "multiply";
            zone.addEventListener(MouseEvent3D.MOUSE_MOVE, onMeshMouseMove);
            zone.addEventListener(MouseEvent3D.MOUSE_OVER, onMeshMouseOver);
            zone.addEventListener(MouseEvent3D.MOUSE_OUT, onMeshMouseOut);
            zone.mouseEnabled = true;
            zone.rotationX = 90;
            zone.rotationZ = 90;
            zone.z = 10;
            zone.x = 6;
            zone.y = 0.22;
            _eyeLook.z = 10.2;
            _eyeLook.x = 6;
            _eyeLook.y = 0.22;
            _eyePosition = _eyeLook.position;
            
            _eyes.addChild(zone);
            _eyes.addChild(_eyeLook);
            _view.scene.addChild(_heroPieces);
        }
        
        /**
         * mesh listener for mouse over interaction
         */
        private function onMeshMouseOver(event:MouseEvent3D):void {
            event.target.showBounds = true;
            _eyeLook.visible = true;
            onMeshMouseMove(event);
        }
        
        /**
         * mesh listener for mouse out interaction
         */
        private function onMeshMouseOut(event:MouseEvent3D):void {
            event.target.showBounds = false;
            _eyeLook.visible = false;
            _eyeLook.position = _eyePosition;
        }
        
        /**
         * mesh listener for mouse move interaction
         */
        private function onMeshMouseMove(event:MouseEvent3D):void {
            _eyeLook.position = new Vector3D(event.localPosition.z + 6, event.localPosition.x, event.localPosition.y + 10);
        }
        
        private function updateEye():void {
            if (_heroPieces && hero) {
                _heroPieces.transform = hero.transform;
                //get the head bone
                if (animator)
                    if (animator.globalPose.numJointPoses >= 40) {
                        _eyes.transform = animator.globalPose.jointPoses[39].toMatrix3D();
                        _eyes.position.add(new Vector3D(-10.22, 0, 0));
                    }
                // look 
                _eyeR.lookAt(_eyeLook.position.add(new Vector3D(0, 1.4, 0)), new Vector3D(0, 1, 1));
                _eyeL.lookAt(_eyeLook.position.add(new Vector3D(0, -1.4, 0)), new Vector3D(0, 1, 1));
                // open close eye	
                _eyeCount++
                if (_eyeCount > 300)
                    closeEye();
                if (_eyeCount > 309)
                    openEye();
            }
        }
        
        private function closeEye():void {
            _eyeR.material = _eyeMapClose;
            _eyeL.material = _eyeMapClose;
        }
        
        private function openEye():void {
            _eyeR.material = _eyeMapOpen;
            _eyeL.material = _eyeMapOpen;
            _eyeCount = 0;
        }
        
        //--------------------------------------------------------------------- FLASH SIDE
        
        /**
         * Create an instructions overlay
         */
        private function initText():void {
            _text = new TextField();
            _text.defaultTextFormat = new TextFormat("Verdana", 11, 0xFFFFFF);
            _text.width = 300;
            _text.height = 250;
            _text.selectable = false;
            _text.mouseEnabled = true;
            _text.wordWrap = true;
            _text.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
            addChild(_text);
            
            //add signature from libs/signature.swc
            var signature:MovieClip = new Signature();
            _signature = new Bitmap(new BitmapData(signature.width, signature.height, true, 0));
            stage.quality = StageQuality.HIGH;
            _signature.bitmapData.draw(signature);
            stage.quality = StageQuality.LOW;
            addChild(_signature);
        }
        
        /**
         * final message
         */
        protected function message():void {
            _text.htmlText = "<a href='http://3dflashlo.wordpress.com/' target='_blank'>ABOUT</a>";
            _text.htmlText += " - <a href='https://github.com/lo-th/loth_labs' target='_blank'>SOURCE</a>\n\n";
            _text.htmlText = "<a href='http://3dflashlo.wordpress.com/' target='_blank'>ABOUT</a>";
            _text.htmlText += " - <a href='https://github.com/lo-th/loth_labs' target='_blank'>SOURCE</a>\n\n";
            _text.appendText("Cursor keys / WSAD / ZSQD - move\n");
            _text.appendText("SHIFT - hold down to run\n");
            _text.appendText("E - punch\n");
            _text.appendText("SPACE / R - guard\n");
            _text.appendText("N - random sky\n");
            _text.appendText("B - clone !\n");
        }
        
        /**
         * log for display info
         */
        private function log(t:String):void {
            _text.htmlText = t;
        }
    }
}

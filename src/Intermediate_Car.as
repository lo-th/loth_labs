
/*

   CAR physics example in Away3d

   Demonstrates:

   How to use awayPhysics for real car simulation
   How to import AWD with liked object
   How to drasticaly reduce mapping size by using vector .swc map and mapper generator

   Code, model and map by LoTh (basic version)
   3dflashlo@gmail.com - http://3dflashlo.wordpress.com/

   Code reference https://github.com/away3d/awayphysics-examples-fp11/
   BvhTriangleMeshCarTest.as  by Muzerly http://www.muzerly.com/

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
    import away3d.cameras.Camera3D;
    import away3d.containers.Scene3D;
    import away3d.controllers.FollowController;
    import away3d.materials.methods.TripleFilteredShadowMapMethod;
    import away3d.lights.shadowmaps.NearDirectionalShadowMapper;
    import away3d.lights.shadowmaps.DirectionalShadowMapper;
    import away3d.materials.methods.FilteredShadowMapMethod;
    import away3d.materials.lightpickers.StaticLightPicker;
    import away3d.materials.methods.FresnelSpecularMethod;
    import away3d.materials.methods.NearShadowMapMethod;
    import away3d.materials.methods.LightMapMethod;
    import away3d.materials.methods.RimLightMethod;
    import away3d.cameras.lenses.PerspectiveLens;
    import away3d.materials.methods.EnvMapMethod;
    import away3d.materials.DefaultMaterialBase;
    import away3d.containers.ObjectContainer3D;
    import away3d.controllers.HoverController;
    import away3d.materials.methods.FogMethod;
    import away3d.loaders.parsers.AWD2Parser;
    import away3d.materials.TextureMaterial;
    import away3d.library.assets.AssetType;
    import away3d.primitives.PlaneGeometry;
    import away3d.loaders.parsers.Parsers;
    import away3d.materials.ColorMaterial;
    import away3d.lights.DirectionalLight;
    import away3d.primitives.CubeGeometry;
    import away3d.textures.BitmapTexture;
    import away3d.materials.LightSources;
    import away3d.library.AssetLibrary;
    import away3d.events.MouseEvent3D;
    import away3d.events.Stage3DEvent;
    import away3d.events.LoaderEvent;
    import away3d.core.base.Geometry;
    import away3d.lights.LightProbe;
    import away3d.lights.PointLight;
    import away3d.containers.View3D;
    import away3d.primitives.SkyBox;
    import away3d.events.AssetEvent;
    import away3d.loaders.Loader3D;
    import away3d.lights.LightBase;
    import away3d.debug.AwayStats;
    import away3d.entities.Mesh;
    import flash.geom.Point;
    
    import awayphysics.debug.AWPDebugDraw;
    import awayphysics.dynamics.AWPRigidBody;
    import awayphysics.dynamics.AWPDynamicsWorld
    import awayphysics.dynamics.vehicle.AWPWheelInfo;
    import awayphysics.dynamics.vehicle.AWPRaycastInfo;
    import awayphysics.dynamics.vehicle.AWPVehicleTuning;
    import awayphysics.dynamics.vehicle.AWPRaycastVehicle;
    import awayphysics.collision.shapes.AWPBvhTriangleMeshShape;
    import awayphysics.collision.dispatch.AWPCollisionObject;
    import awayphysics.collision.shapes.AWPConvexHullShape;
    import awayphysics.collision.shapes.AWPCompoundShape;
    
    import flash.filters.DropShadowFilter;
    import flash.display.StageScaleMode;
    import flash.display.StageQuality;
    import flash.events.KeyboardEvent;
    import flash.display.BitmapData;
    import flash.display.StageAlign;
    import flash.events.MouseEvent;
    import flash.display.MovieClip;
    import flash.text.TextFormat;
    import flash.display.Bitmap;
    import flash.display.Sprite;
    import flash.text.TextField;
    import flash.net.URLRequest;
    import flash.geom.Vector3D;
    import flash.geom.Matrix3D;
    import flash.events.Event;
    import flash.ui.Keyboard;
    import flash.geom.Matrix;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.display.DisplayObject;
    import flash.events.ProgressEvent;
    import flash.net.URLLoader;
    import flash.net.URLLoaderDataFormat;
    
    [SWF(backgroundColor="#333338",frameRate="60",quality="LOW",width="1600",height="768")]
    
    public class Intermediate_Car extends Sprite {
        private static const timeStep:Number = 1.0 / 60;
        //global setting
        private var _scale:Number = 1;
        //demo color [ light color 1, light color 2, sky color, ground color]
        private var DemoColor:Array = [0xAAAAA9, 0x333338, 0x445465, 0x333338];
        private var DemoAmbiant:Array = [0.1, 0.1];
        private var DemoDiffuse:Array = [0.5, 0.3];
        private var DemoSpecular:Array = [1, 0.5];
        //engine variables
        private var _scene:Scene3D;
        private var _camera:Camera3D;
        private var _view:View3D;
        private var _view2:View3D;
        private var _skyBox:SkyBox;
        private var _stats:AwayStats;
        private var _hoverCamera01:HoverController;
        
        private var _lightPicker:StaticLightPicker;
        //referency
        private var _movies:Vector.<MovieClip>;
        private var _carMaterials:Vector.<DefaultMaterialBase>;
        private var _materials:Vector.<DefaultMaterialBase>;
        private var _light:Array;
        
        //physics
        private var _cars:Vector.<AWPRaycastVehicle>;
        private var _carsBoby:Vector.<AWPRigidBody>;
        private var _wheels:Vector.<Vector.<Mesh>>;
        private var _physicsWorld:AWPDynamicsWorld;
        private var _turning:AWPVehicleTuning;
        
        // debug
        private const _debug:Boolean = false;
        private var _debugDraw:AWPDebugDraw;
        //navigation
        private var _prevMouseX01:int;
        private var _prevMouseY01:int;
        private var _mouseCam01:Point;
        
        private var _mouseMove:Boolean;
        private var _cameraHeight:Number = 0;
        //view effect
        private var _fog:FogMethod;
        private var _fog2:FogMethod;
        private var _reflect:EnvMapMethod;
        private var _specularMethod:FresnelSpecularMethod;
        private var _shadowMethod:NearShadowMapMethod;
        //car player 1
        private var _carContent:Mesh;
        private var _engineForce:Number = 0;
        private var _breakingForce:Number = 0;
        private var _vehicleSteering:Number = 0;
        private var _keyRight:Boolean = false;
        private var _keyLeft:Boolean = false;
        private var _boost:int = 0;
        //car mesh referency
        private var _carShape:Mesh;
        private var _wheel:Mesh;
        private var _body:Mesh;
        private var _steeringWheel:Mesh;
        private var _meshSpeed:Mesh;
        
        private var _mapper:Mapper;
        private var _signature:Bitmap;
        private var _playerSpeed01:int = 0;
        //stage center
        private var _middle:int;
        
        //flash 2d
        private var _text:TextField;
        private var _bigText01:TextField;
        private var _speedText01:TextField;
        private var _hotkey:String = "<font size='11' color='#FF8030'>";
        private var _hotkey2:String = "<font size='12' color='#FFae50'>";
        //start counter 
        private var time:Timer;
        private var _timeNumber:int = 3;
        
        /**
         * Constructor
         */
        public function Intermediate_Car() {
            if (stage)
                init();
            else
                addEventListener(Event.ADDED_TO_STAGE, init, false, 0, true);
        }
        
        /**
         * Global initialise function
         */
        private function init(e:Event=null):void {
            removeEventListener(Event.ADDED_TO_STAGE, init)
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            _middle = stage.stageWidth >> 1;
            initEngine();
            initPhysicsEngine();
            initText();
            initLights();
            initMaterial();
            
            load("assets/car.awd");
            
            addEventListener(Event.ENTER_FRAME, physicsReady, false, 0, true);
            onResize();
        }
        
        /**
         * Global start when all in place
         */
        private function physicsReady(e:Event):void {
            if (_physicsWorld && _cars.length == 1) {
                removeEventListener(Event.ENTER_FRAME, physicsReady);
                initListeners();
            }
        
        }
        
        //--------------------------------------------------------------------- ENGINE
        
        /**
         * Initialise the 3d engine
         */
        private function initEngine():void {
            removeEventListener(Event.ADDED_TO_STAGE, init);
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;
            
            _view = new View3D();
            _scene = new Scene3D();
            
            _view.scene = _scene;
            
            _view.camera.lens = new PerspectiveLens(65);
            _view.camera.lens.far = 30000;
            _view.camera.lens.near = 1;
            
            _hoverCamera01 = new HoverController(_view.camera, null, 90, 10, 500, 10, 90);
            _hoverCamera01.minTiltAngle = -60;
            _hoverCamera01.maxTiltAngle = 60;
            _hoverCamera01.autoUpdate = false;
            
            addChild(_view);
            
            //stat
            _stats = new AwayStats(_view, true, true);
            addChild(_stats);
            
            //light referency
            _light = [];
            // car reference
            _cars = new Vector.<AWPRaycastVehicle>();
            _carsBoby = new Vector.<AWPRigidBody>();
            _wheels = new Vector.<Vector.<Mesh>>();
            //auto map generator
            _mapper = new Mapper();
        }
        
        //--------------------------------------------------------------------- LOOP
        
        /**
         * Render loop
         */
        private function onEnterFrame(e:Event):void {
            //update physics engine
            if (_physicsWorld)
                _physicsWorld.step(timeStep);
            if (_keyLeft) {
                _vehicleSteering -= 0.05;
                if (_vehicleSteering < -Math.PI / 6) {
                    _vehicleSteering = -Math.PI / 6;
                }
            }
            if (_keyRight) {
                _vehicleSteering += 0.05;
                if (_vehicleSteering > Math.PI / 6) {
                    _vehicleSteering = Math.PI / 6;
                }
            }
            if (_cars[0]) {
                // control the car
                _cars[0].applyEngineForce(_engineForce, 0);
                _cars[0].setBrake(_breakingForce, 0);
                _cars[0].applyEngineForce(_engineForce, 1);
                _cars[0].setBrake(_breakingForce, 1);
                _cars[0].applyEngineForce(_engineForce, 2);
                _cars[0].setBrake(_breakingForce, 2);
                _cars[0].applyEngineForce(_engineForce, 3);
                _cars[0].setBrake(_breakingForce, 3);
                
                _cars[0].setSteeringValue(_vehicleSteering, 0);
                _cars[0].setSteeringValue(_vehicleSteering, 1);
                _vehicleSteering *= 0.9;
            }
            
            //update camera controler
            if (_carContent)
                _hoverCamera01.lookAtPosition = _carContent.position;
            
            _hoverCamera01.update();
            
            if (_debug)
                _debugDraw.debugDrawWorld();
            //update light
            if (_light[1])
                _light[1].position = _view.camera.position;
            
            //update 3d engine
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
        
        }
        
        //--------------------------------------------------------------------- LIGHT
        
        /**
         * Initialise the lights
         */
        private function initLights():void {
            //create a light for shadows that mimics the sun's position in the skybox
            var sun:DirectionalLight = new DirectionalLight();
            sun.y = 1200;
            sun.castsShadows = true;
            sun.shadowMapper = new NearDirectionalShadowMapper(.1);
            _scene.addChild(sun);
            _light.push(sun);
            //create a light for ambient effect that mimics the sky
            var moon:PointLight = new PointLight();
            moon.y = 1200;
            moon.radius = 2000;
            moon.fallOff = 5000;
            _scene.addChild(moon);
            _light.push(moon);
            //create sky and probe light
            makeSky();
        }
        
        private function Orbit(H:Number, V:Number, D:Number):Vector3D {
            var p:Vector3D = new Vector3D()
            var phi:Number = RadDeg(H);
            var theta:Number = RadDeg(V);
            p.x = (D * Math.sin(phi) * Math.cos(theta));
            p.z = (D * Math.sin(phi) * Math.sin(theta));
            p.y = (D * Math.cos(phi));
            return p;
        }
        
        private function RadDeg(d:Number):Number {
            return (d * (Math.PI / 180));
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
                _scene.removeChild(_light[2]);
                _light.pop();
            }
            if (_skyBox) {
                _scene.removeChild(_skyBox);
                _skyBox.dispose();
            }
            //generate vector degrade sky
            _mapper.vectorSky([DemoColor[3], DemoColor[3], DemoColor[2]], 8);
            _skyBox = new SkyBox(_mapper.sky);
            _scene.addChild(_skyBox);
            //add new probe light
            var probe:LightProbe = new LightProbe(_mapper.sky);
            _scene.addChild(probe);
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
                if (o.name == 'road') {
                    o.removeMethod(_fog);
                    _fog.dispose();
                    _fog = new FogMethod(0, _view.camera.lens.far, DemoColor[3]);
                    o.addMethod(_fog);
                } else if (o.name == 'wall') {
                    o.removeMethod(_fog2);
                    _fog2.dispose();
                    _fog2 = new FogMethod(0, _view.camera.lens.far, DemoColor[3]);
                    o.addMethod(_fog2);
                }
                o.lightPicker = _lightPicker;
            }
            for each (var m:DefaultMaterialBase in _carMaterials) {
                m.lightPicker = _lightPicker;
            }
        }
        
        //--------------------------------------------------------------------- MATERIAL
        
        /**
         * Initialise the material from libs/textures_c1gt.swc
         * Q = Quality  1 or 2
         */
        protected function initMaterial(Q:int=1):void {
            //material reference
            _materials = new Vector.<DefaultMaterialBase>();
            _carMaterials = new Vector.<DefaultMaterialBase>();
            //MovieClip reference
            _movies = new Vector.<MovieClip>();
            _movies.push(new TextureBodyColor(), new TextureDoorColor(), new TextureWheel(), new TextureInterior(), new TextureCarlights(), new TextureSteering(), new TextureWall(), new TextureRoad());
            
            //global methode
            _fog = new FogMethod(0, _view.camera.lens.far, DemoColor[3]);
            _fog2 = new FogMethod(0, _view.camera.lens.far, DemoColor[3]);
            _specularMethod = new FresnelSpecularMethod();
            _specularMethod.normalReflectance = 1.8;
            
            _shadowMethod = new NearShadowMapMethod(new FilteredShadowMapMethod(_light[0]));
            _shadowMethod.epsilon = .0007;
            
            newDecoMaterial(Q);
            newCarColor(Q);
        }
        
        /**
         * deco material
         */
        protected function newDecoMaterial(Q:int=1):void {
            stage.quality = StageQuality.HIGH;
            var material:DefaultMaterialBase;
            // 0 - wall
            material = materialFromClip("wall", _movies[6], 1024, Q, false, true);
            material.repeat = true;
            material.gloss = 30;
            material.specular = 0.3;
            material.addMethod(_fog2);
            // 1 - ground
            material = materialFromClip("road", _movies[7], 1024, Q, false);
            material.repeat = true;
            material.gloss = 30;
            material.specular = 0.3;
            material.addMethod(_fog);
            stage.quality = StageQuality.LOW;
        }
        
        /**
         * Vector car paint
         */
        protected function newCarColor(Q:int=1):void {
            
            //change color of car paint
            var color01:Number = 0xffffff * Math.random();
            var color02:Number = 0xffffff * Math.random();
            _mapper.color(_movies[0].C, color01);
            _mapper.color(_movies[1].C, color01);
            _mapper.color(_movies[3].C, color02);
            _mapper.color(_movies[5].C, color02);
            
            stage.quality = StageQuality.HIGH;
            var material:DefaultMaterialBase;
            // 0 - car paint  - 7
            material = materialFromClip("paint", _movies[0], 1024, Q, true);
            material.gloss = 60;
            material.specular = 1;
            // 1 - glass - 8 
            material = materialFromClip("glass", _movies[0], 1024, Q, true, true);
            material.alphaBlending = true;
            material.gloss = 150;
            material.specular = 3;
            // 2 - door - 9
            material = materialFromClip("door", _movies[1], 1024, Q, true);
            material.gloss = 60;
            material.specular = 1;
            // 3 - wheel - 10
            material = materialFromClip("wheel", _movies[2], 512, Q, true);
            material.gloss = 25;
            material.specular = 0.3;
            material.addMethod(new RimLightMethod(DemoColor[1], .2, 2, "mix"));
            // 4 - intern 11
            material = materialFromClip("intern", _movies[3], 1024, Q, true);
            // 5 - lights 12
            material = materialFromClip("light", _movies[4], 256, Q, true);
            // 6 - steering wheel 13
            material = materialFromClip("steering", _movies[5], 256, Q, true);
            
            stage.quality = StageQuality.LOW;
        }
        
        /**
         * Material from movieClip
         * ( material name, movieClip, resolution, quality, transparent )
         */
        protected function materialFromClip(name:String, Clip:MovieClip, R:int=1024, Q:int=2, forCar:Boolean=false, T:Boolean=false):DefaultMaterialBase {
            var material:TextureMaterial;
            var tmp:BitmapData = new BitmapData(R * Q, R * Q, T, 0x000000);
            var m:Matrix = new Matrix();
            m.scale(Q, Q);
            tmp.draw(Clip, m);
            _mapper.AutoMapper(tmp);
            material = new TextureMaterial(new BitmapTexture(tmp));
            material.normalMap = new BitmapTexture(_mapper.bitdata[1]);
            material.name = name;
            material.lightPicker = _lightPicker;
            //material.diffuseLightSources = LightSources.PROBES;
            material.specularLightSources = LightSources.LIGHTS;
            material.specularMethod = _specularMethod;
            material.shadowMethod = _shadowMethod;
            
            //push to reference
            if (forCar)
                _carMaterials.push(material);
            else
                _materials.push(material);
            return material;
        }
        
        //--------------------------------------------------------------------- AWD
        
        /**
         * Load Binary file
         */
        private function load(url:String):void {
            var loader:URLLoader = new URLLoader();
            loader.dataFormat = URLLoaderDataFormat.BINARY
            loader.addEventListener(Event.COMPLETE, parseAWD, false, 0, true);
            loader.addEventListener(ProgressEvent.PROGRESS, loadProgress, false, 0, true);
            loader.load(new URLRequest(url));
        }
        
        private function loadProgress(e:ProgressEvent):void {
            var P:int = int(e.bytesLoaded / e.bytesTotal * 100);
            if (P != 100)
                log('Load : ' + P + ' % | ' + int((e.bytesLoaded / 1024) << 0) + ' ko\n');
            else
                message();
        }
        
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
         * Listener function for car asset complete
         */
        private function onAssetComplete(event:AssetEvent):void {
            var sceneShape:AWPBvhTriangleMeshShape;
            var sceneBody:AWPRigidBody;
            if (!_carContent) {
                _carContent = new Mesh(new Geometry);
                _scene.addChild(_carContent);
            }
            var m:Mesh;
            if (event.asset.assetType == AssetType.MESH) {
                m = Mesh(event.asset);
                //m.castsShadows = false;
                if (m) {
                    if (m.name == "body") {
                        //other car object are liked to body mesh in 3dsmax
                        m.material = _carMaterials[0];
                        m.scale(_scale);
                        m.castsShadows = true;
                        _body = m;
                        _carContent.addChild(_body);
                    } else if (m.name == "wheel") {
                        // the wheel no add juste for clone
                        m.material = _carMaterials[3];
                        m.geometry.scale(_scale);
                        _wheel = m;
                    } else if (m.name == "headLight") {
                        m.material = _carMaterials[5];
                    } else if (m.name == "hood") {
                        m.material = _carMaterials[0];
                    } else if (m.name == "bottomCar") {
                        m.material = _carMaterials[0];
                    } else if (m.name == "trunk" || m.name == 'glass' || m.name == 'doorGlassLeft' || m.name == 'doorGlassRight') {
                        m.castsShadows = false;
                        m.material = _carMaterials[1];
                    } else if (m.name == "interior") {
                        m.material = _carMaterials[4];
                    } else if (m.name == "doorRght" || m.name == "dooLeft") {
                        m.material = _carMaterials[2];
                    } else if (m.name == "steeringWheel") {
                        m.material = _carMaterials[6];
                        m.geometry.scale(_scale);
                        _steeringWheel = m;
                        initDriveWheels();
                    } else if (m.name == "MotorAndBorder") {
                        m.visible = false;
                    } else if (m.name == "Track") {
                        m.castsShadows = false;
                        m.geometry.scale(_scale);
                        m.material = _materials[1];
                        _scene.addChild(m);
                        // create triangle mesh shape for Track ground
                        sceneShape = new AWPBvhTriangleMeshShape(m.geometry);
                        sceneBody = new AWPRigidBody(sceneShape, m, 0);
                        _physicsWorld.addRigidBody(sceneBody);
                    } else if (m.name == "Wall") {
                        m.castsShadows = false;
                        m.geometry.scale(_scale);
                        m.material = _materials[0];
                        _scene.addChild(m);
                        // create triangle mesh shape for wall
                        sceneShape = new AWPBvhTriangleMeshShape(m.geometry);
                        sceneBody = new AWPRigidBody(sceneShape, m, 0);
                        _physicsWorld.addRigidBody(sceneBody);
                    } else if (m.name == "Deco") {
                        m.castsShadows = false;
                        m.geometry.scale(_scale);
                        m.material = _materials[0];
                        m.geometry.scaleUV(50, 50);
                        _scene.addChild(m);
                        
                    } else if (m.name == "carShape") {
                        //! invisible : physics car collision shape 
                        m.geometry.scale(_scale);
                        m.castsShadows = false;
                        _carShape = m;
                    } else if (m.name == "extraCollision") {
                        //! invisible : physics collision
                        m.geometry.scale(_scale);
                        sceneShape = new AWPBvhTriangleMeshShape(m.geometry);
                        sceneBody = new AWPRigidBody(sceneShape, m, 0);
                        _physicsWorld.addRigidBody(sceneBody);
                    }
                }
            }
        }
        
        /**
         * Check if all resourse loaded
         */
        private function finalAWD(e:LoaderEvent):void {
            initCarPhysics(_carContent);
            var loader3d:Loader3D = e.target as Loader3D;
            loader3d.removeEventListener(AssetEvent.ASSET_COMPLETE, onAssetComplete);
            loader3d.removeEventListener(LoaderEvent.RESOURCE_COMPLETE, finalAWD);
        }
        
        //--------------------------------------------------------------------- PHYSICS
        
        /**
         * Initialise the physics engine
         */
        private function initPhysicsEngine():void {
            _physicsWorld = AWPDynamicsWorld.getInstance();
            _physicsWorld.initWithDbvtBroadphase();
            _physicsWorld.gravity = new Vector3D(0, -10, 0);
            
            if (_debug) {
                _debugDraw = new AWPDebugDraw(_view, _physicsWorld);
                _debugDraw.debugMode = AWPDebugDraw.DBG_DrawCollisionShapes;
            }
        }
        
        /**
         * Car physics
         */
        private function initCarPhysics(Content:Mesh):void {
            // create the chassis body
            var carShape:AWPCompoundShape = createCarShape();
            var wheels:Vector.<Mesh> = createCarWheels();
            var carBody:AWPRigidBody = new AWPRigidBody(carShape, Content, 1000);
            carBody.activationState = AWPCollisionObject.DISABLE_DEACTIVATION;
            
            carBody.angularDamping = 0.1;
            carBody.linearDamping = 0.1;
            carBody.friction = 0.9;
            // add to world physics
            _physicsWorld.addRigidBody(carBody);
            
            // create vehicle
            _turning = new AWPVehicleTuning();
            with (_turning) {
                frictionSlip = 2;
                suspensionStiffness = 100;
                suspensionDamping = 0.85;
                suspensionCompression = 0.83;
                maxSuspensionTravelCm = 10 * _scale;
                maxSuspensionForce = 10000;
            }
            var car:AWPRaycastVehicle = new AWPRaycastVehicle(_turning, carBody);
            _physicsWorld.addVehicle(car);
            
            // wheels setting
            car.addWheel(wheels[0], new Vector3D(39 * _scale, 5 * _scale, 60 * _scale), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 5 * _scale, 17 * _scale, _turning, true);
            car.addWheel(wheels[1], new Vector3D(-39 * _scale, 5 * _scale, 60 * _scale), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 5 * _scale, 17 * _scale, _turning, true);
            car.addWheel(wheels[2], new Vector3D(39 * _scale, 5 * _scale, -60 * _scale), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 5 * _scale, 17 * _scale, _turning, false);
            car.addWheel(wheels[3], new Vector3D(-39 * _scale, 5 * _scale, -60 * _scale), new Vector3D(0, -1, 0), new Vector3D(-1, 0, 0), 5 * _scale, 17 * _scale, _turning, false);
            
            // wheels settings
            for (var i:int = 0; i < car.getNumWheels(); i++) {
                var wheel:AWPWheelInfo = car.getWheelInfo(i);
                wheel.wheelsDampingRelaxation = 4.5;
                wheel.wheelsDampingCompression = 4.5;
                wheel.suspensionRestLength1 = 10 * _scale;
                wheel.rollInfluence = 0.01;
            }
            _carsBoby.push(carBody);
            _wheels.push(wheels);
            _cars.push(car);
            
            // start position
            resetPosition();
        }
        
        /**
         * Car position rotation
         */
        private function resetPosition():void {
            var body:AWPRigidBody = _cars[0].getRigidBody();
            body.position = new Vector3D(0, 100 * _scale, -180 * _scale);
            body.rotation = new Vector3D(0, -90, 0);
            body.linearVelocity = new Vector3D();
            body.angularVelocity = new Vector3D();
            if (_cars.length == 2) {
                body = _cars[1].getRigidBody();
                body.position = new Vector3D(0, 100 * _scale, 180 * _scale);
                body.rotation = new Vector3D(0, -90, 0);
                body.linearVelocity = new Vector3D();
                body.angularVelocity = new Vector3D();
            }
            startConter();
        
        }
        
        /**
         * Car chassis shape
         */
        private function createCarShape():AWPCompoundShape {
            // car shape from loading mesh "carShape"
            var _carShapeConvex:AWPConvexHullShape = new AWPConvexHullShape(Mesh(_carShape.clone()).geometry);
            var carShape:AWPCompoundShape = new AWPCompoundShape();
            carShape.addChildShape(_carShapeConvex);
            return carShape;
        }
        
        /**
         * Init wheels
         */
        private function createCarWheels():Vector.<Mesh> {
            var wheels:Vector.<Mesh> = new Vector.<Mesh>();
            wheels.push(new Mesh(new Geometry()), Mesh(_wheel.clone()), new Mesh(new Geometry()), Mesh(_wheel.clone()));
            //reverse for left wheels
            var w2n:Mesh = Mesh(_wheel.clone());
            var w4n:Mesh = Mesh(_wheel.clone());
            w2n.rotationY = w4n.rotationY = -180;
            wheels[0].addChild(w2n);
            wheels[2].addChild(w4n);
            //showtime
            for each (var w:Mesh in wheels) {
                _scene.addChild(w);
            }
            return wheels;
        }
        
        /**
         * init drive wheel
         */
        public function initDriveWheels():void {
            var axe:Mesh = new Mesh(new Geometry());
            var matSpeed:ColorMaterial = new ColorMaterial(0xff0000);
            _meshSpeed = new Mesh(new CubeGeometry(.25 * _scale, 2.5 * _scale, .25 * _scale), matSpeed);
            _meshSpeed.pivotPoint = new Vector3D(0, -2.5 * _scale, 0);
            _meshSpeed.z = -3 * _scale;
            _meshSpeed.rotationZ = 135;
            axe.rotationX = 25 + 180;
            axe.addChild(_meshSpeed);
            axe.position = new Vector3D(-20 * _scale, 30 * _scale, 30 * _scale);
            
            _carContent.addChild(axe);
            axe.addChild(_steeringWheel);
        }
        
        //--------------------------------------------------------------------- KEYBOARD
        
        /**
         * Key down listener
         */
        private function onKeyDown(event:KeyboardEvent):void {
            switch (event.keyCode) {
                case Keyboard.SHIFT: 
                    _boost = 5000;
                    break;
                case Keyboard.UP: 
                case Keyboard.W: 
                case Keyboard.Z: //fr
                    _engineForce = 2500 + _boost;
                    _breakingForce = 0;
                    break;
                case Keyboard.DOWN: 
                case Keyboard.S: 
                    _engineForce = -2500;
                    _breakingForce = 0;
                    break;
                case Keyboard.LEFT: 
                case Keyboard.A: 
                case Keyboard.Q: //fr
                    _keyLeft = true;
                    _keyRight = false;
                    break;
                case Keyboard.RIGHT: 
                case Keyboard.D: 
                    _keyRight = true;
                    _keyLeft = false;
                    break;
                case Keyboard.E: 
                    _breakingForce = 80;
                    _engineForce = 0;
                    break;
                case Keyboard.N: 
                    randomSky();
                    break;
                case Keyboard.R: 
                    resetPosition();
                    break;
            }
        }
        
        /**
         * Key up listener
         */
        private function onKeyUp(event:KeyboardEvent):void {
            switch (event.keyCode) {
                case Keyboard.SHIFT: 
                    _boost = 0;
                    break;
                case Keyboard.UP: 
                case Keyboard.W: 
                case Keyboard.Z: //fr
                    _engineForce = 0;
                    break;
                case Keyboard.DOWN: 
                case Keyboard.S: 
                    _engineForce = 0;
                    break;
                case Keyboard.LEFT: 
                case Keyboard.A: 
                case Keyboard.Q: //fr
                    _keyLeft = false;
                    break;
                case Keyboard.RIGHT: 
                case Keyboard.D: 
                    _keyRight = false;
                    break;
                case Keyboard.E: 
                    _breakingForce = 0;
                    break;
            }
        }
        
        //--------------------------------------------------------------------- NAVIGATION
        
        /**
         * stage listener and mouse control
         */
        private function onResize(event:Event=null):void {
            _middle = stage.stageWidth >> 1;
            _stats.x = stage.stageWidth - _stats.width;
            _signature.y = stage.stageHeight - _signature.height;
            _view.height = stage.stageHeight;
            _bigText01.y = (stage.stageHeight / 3) - 50;
            _bigText01.width = stage.stageWidth;
        }
        
        private function onStageMouseDown(ev:MouseEvent):void {
            _prevMouseX01 = ev.stageX;
            _prevMouseY01 = ev.stageY;
            _mouseCam01 = new Point(ev.stageX, ev.stageY);
            _mouseMove = true;
        }
        
        private function onStageMouseLeave(event:Event):void {
            _mouseMove = false;
        }
        
        private function onStageMouseMove(ev:MouseEvent):void {
            if (!_mouseMove)
                return;
            
            _hoverCamera01.panAngle += (ev.stageX - _mouseCam01.x);
            _hoverCamera01.tiltAngle += (ev.stageY - _mouseCam01.y);
            
            _mouseCam01 = new Point(ev.stageX, ev.stageY);
        }
        
        private function onStageMouseWheel(ev:MouseEvent):void {
            _hoverCamera01.distance -= ev.delta * 5;
            if (_hoverCamera01.distance < 600) {
                if (ev.delta > 0)
                    _cameraHeight += 10;
                else
                    _cameraHeight -= 10;
            }
            if (_hoverCamera01.distance < 100)
                _hoverCamera01.distance = 100;
            else if (_hoverCamera01.distance > 2000)
                _hoverCamera01.distance = 2000;
        }
        
        //--------------------------------------------------------------------- FLASH 2D
        
        /**
         * Create an instructions overlay
         */
        private function initText():void {
            _text = text()
            _text.mouseEnabled = true;
            _text.x = 10;
            _text.y = 5;
            addChild(_text);
            
            _bigText01 = text(_middle, 100, 40);
            addChild(_bigText01);
            bigLog01();
            
            //add signature from libs/signature.swc
            var signature:MovieClip = new Signature();
            _signature = new Bitmap(new BitmapData(signature.width, signature.height, true, 0));
            stage.quality = StageQuality.HIGH;
            _signature.bitmapData.draw(signature);
            stage.quality = StageQuality.LOW;
            addChild(_signature);
        }
        
        private function startConter():void {
            if (time) {
                time.stop();
                time.removeEventListener(TimerEvent.TIMER, count);
                _timeNumber = 3;
            }
            time = new Timer(1000, 5);
            time.addEventListener(TimerEvent.TIMER, count, false, 0, true)
            time.start();
        }
        
        private function count(e:TimerEvent):void {
            if (_timeNumber == 0) {
                bigLog01("GO");
            } else if (_timeNumber == -1) {
                bigLog01();
            } else {
                bigLog01(_timeNumber.toString());
            }
            _timeNumber--;
        }
        
        private function bigLog01(t:String=""):void {
            _bigText01.htmlText = "<p align='center'><b>" + t + "</b></p>";
            if (t == "")
                _bigText01.visible = false;
            else if (!_bigText01.visible)
                _bigText01.visible = true;
        }
        
        private function text(w:int=300, h:int=100, size:int=10):TextField {
            var t:TextField = new TextField();
            t.defaultTextFormat = new TextFormat("Verdana", size, 0xFFFFFF);
            t.width = w;
            t.height = h;
            t.multiline = true;
            t.selectable = false;
            t.wordWrap = true;
            t.mouseEnabled = false;
            t.filters = [new DropShadowFilter(1, 45, 0x0, 1, 0, 0)];
            return t
        }
        
        /**
         * final message
         */
        protected function message():void {
            _text.htmlText = _hotkey2 + "<a href='http://3dflashlo.wordpress.com/' target='_blank'>ABOUT</a> - <a href='https://github.com/lo-th/loth_labs' target='_blank'>SOURCE</a></font>\n\n";
            _text.htmlText += "Player one" + _hotkey + " WSAD</font> or " + _hotkey + "ZSQD</font> : drive " + _hotkey + "E</font> : break\n"
            _text.htmlText += _hotkey + "R</font> - restart\n";
            _text.htmlText += _hotkey + "N</font> - random sky\n";
        }
        
        /**
         * log for display info
         */
        private function log(t:String):void {
            _text.htmlText = t;
        }
    }
}
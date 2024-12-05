import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors;
import 'package:simple_sensor/simple_sensor.dart';
import "package:latlong2/latlong.dart";

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Simple Sensor'),
        ),
        body: MyStatefullApp(),
      ),
    );
  }
}

class MyStatefullApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyStatefullApp> {
  Vector3 _accelerometer        = Vector3.zero();
  Vector3 _gyroscope            = Vector3.zero();
  Vector3 _magnetometer         = Vector3.zero();
  Vector3 _userAaccelerometer   = Vector3.zero();
  Vector3 _orientation          = Vector3.zero();
  Vector3 _absoluteOrientation  = Vector3.zero();
  Vector3 _absoluteOrientation2 = Vector3.zero();
  double? _screenOrientation    = 0;

  final TextEditingController initialLatController   = TextEditingController();
  final TextEditingController initialLonController   = TextEditingController();
  final TextEditingController initialSpeedController = TextEditingController();
  final TextEditingController orientPhiController    = TextEditingController();
  final TextEditingController orientThetaController  = TextEditingController();
  final TextEditingController orientPsiController    = TextEditingController();
  final TextEditingController accelXController       = TextEditingController();
  final TextEditingController accelYController       = TextEditingController();
  final TextEditingController accelZController       = TextEditingController();

  final FocusNode initialLatFocuser   = FocusNode();
  final FocusNode initialLonFocuser   = FocusNode();
  final FocusNode initialSpeedFocuser = FocusNode();
  final FocusNode orientPhiFocuser    = FocusNode();
  final FocusNode orientThetaFocuser  = FocusNode();
  final FocusNode orientPsiFocuser    = FocusNode();
  final FocusNode accelXFocuser       = FocusNode();
  final FocusNode accelYFocuser       = FocusNode();
  final FocusNode accelZFocuser       = FocusNode();

  String INITIAL_LAT_PROMPT   = "Lat";
  String INITIAL_LON_PROMPT   = "Lon";
  String INITIAL_SPEED_PROMPT = "Speed";
  String ORIENT_PHI_PROMPT    = "Phi";
  String ORIENT_THETA_PROMPT  = "Theta";
  String ORIENT_PSI_PROMPT    = "Psi";
  String ACCEL_X_PROMPT       = "X";
  String ACCEL_Y_PROMPT       = "Y";
  String ACCEL_Z_PROMPT       = "Z";
  double BOX_HEIGHT           = 45;
  double BOX_WIDTH            = 80;

  int? _groupValue = 0;
  double distanceX = 0.0;
  double distanceY = 0.0;
  double distanceZ = 0.0;

  @override
  void initState() {
    super.initState();
    simpleSensor.gyroscope.listen((GyroscopeEvent event) {
      setState(() {
        _gyroscope.setValues(event.x, event.y, event.z);
      });
    });
    simpleSensor.accelerometer.listen((AccelerometerEvent event) {
      setState(() {
        _accelerometer.setValues(event.x, event.y, event.z);
      });
    });
    simpleSensor.userAccelerometer.listen((UserAccelerometerEvent event) {
      setState(() {
        _userAaccelerometer.setValues(event.x, event.y, event.z);
      });
    });
    simpleSensor.magnetometer.listen((MagnetometerEvent event) {
      setState(() {
        _magnetometer.setValues(event.x, event.y, event.z);
        var matrix = simpleSensor.getRotationMatrix(_accelerometer, _magnetometer);
        _absoluteOrientation2.setFrom(simpleSensor.getOrientation(matrix));
      });
    });
    simpleSensor.isOrientationAvailable().then((available) {
      if (available) {
        simpleSensor.orientation.listen((OrientationEvent event) {
          setState(() {
            _orientation.setValues(event.yaw, event.pitch, event.roll);
          });
        });
      }
    });
    simpleSensor.absoluteOrientation.listen((AbsoluteOrientationEvent event) {
      setState(() {
        _absoluteOrientation.setValues(event.yaw, event.pitch, event.roll);
      });
    });
    simpleSensor.screenOrientation.listen((ScreenOrientationEvent event) {
      setState(() {
        _screenOrientation = event.angle;
      });
    });
  }

  // Calculate distance travelled and final speed from acceleration, initial speed and time.
  // Acceleration is m/s**2
  // Speed is m/s
  // Time is in milliseconds
  // Output distance is in metres
  List<double> calculateDistanceAndSpeed(double accel, double initialSpeed, int time) {
    var distanceAndSpeed = <double>[0.0,0.0];
    double finalSpeed = initialSpeed + (accel*time)/1000.0;
    distanceAndSpeed[0] = finalSpeed;
    distanceAndSpeed[1] = (initialSpeed + finalSpeed)*0.5*(time/1000.0);

    return distanceAndSpeed;
  }

  // Latitude:
  //  var earth = 6378.137,  //radius of the earth in kilometer
  //     pi = Math.PI,
  //     m = (1 / ((2 * pi / 360) * earth)) / 1000;  //1 meter in degree
  //  var new_latitude = latitude + (your_meters * m);

  // Longitude:
  // var earth = 6378.137,  //radius of the earth in kilometer
  //    pi = Math.PI,
  //    cos = Math.cos,
  //    m = (1 / ((2 * pi / 360) * earth)) / 1000;  //1 meter in degree
  // var new_longitude = longitude + (your_meters * m) / cos(latitude * (pi / 180));


//  var EARTH_RADIUS = 6378.137;  //radius of the earth in kilometer
//  var oneMetreLat  = (1 / ((2 * pi / 360) * EARTH_RADIUS)) / 1000;
//  var oneMetreLon  =

  void setUpdateInterval(int? groupValue, int interval) {
    simpleSensor.accelerometerUpdateInterval       = interval;
    simpleSensor.userAccelerometerUpdateInterval   = interval;
    simpleSensor.gyroscopeUpdateInterval           = interval;
    simpleSensor.magnetometerUpdateInterval        = interval;
    simpleSensor.orientationUpdateInterval         = interval;
    simpleSensor.absoluteOrientationUpdateInterval = interval;
    setState(() {
      _groupValue = groupValue;
    });
  }

  Matrix3 rotationMatrixFromOrientationVector(Vector3 o) {
    return Matrix3(
        cos(o.x)*cos(o.z) - sin(o.x)*cos(o.y)*sin(o.z),
        sin(o.x)*cos(o.z) + cos(o.y)*cos(o.x)*sin(o.z),
        sin(o.y)*sin(o.z),
        -cos(o.x)*sin(o.z) - cos(o.y)*sin(o.x)*cos(o.z),
        -sin(o.x)*sin(o.z) + cos(o.y)*cos(o.x)*cos(o.z),
        sin(o.y)*cos(o.z),
        sin(o.x)*sin(o.y),
        -cos(o.x)*sin(o.y),
        cos(o.y));
  }

  void calculate() {
    print('phi ${orientPhiController.text} theta ${orientThetaController.text} psi ${orientPsiController.text}');
    print('x ${accelXController.text} y ${accelYController.text} z ${accelZController.text}');

    Matrix3 transformer = rotationMatrixFromOrientationVector(
        Vector3(radians(double.parse(orientPhiController.text)),
                radians(double.parse(orientThetaController.text)),
                radians(double.parse(orientPsiController.text)))
    );
    Vector3 accel = Vector3(double.parse(accelXController.text),
                            double.parse(accelYController.text),
                            double.parse(accelZController.text));
    transformer.transform(accel);

    setState(() {
      distanceX = accel.x;
      distanceY = accel.y;
      distanceZ = accel.z;
    });
  }

  Widget myTextField(TextEditingController controller, FocusNode focuser, String labelText) {
    return SizedBox(
      height: BOX_HEIGHT,
      width:  BOX_WIDTH,
      child: TextField(
        controller: controller,
        focusNode: focuser,
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text('Update Interval'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Radio(
                    value: 1,
                    groupValue: _groupValue,
                    onChanged: (dynamic value) => setUpdateInterval(value, Duration.microsecondsPerSecond ~/ 1),
                  ),
                  const Text("1 FPS"),
                  Radio(
                    value: 2,
                    groupValue: _groupValue,
                    onChanged: (dynamic value) => setUpdateInterval(value, Duration.microsecondsPerSecond ~/ 30),
                  ),
                  const Text("30 FPS"),
                  Radio(
                    value: 3,
                    groupValue: _groupValue,
                    onChanged: (dynamic value) => setUpdateInterval(value, Duration.microsecondsPerSecond ~/ 60),
                  ),
                  const Text("60 FPS"),
                ],
              ),
              const Text('Accelerometer'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_accelerometer.x.toStringAsFixed(4)),
                  Text(_accelerometer.y.toStringAsFixed(4)),
                  Text(_accelerometer.z.toStringAsFixed(4)),
                ],
              ),
              const Text('Magnetometer'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_magnetometer.x.toStringAsFixed(4)),
                  Text(_magnetometer.y.toStringAsFixed(4)),
                  Text(_magnetometer.z.toStringAsFixed(4)),
                ],
              ),
              const Text('Gyroscope'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_gyroscope.x.toStringAsFixed(4)),
                  Text(_gyroscope.y.toStringAsFixed(4)),
                  Text(_gyroscope.z.toStringAsFixed(4)),
                ],
              ),
              const Text('User Accelerometer'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_userAaccelerometer.x.toStringAsFixed(4)),
                  Text(_userAaccelerometer.y.toStringAsFixed(4)),
                  Text(_userAaccelerometer.z.toStringAsFixed(4)),
                ],
              ),
              const Text('Orientation'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(degrees(_orientation.x).toStringAsFixed(4)),
                  Text(degrees(_orientation.y).toStringAsFixed(4)),
                  Text(degrees(_orientation.z).toStringAsFixed(4)),
                ],
              ),
              const Text('Absolute Orientation'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(degrees(_absoluteOrientation.x).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation.y).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation.z).toStringAsFixed(4)),
                ],
              ),
              const Text('Orientation (accelerometer + magnetometer)'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(degrees(_absoluteOrientation2.x).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation2.y).toStringAsFixed(4)),
                  Text(degrees(_absoluteOrientation2.z).toStringAsFixed(4)),
                ],
              ),
              const Text('Screen Orientation'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Text(_screenOrientation!.toStringAsFixed(4)),
                ],
              ),

              const Text('Initial Position'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  myTextField(initialLatController,initialLatFocuser,INITIAL_LAT_PROMPT),
                  myTextField(initialLonController,initialLonFocuser,INITIAL_LON_PROMPT),
                  myTextField(initialSpeedController,initialSpeedFocuser,INITIAL_SPEED_PROMPT),
                ],
              ),

              const Text('Orientation'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  myTextField(orientPhiController,orientPhiFocuser,ORIENT_PHI_PROMPT),
                  myTextField(orientThetaController,orientThetaFocuser,ORIENT_THETA_PROMPT),
                  myTextField(orientPsiController,orientPsiFocuser,ORIENT_PSI_PROMPT),
                ],
              ),

              const Text('Acceleration'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  myTextField(accelXController,accelXFocuser,ACCEL_X_PROMPT),
                  myTextField(accelYController,accelYFocuser,ACCEL_Y_PROMPT),
                  myTextField(accelZController,accelZFocuser,ACCEL_Z_PROMPT),
                ],
              ),

              const Text('Update'),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () {calculate(); },
                    child: Text('Update'),
                  ),
                  SizedBox(
                    height: BOX_HEIGHT,
                    width:  BOX_WIDTH*3,
                    child: TextField(
                      focusNode: FocusNode(),
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: "x: ${distanceX.toStringAsFixed(2)} y: ${distanceY.toStringAsFixed(2)} z: ${distanceZ.toStringAsFixed(2)}",
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:weatherapp/bloc/weather_bloc_bloc.dart';
import 'package:weatherapp/screens/home_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Future<Position> _positionFuture;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  void _fetchLocation() {
    setState(() {
      _positionFuture = _determinePosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Position>(
        future: _positionFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snap.hasError) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Location Error'),
                  content: Text(snap.error.toString()),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        //Navigator.pop(context, 'Cancel');
                        SystemNavigator.pop(); // Retry fetching location
                      },
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, 'OK');
                        _fetchLocation(); // Retry fetching location
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            });
            return const Center();
          } else if (snap.hasData) {
            return BlocProvider<WeatherBlocBloc>(
              create: (context) => WeatherBlocBloc()
                ..add(FetchWeather(snap.data as Position)),
              child: const HomeScreen(),
            );
          } else {
            return const Center(child: Text('Location not available.'));
          }
        },
      ),
    );
  }
}

/// Determine the current position of the device.
Future<Position> _determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return Future.error(
      'Location permissions are permanently denied, we cannot request permissions.',
    );
  }

  return await Geolocator.getCurrentPosition();
}

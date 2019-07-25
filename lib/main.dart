import 'dart:convert';
import 'package:flutter/material.dart';
import './models/user.dart';
import './routes/category/category_page.dart';
import './global_components/navbar.dart';
import './models/country.dart';
import './utils/locationUtil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'global_components/api.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'JustMusic',
        theme: ThemeData(canvasColor: Colors.transparent),
        home: AppScreen());
  }
}

class AppScreen extends StatefulWidget {
  final User user;
  Widget navigatedPage;
  AppScreen({Key key, @required this.user, this.navigatedPage}) : super(key: key);

  @override
  _AppScreenState createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> with SingleTickerProviderStateMixin {
  Future<Country> countryFuture;
  Country userCountry;
  Widget currentPage;
  Animation<double> _animation;
  AnimationController _animationController;
  FlutterSecureStorage _storage = FlutterSecureStorage();
  User user;

  void getSelectedPageFromChild(page) {
    setState((){
      currentPage = page;
    });
  }

  void initState() {
    Api(); //create an Api instance to determine which host the app should use
    if (widget.user == null) {
      _storage.read(key: "user").then((userJson) {
        if (userJson != null && jsonDecode(userJson)["user"].isNotEmpty) {
          UserApi.authenticateUser(jsonDecode(userJson)["user"]["contactInfo"]["phoneNumber"])
          .then((isValidUser){
            if (isValidUser == true){
              this.user = User.fromJson(jsonDecode(userJson));
              print("I am ${user.nickname} (from storage)");
            }else {
              _storage.delete(key: "user").catchError((error){
                print(error);
              });
            }
          });
        }else {
          user = null;
        }
      });
    }else {
      user = widget.user;
    }

    currentPage = widget.navigatedPage != null ? widget.navigatedPage : CategoryPage();
    countryFuture = getCountryInstance();
    countryFuture.then((country) {
      _storage.write(key: "country", value: Country.toJson(country));
        userCountry = country;
    });

    _animationController = AnimationController(
        vsync: this,
        duration: Duration(
            seconds: 2)); //specify the duration for the animation & include `this` for the vsyc
    _animation = Tween<double>(begin: 0, end: 100).animate(
        _animationController); //use Tween animation here, to animate between the values of 1.0 & 2.5.

    _animation.addListener(() {
      //here, a listener that rebuilds our widget tree when animation.value changes
      setState(() {});
      print("dsfd");
    });

    _animation.addStatusListener((status) {
      //AnimationStatus gives the current status of our animation, we want to go back to its previous state after completing its animation
      if (status == AnimationStatus.completed) {
        _animationController
            .reverse(); //reverse the animation back here if its completed
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: countryFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Scaffold(
                body: Stack(
                    children: [
                      currentPage,
                      widget.navigatedPage != null ?
                      NavBar(user: user, getSelectedPageFromChild: getSelectedPageFromChild, currentPage: widget.navigatedPage):
                      NavBar(user: user, getSelectedPageFromChild: getSelectedPageFromChild),
                    ]));
          }else if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return Scaffold(body: Stack(children: [Center(child: CircularProgressIndicator()), NavBar(user: user, getSelectedPageFromChild: getSelectedPageFromChild)]));
          } else if (snapshot.hasError) {
            return Center(
                child: Column(children: <Widget>[
                  Text('Error: ${snapshot.error}',
                      style:
                      TextStyle(fontSize: 14.0, color: Colors.white)),
                  RaisedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("Exit"),
                      textColor: Colors.white,
                      elevation: 7.0,
                      color: Colors.blue)
                ]));
          }else{
            return Center();
          }
        });

  }
}

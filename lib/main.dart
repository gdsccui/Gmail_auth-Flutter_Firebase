import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomeScreen(),
    );
  }
}

/*
 *** Pre-req for Gmail Auth ***

 - SHA-1 Key must be placed in Firebase project settings
 - You can generate SHA-1 Key using following Command:
  keytool -list -v -keystore "C:\Users\<Username>\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
 
 - Enable the Google Auth from Firebase authentication panel
 - Also made the following changes to you android/app/build.gradle
      defaultConfig {
        minSdkVersion 21
        multiDexEnabled true
        ...
      }
  - Use the compatible plugins as mentioned in pubspec.yaml
 */

// SHA key for Debug and Release mode
// https://stackoverflow.com/questions/15727912/sha-1-fingerprint-of-keystore-certificate

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("Firebase Auth Gmail"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Login via Gmail",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
            ),
            RaisedButton(
              color: Colors.redAccent[200],
              onPressed: () {
                // Method for Gmail Authentication
                _signInGmail(context);
                // _googleSignIn.signOut();
              },
              child: Text(
                "Gmail Login",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  // objects for GoogleSignIn & FirebaseAuth
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<FirebaseUser> _signInGmail(BuildContext context) async {
    // flag: to check if user has been logged in successfully or not
    bool isLoggedIn;
    // flag: to check if user is already logged in or not
    bool isAlreadyLoggedIn = await _googleSignIn.isSignedIn();
    setState(() {
      isLoggedIn = isAlreadyLoggedIn;
    });

    // FirebaseUser object to hold various information like User Picture, Email, Name etc.
    FirebaseUser user;

    // Now we check if user is already logged in then do nothing just return the user, if not then do Gmail auth
    if (isLoggedIn) {
      // If user is already logged in: return user;
      user = await _auth.currentUser();
    } else {
      // else do the Gmail auth
      // getting the Google account which will be logging in
      GoogleSignInAccount gmailUser = await _googleSignIn.signIn();
      // authenticating the google account
      GoogleSignInAuthentication googleSignInAuthentication =
          await gmailUser.authentication;
      // getting the credentials
      final AuthCredential authCredential = GoogleAuthProvider.getCredential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);
      // login the user
      user = await _auth.signInWithCredential(authCredential);
      // changing the flag when the user is logged in successfully
      isAlreadyLoggedIn = await _googleSignIn.isSignedIn();
      setState(() {
        isLoggedIn = isAlreadyLoggedIn;
      });

      // Navigate to next screen
      var gmailUserSignedIn = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(
            // passing the FirebaseUser object to get information like picture, email, name etc.
            user: user,
            // passing the googleSignIn object to logout of the firebase
            googleSignIn: _googleSignIn,
          ),
        ),
      );

      // setting the flag when user navigate to new screen after login
      setState(() {
        isLoggedIn = gmailUserSignedIn == null ? true : false;
      });
    }
    // returning the user
    return user;
  }
}

class WelcomeScreen extends StatelessWidget {
  final FirebaseUser user;
  final GoogleSignIn googleSignIn;
  WelcomeScreen({this.user, this.googleSignIn});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text("Welcome Screen"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              maxRadius: 80,
              backgroundImage: NetworkImage(user.photoUrl),
            ),
            Text(
              user.displayName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
            ),
            Text(
              user.email,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w200),
            ),
            RaisedButton(
              color: Colors.orange,
              onPressed: () {
                googleSignIn.signOut();
                Navigator.pop(context);
              },
              child: Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}

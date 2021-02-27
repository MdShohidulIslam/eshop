import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_shop/Widgets/customTextField.dart';
import 'package:e_shop/DialogBox/errorDialog.dart';
import 'package:e_shop/DialogBox/loadingDialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart';
import 'package:image_picker/image_picker.dart';
import '../Store/storehome.dart';
import 'package:e_shop/Config/config.dart';



class Register extends StatefulWidget {
  @override
  _RegisterState createState() => _RegisterState();
}



class _RegisterState extends State<Register>
{
  final TextEditingController _nameTextEiditingController = TextEditingController();
  final TextEditingController _emailTextEiditingController = TextEditingController();
  final TextEditingController _passwordTextEiditingController = TextEditingController();
  final TextEditingController _cPasswordTextEiditingController = TextEditingController();
  final GlobalKey<FormState> _formKey= GlobalKey<FormState>();
  String userImageUrl = "";
  File _imageFile;
  @override
  Widget build(BuildContext context) {
    double _screenWidth = MediaQuery.of(context).size.width, _screenHeight = MediaQuery.of(context).size.height;
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: 10.0,),
            InkWell(
              onTap: _selectAndPickImage,
              child: CircleAvatar(
                radius: _screenWidth *0.15,
                backgroundColor: Colors.white,
                backgroundImage: _imageFile == null ? null : FileImage(_imageFile),
                child: _imageFile == null
                  ? Icon(Icons.add_photo_alternate, size: _screenWidth * 0.15, color: Colors.grey,)
                    :null,
              ),
            ),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: _nameTextEiditingController,
                    data: Icons.person,
                    hintText: "Name",
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: _emailTextEiditingController,
                    data: Icons.email,
                    hintText: "Email",
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: _passwordTextEiditingController,
                    data: Icons.person,
                    hintText: "Password",
                    isObsecure: true,
                  ),
                  CustomTextField(
                    controller: _cPasswordTextEiditingController,
                    data: Icons.person,
                    hintText: "Confirm Password",
                    isObsecure: true,
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.0,),

            RaisedButton(
              onPressed: (){
                uploadAndSaveImage();
              },
              color: Colors.pink,
              child: Text("Sign Up", style: TextStyle(color: Colors.white),),
            ),
            SizedBox(
              height: 30.0,
            ),
            Container(
              height: 4.0,
              width: _screenWidth * 0.8,
              color: Colors.pink,
            ),
            SizedBox(
              height: 15.0,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectAndPickImage() async{
    _imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
  }

  Future<void> uploadAndSaveImage(){
    if(_imageFile == null){
      showDialog(context: context,
      builder: (c){
        return ErrorAlertDialog(message: "Please Select an Image",);
      }
      );
    }
    else{
      _passwordTextEiditingController.text == _cPasswordTextEiditingController.text
          ? _emailTextEiditingController.text.isNotEmpty &&
          _passwordTextEiditingController.text.isNotEmpty &&
          _cPasswordTextEiditingController.text.isNotEmpty &&
          _nameTextEiditingController.text.isNotEmpty

          ? uploadToStorage()
          : displayDialog("Please Fill up the Registration complete form.")
          : displayDialog("Password do not Match");
    }
  }
  displayDialog(String msg){
    showDialog(
      context: context,
      builder: (c){
        return ErrorAlertDialog(message: msg,);
      }
    );
  }
  uploadToStorage() async
  {
    showDialog(
        context: context,
    builder: (c)
    {
      return LoadingAlertDialog(message: "Registering, Please wait.......",);
    }
    );
    String imageFileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference storageReference = FirebaseStorage.instance.ref().child(imageFileName);
    StorageUploadTask storageUploadTask = storageReference.putFile(_imageFile);
    StorageTaskSnapshot taskSnapshot = await storageUploadTask.onComplete;
    await taskSnapshot.ref.getDownloadURL().then((urlImage){
      userImageUrl = urlImage;

      _registerUser();

    });
  }

  FirebaseAuth _auth = FirebaseAuth.instance;
  _registerUser() async{
    FirebaseUser firebaseUser;
    await _auth.createUserWithEmailAndPassword(email: _emailTextEiditingController.text.trim(), password: _passwordTextEiditingController.text.trim(),

    ).then((auth){
      firebaseUser = auth.user;
    }).catchError((error){
      Navigator.pop(context);
      showDialog(context: context,
      builder: (c){
        return ErrorAlertDialog(message: error.message.toString(),);
      }
      );
    });
    if(firebaseUser != null){
      saveUserInfoToFireStore(firebaseUser).then((value){
        Navigator.pop(context);
        Route route = MaterialPageRoute(builder: (c) => StoreHome());
        Navigator.pushReplacement(context, route);
      });
    }
  }
  Future saveUserInfoToFireStore(FirebaseUser fUser) async
  {
      Firestore.instance.collection("users").document(fUser.uid).setData({
        "uid": fUser.uid,
        "email": fUser.email,
        "name": _nameTextEiditingController.text.trim(),
        "url": userImageUrl,
        EcommerceApp.userCartList: ["garbageValue"],
      });

      await EcommerceApp.sharedPreferences.setString("uid", fUser.uid);
      await EcommerceApp.sharedPreferences.setString(EcommerceApp.userName, fUser.email);
      await EcommerceApp.sharedPreferences.setString(EcommerceApp.userName, _nameTextEiditingController.text);
      await EcommerceApp.sharedPreferences.setString(EcommerceApp.userAvatarUrl, userImageUrl);
      await EcommerceApp.sharedPreferences.setStringList(EcommerceApp.userCartList, ["garbageValue"]);
  }
}


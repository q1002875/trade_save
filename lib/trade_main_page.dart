import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:trade_save/googleSeets.dart';

class GoogleSignInScreen extends StatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  _GoogleSignInScreenState createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends State<GoogleSignInScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount? _user;
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google 登錄'),
        actions: [
          IconButton(
            icon: _user != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(_user!.photoUrl ?? ''),
                  )
                : const Icon(Icons.person),
            onPressed: () {
              if (_user != null) {
                // 顯示確認登出對話框
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('登出確認'),
                      content: const Text('您確定要登出嗎？'),
                      actions: <Widget>[
                        TextButton(
                          child: const Text('取消'),
                          onPressed: () {
                            Navigator.of(context).pop(); // 關閉對話框
                          },
                        ),
                        TextButton(
                          child: const Text('登出'),
                          onPressed: () {
                            _signOut(); // 執行登出操作
                            Navigator.of(context).pop(); // 關閉對話框
                          },
                        ),
                      ],
                    );
                  },
                );
              } else {
                _signIn(); // 如果未登錄則執行登錄操作
              }
            },
          ),
        ],
      ),
      body: const GoogleSheetsExample(),
    );
  }

  Future<void> _signIn() async {
    try {
      _user = await _googleSignIn.signIn();
      setState(() {
        // _message = '登錄成功！';
        // // print(_user.id);
        // print('${_googleSignIn.serverClientId}');

        // 將用戶資料傳遞至 GoogleSheetsExample
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => GoogleSheetsExample(user: _user!),
        //   ),
        // );
      });
    } catch (error) {
      setState(() {
        _message = '登錄失敗：$error';
      });
    }
  }

  Future<void> _signOut() async {
    await _googleSignIn.signOut();
    setState(() {
      _user = null;
      _message = '已登出';
    });
  }
}

import 'dart:io';

import 'util/common_imports.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Photos upload')),
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : TextButton(
                onPressed: () => pickAndUploadFile(),
                child: const Text('Upload Image'),
              ),
      ),
    );
  }

  pickAndUploadFile() async {
    loading = true;
    setState(() {});
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      File file = File(result.files.single.path!);
      await PhotosService().uploadPhoto(file: file);
      loading = false;
      setState(() {});
    }
  }
}

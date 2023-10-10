import 'dart:async';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SaveCall extends StatefulWidget {
  const SaveCall({Key? key}) : super(key: key);

  @override
  State<SaveCall> createState() => _SaveCallState();
}

class _SaveCallState extends State<SaveCall> {
  static const batteryChannel = MethodChannel("com.example.headset_call/battery");
  String text = "Stop Service";
  late final Timer timer;
  List<String> logs = [];
  final headsetPlugin = HeadsetEvent();
  HeadsetState? _headsetState;
  bool popStatus = false;
  final numberCon = TextEditingController();
  late String savedNum;
  dynamic phoneNumber;

  @override
  void initState() {
    checkHeadsetConnectionStatus();
    initialize();
    super.initState(); 
  }
  
  initialize()async{
    //Check if phone number is empty
    var checkNo = await getStoredNumber();
    if(checkNo == null || checkNo == ""){
      popStatus = false;
      showPopUp();
    } else{
      popStatus = true;
    }
    setState(() {});
  }

  checkHeadsetConnectionStatus() async{
    headsetPlugin.requestPermission();
    var currentStatus = await headsetPlugin.getCurrentState;
    setState(() {
        _headsetState = currentStatus;
      });
    headsetPlugin.setListener((val) {
      setState(() {
          _headsetState = val;
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    numberCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 200,),
              //Device Info
              StreamBuilder<Map<String, dynamic>?>(
                stream: FlutterBackgroundService().on('update'),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final data = snapshot.data!;
                  String? device = data["device"];
                  DateTime? date = DateTime.tryParse(data["current_date"]);
                  return Column(
                    children: [
                      Text(device ?? 'Unknown'),
                      Text(date.toString()),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20,),
              //Headset Status
              Icon(
                Icons.headset,
                size: 35,
                color: _headsetState == HeadsetState.CONNECT
                    ? Colors.green
                    : Colors.red,
              ),
              const SizedBox(height: 10,),
              Text('State : ${_headsetState ?? "Not Connected"}\n', style: const TextStyle(fontSize: 16),),
              const SizedBox(height: 35,),
              ElevatedButton(
                child: const Text("Foreground Mode"),
                onPressed: () {
                  FlutterBackgroundService().invoke("setAsForeground");
                },
              ),
              const SizedBox(height: 20,),
              ElevatedButton(
                child: const Text("Background Mode"),
                onPressed: () {
                  FlutterBackgroundService().invoke("setAsBackground");
                },
              ),
              const SizedBox(height: 20,),
              //Stop App
              ElevatedButton(
                child: Text(text),
                onPressed: () async {
                  final service = FlutterBackgroundService();
                  var isRunning = await service.isRunning();
                  if (isRunning) {
                    service.invoke("stopService");
                  } else {
                    service.startService();
                  }
      
                  if (!isRunning) {
                    text = 'Stop Service';
                  } else {
                    text = 'Start Service';
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 20,),
              // Change Number
              InkWell(
                child: Container(
                  height: 45,
                  width: 150,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(
                    left: 10.0,
                    right: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(255, 223, 223, 223),
                        offset: Offset(0, 5),
                        blurRadius: 5
                      )
                    ]
                  ),
                  child: const Text("Change Number", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),)
                ),
                onTap: (){
                  showPopUp();
                },
              ),
              const SizedBox(height: 20,),
              //Test Call
              InkWell(
                child: Container(
                  height: 60,
                  width: 150,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromARGB(255, 223, 223, 223),
                        offset: Offset(0, 5),
                        blurRadius: 5
                      )
                    ]
                  ),
                  child: const Text("Test Saved Number", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.center,)
                ),
                onTap: (){
                  callNumber();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //Store number
  Future<void> storeNumber(String number) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phoneNumber', number);
  }

  //Return Number to retrieve store number 
  getStoredNumber() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedNumber = prefs.getString('phoneNumber');
    return storedNumber;
  }

  //Call number
  callNumber() async{//set the number here
    var contact = await getStoredNumber();
    AndroidIntent intent = AndroidIntent(
      action: 'android.intent.action.CALL',
      data: 'tel:${contact ?? "9863021878"}',
    );
    await intent.launch();
  }

  //Show Pop Up
  showPopUp() async{
    var checkNumber = await getStoredNumber();
    if(checkNumber == null || checkNumber == ""){
      popStatus = false;
      // ignore: use_build_context_synchronously
      return showDialog(
        context: context, 
        builder: (context){
          return WillPopScope(
            onWillPop: ()async => popStatus,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              title: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Enter a Contact that you want to call", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                      const SizedBox(height: 20,),
                      Container(
                        height: 60,
                        width: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 223, 223, 223),
                              offset: Offset(0, 5),
                              blurRadius: 5
                            )
                          ]
                        ),
                        child: TextFormField(
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(15),
                            border: InputBorder.none,
                            labelText: "Enter a contact",
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val){
                            phoneNumber = val;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 20,),
                      //Save Contact to Shared prefrence
                      ElevatedButton(
                        onPressed: () {
                          if(phoneNumber != "" && phoneNumber!=null){
                            setState(() {
                              storeNumber(phoneNumber);
                              popStatus = true;
                            });
                            Navigator.pop(context);
                          } else{
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(milliseconds: 1000),
                                backgroundColor: Colors.red.withOpacity(0.9),
                                dismissDirection: DismissDirection.up,
                                margin: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).size.height - 100,
                                  right: 20,
                                  left: 20),
                                behavior: SnackBarBehavior.floating,
                                content: const Text("Please Enter a Contact First.", style: TextStyle(color: Colors.white),),
                              )
                            );
                          }
                        }, 
                        child: const Text("Save")
                      ),
                    ],
                  ),
                ),
              )
            ),
          );
        },
      );
    } else{
      popStatus = true;
      return showDialog(
        context: context, 
        builder: (context){
          return WillPopScope(
            onWillPop: ()async => popStatus,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              title: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Enter a Contact that you want to call", style: TextStyle(fontSize: 18), textAlign: TextAlign.center,),
                      const SizedBox(height: 20,),
                      Text("Prev Contact: ${checkNumber ?? "No Data"}", style: const TextStyle(fontSize: 12), textAlign: TextAlign.center,),
                      Container(
                        height: 60,
                        width: 200,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.only(
                          left: 10.0,
                          right: 10.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: const [
                            BoxShadow(
                              color: Color.fromARGB(255, 223, 223, 223),
                              offset: Offset(0, 5),
                              blurRadius: 5
                            )
                          ]
                        ),
                        child: TextFormField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.all(15),
                            border: InputBorder.none,
                            labelText: "Enter a contact",
                          ),
                          onChanged: (val){
                            phoneNumber = val;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(height: 20,),
                      //Save Contact to Shared prefrence
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog<bool>(
                            context: context,
                            builder: (context) => WillPopScope(
                              onWillPop: () async=> false,
                              child: AlertDialog(
                                title: const Text("You will need to restart the App to change the contact."),
                                actions: [
                                  TextButton(
                                    onPressed: () async{
                                      //Stop Service
                                      final service = FlutterBackgroundService();
                                      var isRunning = await service.isRunning();
                                      if (isRunning) {
                                        service.invoke("stopService");
                                      } else {
                                        service.startService();
                                      }
                          
                                      if (!isRunning) {
                                        text = 'Stop Service';
                                      } else {
                                        text = 'Start Service';
                                      }
                                      //Save Number and pop
                                      if(phoneNumber != "" && phoneNumber!=null){
                                        setState(() {
                                          storeNumber(phoneNumber);
                                          popStatus = true;
                                        });
                                        SystemNavigator.pop();
                                      } else{
                                        setState(() {
                                          storeNumber(checkNumber);
                                          popStatus = true;
                                        });
                                        SystemNavigator.pop();
                                      }
                                    },
                                    child: const Text("OK")
                                  ),
                                ],
                              ),
                            )
                          );
                        }, 
                        child: const Text("Save")
                      ),
                    ],
                  ),
                ),
              )
            ),
          );
        },
      );
    }
  }
}
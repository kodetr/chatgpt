import 'dart:developer';
import 'package:chatgpt/constants/constants.dart';
import 'package:chatgpt/constants/shared_preference.dart';
import 'package:chatgpt/providers/chats_provider.dart';
import 'package:chatgpt/services/services.dart';
import 'package:chatgpt/widgets/chat_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../providers/models_provider.dart';
import '../services/assets_manager.dart';
import '../widgets/text_widget.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isTyping = false;
  bool clikVolume = false;

  late TextEditingController textEditingController;
  late TextEditingController textCtlKey;
  late ScrollController _listScrollController;
  late FocusNode focusNode;

  void apiKey() async {
    textCtlKey.text = await SharePrefrenceAPI.getKey();
  }

  void speak() async {
    clikVolume = await SharePrefrenceAPI.getSpeak();
  }

  @override
  void initState() {
    _listScrollController = ScrollController();
    textEditingController = TextEditingController();
    textCtlKey = TextEditingController();
    focusNode = FocusNode();

    speak();

    super.initState();
    setState(() {
      apiKey();
    });
  }

  @override
  void dispose() {
    _listScrollController.dispose();
    textEditingController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  // List<ChatModel> chatList = [];
  @override
  Widget build(BuildContext context) {
    final modelsProvider = Provider.of<ModelsProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 2,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(AssetsManager.openaiLogo),
        ),
        title: const Text("Smart Chat"),
        actions: [
          IconButton(
            onPressed: () async {
              if (clikVolume) {
                clikVolume = false;
                await SharePrefrenceAPI.setSpeak(false);
              } else {
                clikVolume = true;
                await SharePrefrenceAPI.setSpeak(true);
              }
              setState(() {});
            },
            icon: Icon(clikVolume ? Icons.volume_down : Icons.volume_off),
          ),
          IconButton(
            onPressed: () {
              dialogSaveAPI();
            },
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            onPressed: () async {
              await Services.showModalSheet(context: context);
            },
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Flexible(
              child: ListView.builder(
                controller: _listScrollController,
                itemCount: chatProvider.getChatList.length, //chatList.length,
                itemBuilder: (context, index) {
                  return ChatWidget(
                    msg: chatProvider
                        .getChatList[index].msg, // chatList[index].msg,
                    chatIndex: chatProvider.getChatList[index]
                        .chatIndex, //chatList[index].chatIndex,
                  );
                },
              ),
            ),
            if (_isTyping) ...[
              const SpinKitThreeBounce(
                color: Colors.white,
                size: 18,
              ),
            ],
            const SizedBox(
              height: 15,
            ),
            Material(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        focusNode: focusNode,
                        style: const TextStyle(color: Colors.white),
                        controller: textEditingController,
                        onSubmitted: (value) async {
                          await sendMessageFCT(
                              modelsProvider: modelsProvider,
                              chatProvider: chatProvider);
                        },
                        decoration: const InputDecoration.collapsed(
                          hintText: "Apa yang bisa saya bantu?",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await sendMessageFCT(
                          modelsProvider: modelsProvider,
                          chatProvider: chatProvider,
                        );
                      },
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void scrollListToEND() {
    _listScrollController.animateTo(
        _listScrollController.position.maxScrollExtent,
        duration: const Duration(seconds: 2),
        curve: Curves.easeOut);
  }

  Future<void> sendMessageFCT(
      {required ModelsProvider modelsProvider,
      required ChatProvider chatProvider}) async {
    if (_isTyping) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "Anda tidak dapat mengirim banyak pesan sekaligus",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (textEditingController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: TextWidget(
            label: "Silakan ketik pesan",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      String msg = textEditingController.text;
      setState(() {
        _isTyping = true;
        // chatList.add(ChatModel(msg: textEditingController.text, chatIndex: 0));
        chatProvider.addUserMessage(msg: msg);
        textEditingController.clear();
        focusNode.unfocus();
      });
      await chatProvider.sendMessageAndGetAnswers(
          msg: msg, chosenModelId: modelsProvider.getCurrentModel);
      // chatList.addAll(await ApiService.sendMessage(
      //   message: textEditingController.text,
      //   modelId: modelsProvider.getCurrentModel,
      // ));
      setState(() {});
    } catch (error) {
      log("error $error");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: TextWidget(
          label: error.toString(),
        ),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() {
        scrollListToEND();
        _isTyping = false;
      });
    }
  }

  void dialogSaveAPI() {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('API KEY'),
        content: const Text('Masukan Api Key Openai Anda yang sudah terdaftar'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 10),
            child: TextField(
              controller: textCtlKey,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          TextButton(
            onPressed: () async {
              await SharePrefrenceAPI.setKey(textCtlKey.text);
              Navigator.pop(context, 'Simpan');
              setState(() {});
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

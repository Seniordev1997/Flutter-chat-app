import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:whatsapp_clone/features/chat/views/widgets/attachment_renderers.dart';
import 'package:whatsapp_clone/theme/theme.dart';

import '../../../../shared/models/user.dart';
import '../../../../shared/utils/abc.dart';
import '../../../../shared/utils/storage_paths.dart';
import '../../controllers/chat_controller.dart';
import '../../models/attachement.dart';
import '../../models/message.dart';

class AttachmentMessageSender extends ConsumerStatefulWidget {
  const AttachmentMessageSender({
    super.key,
    required this.attachments,
  });

  final List<Attachment> attachments;

  @override
  ConsumerState<AttachmentMessageSender> createState() =>
      _AttachmentMessageSenderState();
}

class _AttachmentMessageSenderState
    extends ConsumerState<AttachmentMessageSender> {
  late User self;
  late User other;
  late Attachment current;
  late List<TextEditingController> controllers;
  bool isKeyboardVisible = false;
  late List<Attachment> attachments = widget.attachments;
  late StreamSubscription<bool> keyboardListener;

  @override
  void initState() {
    self = ref.read(chatControllerProvider.notifier).self;
    other = ref.read(chatControllerProvider.notifier).other;
    current = attachments[0];
    controllers = attachments.map((_) => TextEditingController()).toList();

    keyboardListener = KeyboardVisibilityController().onChange.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          isKeyboardVisible = event;
        });
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    keyboardListener.cancel();
    for (var controller in controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorTheme = Theme.of(context).custom.colorTheme;
    final currentType = current.type;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? colorTheme.backgroundColor
          : const Color.fromARGB(236, 225, 233, 235),
      body: Stack(
        children: [
          Center(
            child: KeyboardDismissOnTap(
              child: AttachmentRenderer(
                attachment: current.file!,
                attachmentType: currentType,
                fit: BoxFit.contain,
                controllable: true,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(
              top: 48,
              bottom: isKeyboardVisible ? 12 : 48,
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: const CircleAvatar(
                      backgroundColor: Color.fromARGB(100, 0, 0, 0),
                      foregroundColor: Colors.white,
                      child: Icon(
                        Icons.close,
                      ),
                    ),
                  ),
                  trailing: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        backgroundColor: Color.fromARGB(100, 0, 0, 0),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.crop),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Color.fromARGB(100, 0, 0, 0),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.sticky_note_2),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Color.fromARGB(100, 0, 0, 0),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.text_format_outlined),
                      ),
                      SizedBox(width: 8),
                      CircleAvatar(
                        backgroundColor: Color.fromARGB(100, 0, 0, 0),
                        foregroundColor: Colors.white,
                        child: Icon(Icons.draw),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Offstage(
                  offstage: isKeyboardVisible,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          child: const Icon(Icons.arrow_back_ios),
                          onTap: () {
                            final index = attachments.indexOf(current);
                            if (index == 0) return;
                            setState(() {
                              current = attachments[index - 1];
                            });
                          },
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 60,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: attachments.length,
                              itemBuilder: (context, idx) {
                                final attachment = attachments[idx];
                                final attachmentType = attachment.type;

                                return Center(
                                  child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          current = attachment;
                                        });
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: current == attachment
                                              ? Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                )
                                              : null,
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              SizedBox(
                                                height: 50,
                                                width: 50,
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: AttachmentRenderer(
                                                    attachment:
                                                        attachment.file!,
                                                    attachmentType:
                                                        attachmentType,
                                                    fit: BoxFit.cover,
                                                    compact: true,
                                                  ),
                                                ),
                                              ),
                                              if (current == attachment) ...[
                                                Container(
                                                  width: 50,
                                                  height: 50,
                                                  color: Colors.black38,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      if (attachments.length ==
                                                          1) {
                                                        Navigator.pop(context);
                                                        return;
                                                      }
                                                      setState(() {
                                                        final idx = attachments
                                                            .indexOf(current);
                                                        attachments
                                                            .removeAt(idx);
                                                        controllers[idx]
                                                            .dispose();
                                                        controllers
                                                            .removeAt(idx);
                                                        current =
                                                            attachments.first;
                                                      });
                                                    },
                                                    child: const Icon(
                                                      Icons.delete,
                                                      color: Colors.white,
                                                      size: 32,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      )),
                                );
                              },
                              separatorBuilder: (context, idx) {
                                return const SizedBox(width: 10);
                              },
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            final index = attachments.indexOf(current);
                            if (index == attachments.length - 1) {
                              return;
                            }
                            setState(() {
                              current = attachments[index + 1];
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.0),
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? colorTheme.appBarColor
                                    : const Color.fromARGB(
                                        255,
                                        242,
                                        251,
                                        254,
                                      ),
                          ),
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 4,
                                    bottom: 12.0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final newAttachments = await ref
                                          .read(chatControllerProvider.notifier)
                                          .pickAttachmentsFromGallery(
                                            context,
                                            returnAttachments: true,
                                          );
                                      if (newAttachments == null) return;
                                      setState(() {
                                        attachments.addAll(newAttachments);
                                        controllers.addAll(
                                          List.generate(
                                            newAttachments.length,
                                            (_) => TextEditingController(),
                                          ),
                                        );
                                      });
                                    },
                                    child: Icon(
                                      Icons.add_box_rounded,
                                      size: 24.0,
                                      color: colorTheme.greyColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 8.0,
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: controllers[
                                        attachments.indexOf(current)],
                                    maxLines: 6,
                                    minLines: 1,
                                    cursorColor: colorTheme.greenColor,
                                    cursorHeight: 20,
                                    style: Theme.of(context)
                                        .custom
                                        .textTheme
                                        .bodyText1,
                                    decoration: InputDecoration(
                                      hintText: 'Message',
                                      hintStyle: Theme.of(context)
                                          .custom
                                          .textTheme
                                          .bodyText1
                                          .copyWith(),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 8.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 4.0,
                      ),
                      InkWell(
                        onTap: () async {
                          for (var i = 0; i < controllers.length; i++) {
                            final attachment = attachments[i];

                            String messageId = const Uuid().v4();
                            String msgContent = controllers[i].text.trim();
                            if (msgContent.isEmpty &&
                                attachment.type == AttachmentType.document) {
                              msgContent = "\u00A0";
                            }

                            await attachment.file!.copy(
                              DeviceStorage.getMediaFilePath(
                                attachment.fileName,
                              ),
                            );

                            ref
                                .read(chatControllerProvider.notifier)
                                .sendMessageWithAttachments(
                                  Message(
                                    id: messageId,
                                    content: msgContent,
                                    status: MessageStatus.pending,
                                    senderId: self.id,
                                    receiverId: other.id,
                                    timestamp: Timestamp.now(),
                                    attachment: attachment
                                      ..uploadStatus = UploadStatus.uploading,
                                  ),
                                );
                          }

                          if (!mounted) return;
                          Navigator.of(context).pop();
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: colorTheme.greenColor,
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                if (isKeyboardVisible) ...[
                  SizedBox(
                    height: getKeyboardHeight(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

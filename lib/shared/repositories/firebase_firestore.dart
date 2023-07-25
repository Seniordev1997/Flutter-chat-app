import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:whatsapp_clone/features/chat/models/message.dart';
import 'package:whatsapp_clone/shared/models/user.dart';

import 'isar_db.dart';

final firebaseFirestoreRepositoryProvider = Provider(
  (ref) => FirebaseFirestoreRepo(firestore: FirebaseFirestore.instance),
);

class FirebaseFirestoreRepo {
  final FirebaseFirestore firestore;

  const FirebaseFirestoreRepo({
    required this.firestore,
  });

  Future<void> setActivityStatus({
    required String userId,
    required String statusValue,
  }) async {
    await firestore
        .collection('users')
        .doc(userId)
        .update({'activityStatus': statusValue});
  }

  Stream<UserActivityStatus> userActivityStatusStream({required userId}) {
    return firestore.collection('users').doc(userId).snapshots().map((event) {
      return UserActivityStatus.fromValue(event.data()!['activityStatus']);
    });
  }

  Future<void> sendMessage(Message message) async {
    await firestore
        .collection('chats')
        .doc(message.receiverId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Future<void> sendReplacementMessage({
    required Message message,
    required String receiverId,
  }) async {
    await firestore
        .collection('chats')
        .doc(receiverId)
        .collection('messages')
        .doc(message.id)
        .set(message.toMap());
  }

  Future<User?> getUserById(String id) async {
    final documentSnapshot = await firestore.collection('users').doc(id).get();

    return documentSnapshot.exists
        ? User.fromMap(documentSnapshot.data()!)
        : null;
  }

  Stream<List<Message>> getChatStream(String ownId) {
    return firestore
        .collection('chats')
        .doc(ownId)
        .collection('messages')
        .snapshots()
        .asyncMap(
      (querySnap) async {
        final messages = <Message>[];

        for (final docChange in querySnap.docChanges) {
          if (docChange.type == DocumentChangeType.removed) continue;

          final docData = docChange.doc.data()!;
          docChange.doc.reference.delete();

          final message = Message.fromMap(docData);
          if (message.type == MessageType.replacementMessage) {
            await IsarDb.updateMessage(message.id, message);
            continue;
          }

          messages.add(message);
        }

        return messages;
      },
    );
  }

  Future<User?> getUserByPhone(String phoneNumber) async {
    phoneNumber = phoneNumber
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('(', '')
        .replaceAll(')', '');

    QuerySnapshot<Map<String, dynamic>> snap;
    if (phoneNumber.startsWith('+')) {
      snap = await firestore
          .collection('users')
          .where('phone.rawNumber', isEqualTo: phoneNumber)
          .get();
    } else {
      snap = await firestore
          .collection('users')
          .where('phone.number', isEqualTo: phoneNumber)
          .get();
    }

    return snap.size == 0 ? null : User.fromMap(snap.docs[0].data());
  }
}

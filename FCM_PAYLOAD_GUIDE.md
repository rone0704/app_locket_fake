# FCM Payload Guide

Tai lieu nay mo ta payload chuan de backend (Cloud Functions hoac server rieng) gui push notification den app.

## 1. Data payload de mo bai viet

Dung payload duoi day de app mo dung bai viet khi nguoi dung cham notification:

```json
{
  "schemaVersion": "1",
  "event": "newPost",
  "postId": "POST_ID_HERE",
  "relatedPostId": "POST_ID_HERE",
  "relatedUserId": "SENDER_UID_HERE",
  "deepLink": "locketfake://post/POST_ID_HERE"
}
```

## 2. FCM HTTP v1 message mau

```json
{
  "message": {
    "token": "USER_DEVICE_FCM_TOKEN",
    "notification": {
      "title": "Ban be vua dang anh moi",
      "body": "Nhan de mo bai viet moi nhat"
    },
    "data": {
      "schemaVersion": "1",
      "event": "newPost",
      "postId": "POST_ID_HERE",
      "relatedPostId": "POST_ID_HERE",
      "relatedUserId": "SENDER_UID_HERE",
      "deepLink": "locketfake://post/POST_ID_HERE"
    },
    "android": {
      "priority": "HIGH"
    },
    "apns": {
      "payload": {
        "aps": {
          "sound": "default"
        }
      }
    }
  }
}
```

## 3. Field quan trong

- postId: id bai viet de app mo Feed dung vi tri.
- deepLink: backup cho truong hop backend khong gui postId.
- relatedUserId: uid nguoi dang bai, dung cho thong ke va mo rong sau nay.
- schemaVersion: version payload de de migrate sau nay.

## 4. Luu y trien khai backend

- Khong gui push truc tiep tu client bang server key.
- Nen doc token tu users/{uid}.fcmTokens.
- Khi token loi (unregistered), can xoa token khoi Firestore.

# Wevo chat model v0.1

## collections
- chats/{chatId}
  - users: [uidA, uidB]
  - matchId: string
  - createdAt
  - lastMessage
  - lastMessageAt
  - lastSenderId

- chats/{chatId}/messages/{messageId}
  - senderId
  - text
  - createdAt

## chatId
sorted uid pair joined with underscore

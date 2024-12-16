const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Function to send FCM notification when a new request is added
exports.sendDonationNotification = functions.firestore
  .document('donationRequests/{requestId}')
  .onCreate((snapshot, context) => {
    const data = snapshot.data();
    const message = {
      notification: {
        title: 'New Donation Request',
        body: `A new request for ${data.amount} has been posted. Please donate!`
      },
      topic: 'chat' // Send to all users subscribed to the 'allUsers' topic
    };

    return admin.messaging().send(message);
  });

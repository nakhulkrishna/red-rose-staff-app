/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");

const {onSchedule} = require("firebase-functions/v2/scheduler");


const admin = require("firebase-admin");
admin.initializeApp();

// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.
setGlobalOptions({maxInstances: 10});

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.deleteMonthlyOrders = onSchedule(
    {
      schedule: "0 0 1 * *", // At 00:00 on the 1st day of every month
      timeZone: "Asia/Kolkata", // Your timezone
    },
    async (event) => {
      const db = admin.firestore();
      const ordersSnapshot = await db.collection("orders").get();

      if (ordersSnapshot.empty) {
        console.log("No orders to delete.");
        return;
      }

      const batch = db.batch();
      ordersSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();
      console.log(`Deleted ${ordersSnapshot.size} orders successfully.`);
    },
);


exports.testDeleteOrders = onRequest(async (req, res) => {
  try {
    const db = admin.firestore();
    const ordersSnapshot = await db.collection("orders").get();

    if (ordersSnapshot.empty) {
      res.send("No orders to delete.");
      return;
    }

    const batch = db.batch();
    ordersSnapshot.docs.forEach((doc) => batch.delete(doc.ref));

    await batch.commit();
    res.send(`Deleted ${ordersSnapshot.size} orders successfully.`);
  } catch (error) {
    console.error(error);
    res.status(500).send("Error deleting orders.");
  }
});

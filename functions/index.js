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
const {onCall, HttpsError} = require("firebase-functions/v2/https");

const {onSchedule} = require("firebase-functions/v2/scheduler");


const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();

async function assertAdmin(context) {
  if (!context.auth || !context.auth.uid) {
    throw new HttpsError("unauthenticated", "Authentication is required.");
  }

  const snapshot = await db
      .collection("catalog_users")
      .doc(context.auth.uid)
      .get();
  const role = (snapshot.data()?.role || "").toString().toLowerCase();
  if (role !== "admin" && role !== "manager") {
    throw new HttpsError(
        "permission-denied",
        "Only admins/managers can ban or unban users.",
    );
  }
}

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

exports.banCatalogUser = onCall(async (request) => {
  await assertAdmin(request);

  const targetUid = (request.data?.uid || "").toString().trim();
  const reason = (request.data?.banReason || "").toString().trim();
  const days = Number(request.data?.days || 0);
  const customDateMs = Number(request.data?.banUntilMs || 0);

  if (!targetUid) {
    throw new HttpsError("invalid-argument", "Target uid is required.");
  }

  let banUntil = null;
  if (customDateMs > 0) {
    banUntil = admin.firestore.Timestamp.fromMillis(customDateMs);
  } else if (days > 0) {
    const until = new Date(Date.now() + days * 24 * 60 * 60 * 1000);
    banUntil = admin.firestore.Timestamp.fromDate(until);
  }

  if (!banUntil) {
    throw new HttpsError(
        "invalid-argument",
        "Provide either days or banUntilMs.",
    );
  }

  await db.collection("catalog_users").doc(targetUid).set({
    accountStatus: "banned",
    banUntil: banUntil,
    banReason: reason || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {
    uid: targetUid,
    accountStatus: "banned",
    banUntilMs: banUntil.toMillis(),
  };
});

exports.unbanCatalogUser = onCall(async (request) => {
  await assertAdmin(request);

  const targetUid = (request.data?.uid || "").toString().trim();
  if (!targetUid) {
    throw new HttpsError("invalid-argument", "Target uid is required.");
  }

  await db.collection("catalog_users").doc(targetUid).set({
    accountStatus: "active",
    banUntil: admin.firestore.FieldValue.delete(),
    banReason: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, {merge: true});

  return {uid: targetUid, accountStatus: "active"};
});

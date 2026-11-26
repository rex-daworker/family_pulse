'use strict';

const admin = require('firebase-admin');

/**
 * Firebase Admin, initialised once per worker process.
 *
 * The service account never lives in the repository. It is stored as the
 * FIREBASE_SERVICE_ACCOUNT application setting on the Function App — a single
 * JSON string — and read from the environment here. Azure encrypts application
 * settings at rest and injects them as environment variables at start-up,
 * which is the same contract a Kubernetes secret or a GitHub Actions secret
 * offers. The credential therefore exists in exactly two places: the Firebase
 * console that issued it, and the Function App configuration.
 *
 * Initialisation is lazy and memoised. Azure Functions reuses a warm worker
 * across invocations, so paying for admin.initializeApp() once per process
 * rather than once per request is the difference between a fast endpoint and
 * a slow one.
 */
let app = null;

function getApp() {
  if (app) return app;

  const raw = process.env.FIREBASE_SERVICE_ACCOUNT;
  if (!raw) {
    throw new Error(
      'FIREBASE_SERVICE_ACCOUNT is not set on this Function App. ' +
        'Set it with: az functionapp config appsettings set --name <app> ' +
        '--resource-group <rg> --settings FIREBASE_SERVICE_ACCOUNT=@<file>.json',
    );
  }

  let credentials;
  try {
    credentials = JSON.parse(raw);
  } catch (error) {
    throw new Error(
      'FIREBASE_SERVICE_ACCOUNT is set but is not valid JSON. It must be the ' +
        'entire service account file as a single string.',
    );
  }

  app = admin.initializeApp({
    credential: admin.credential.cert(credentials),
    projectId: credentials.project_id,
  });

  return app;
}

/** Verifies a Firebase ID token and returns its decoded claims. */
async function verifyIdToken(idToken) {
  return admin.auth(getApp()).verifyIdToken(idToken);
}

/** Firestore handle bound to the same credential. */
function firestore() {
  return admin.firestore(getApp());
}

module.exports = { getApp, verifyIdToken, firestore };

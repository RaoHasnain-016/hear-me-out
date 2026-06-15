// server.js
const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

// initialize admin SDK (make sure serviceAccountKey.json exists)
admin.initializeApp({
  credential: admin.credential.cert(require('./serviceAccountKey.json'))
});
const db = admin.firestore();

// --- Create user (Auth + optional custom claim) ---
app.post('/createUser', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    if (!email || !password) return res.json({ error: 'Email and password required' });

    const user = await admin.auth().createUser({ email, password, displayName: name });
    if (role === 'admin') await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    if (role === 'superadmin') await admin.auth().setCustomUserClaims(user.uid, { superadmin: true });

    // create Firestore doc with uid as id
    await db.collection('users').doc(user.uid).set({
      name: name || '',
      email,
      role: role || 'user',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      disabled: false
    });

    res.json({ uid: user.uid });
  } catch (e) {
    console.error(e);
    res.json({ error: e.message });
  }
});

// --- Update user (Auth & Firestore) ---
app.post('/updateUser', async (req, res) => {
  try {
    const { uid, name, email, role, password } = req.body;
    if (!uid) return res.json({ error: 'uid required' });
    // Update Auth user
    const updatePayload = {};
    if (name) updatePayload.displayName = name;
    if (email) updatePayload.email = email;
    if (password) updatePayload.password = password;
    if (Object.keys(updatePayload).length > 0) {
      await admin.auth().updateUser(uid, updatePayload);
    }
    // Update custom claims for role
    if (role) {
      // clear both claims then set appropriate
      const claims = {};
      if (role === 'admin') claims.admin = true;
      if (role === 'superadmin') claims.superadmin = true;
      await admin.auth().setCustomUserClaims(uid, claims);
    }
    // Update Firestore document
    const docRef = db.collection('users').doc(uid);
    await docRef.update({
      name: name || admin.firestore.FieldValue.delete(),
      email: email || admin.firestore.FieldValue.delete(),
      role: role || admin.firestore.FieldValue.delete(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }).catch(()=>{ /* ignore if doc absent */ });

    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.json({ error: e.message });
  }
});

// --- Delete user (Auth + Firestore) ---
app.post('/deleteUser', async (req, res) => {
  try {
    const { uid } = req.body;
    if (!uid) return res.json({ error: 'uid required' });
    await admin.auth().deleteUser(uid);
    await db.collection('users').doc(uid).delete().catch(()=>{});
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.json({ error: e.message });
  }
});

// --- Disable / Enable user (Auth + Firestore flag) ---
app.post('/disableUser', async (req, res) => {
  try {
    const { uid, disable } = req.body;
    if (!uid) return res.json({ error: 'uid required' });
    await admin.auth().updateUser(uid, { disabled: !!disable });
    await db.collection('users').doc(uid).update({ disabled: !!disable, updatedAt: admin.firestore.FieldValue.serverTimestamp() }).catch(()=>{});
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.json({ error: e.message });
  }
});

// --- Generate password reset link (admin can copy & send) ---
app.post('/generatePasswordResetLink', async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.json({ error: 'email required' });
    const link = await admin.auth().generatePasswordResetLink(email);
    res.json({ link });
  } catch (e) {
    console.error(e);
    res.json({ error: e.message });
  }
});

// --- Directly set user password (admin action) ---
app.post('/setPassword', async (req, res) => {
  try {
    const { uid, password } = req.body;
    if (!uid || !password) return res.json({ error: 'uid and password required' });
    await admin.auth().updateUser(uid, { password });
    res.json({ ok: true });
  } catch (e) {
    console.error(e);
    res.json({ error: e.message });
  }
});

// --- Utility endpoint: set custom claim (for making admins) ---
app.post('/setRole', async (req, res) => {
  try {
    const { uid, role } = req.body;
    if (!uid) return res.json({ error: 'uid required' });
    const claims = {};
    if (role === 'admin') claims.admin = true;
    if (role === 'superadmin') claims.superadmin = true;
    await admin.auth().setCustomUserClaims(uid, claims);
    res.json({ ok: true });
  } catch (e) { res.json({ error: e.message }); }
});

// --- Start server ---
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Admin API running on http://localhost:${PORT}`));

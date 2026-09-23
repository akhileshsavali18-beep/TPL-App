// ==========================================
// SETTINGS & REMOTE CONTROLS MODULE (js/settings.js)
// ==========================================

// 1. Master Refresh Function (Connects all modules)
function fetchAllData() {
  if (typeof listenWithdrawals === 'function') listenWithdrawals();
  if (typeof listenUsers === 'function') listenUsers();
  if (typeof loadTasksHub === 'function') loadTasksHub();
  loadAllSettings();
  showToast('Refreshing live data...');
}

// 2. Unity Ads Status Label Toggle
function toggleAdsLabel(isActive) {
  const lbl = document.getElementById('adsStatusLabel');
  if (lbl) {
    lbl.innerText = isActive ? 'Ads Active' : 'Ads Paused';
    lbl.className = isActive ? 'text-green-400 font-bold' : 'text-red-400 font-bold';
  }
}

// 3. Load All Remote Settings from Firestore
function loadAllSettings() {
  // A. Unity Ads Settings
  db.collection('settings').doc('unity_ads').get().then(doc => {
    if (doc.exists) {
      const d = doc.data();
      const active = d.adsActive !== false;
      const toggle = document.getElementById('ads-enabledToggle');
      if (toggle) toggle.checked = active;
      toggleAdsLabel(active);

      if (d.gameId && document.getElementById('ads-gameId')) document.getElementById('ads-gameId').value = d.gameId;
      if (d.cooldown && document.getElementById('ads-cooldown')) document.getElementById('ads-cooldown').value = d.cooldown;
      if (d.rewardedId && document.getElementById('ads-rewardedId')) document.getElementById('ads-rewardedId').value = d.rewardedId;
      if (d.interstitialId && document.getElementById('ads-interstitialId')) document.getElementById('ads-interstitialId').value = d.interstitialId;
      if (document.getElementById('ads-testMode')) document.getElementById('ads-testMode').checked = d.testMode || false;
    }
  });

  // B. P1 Core Economy
  db.collection('settings').doc('economy').get().then(doc => {
    if (doc.exists) {
      const d = doc.data();
      if (d.coinRate && document.getElementById('p1-coinRate')) document.getElementById('p1-coinRate').value = d.coinRate;
      if (d.referBonus && document.getElementById('p1-referBonus')) document.getElementById('p1-referBonus').value = d.referBonus;
      if (d.minTask && document.getElementById('p1-minTask')) document.getElementById('p1-minTask').value = d.minTask;
      if (d.minRefer && document.getElementById('p1-minRefer')) document.getElementById('p1-minRefer').value = d.minRefer;
      if (d.announcement && document.getElementById('p1-announcement')) document.getElementById('p1-announcement').value = d.announcement;
      if (document.getElementById('p1-announcementToggle')) document.getElementById('p1-announcementToggle').checked = d.showAnnouncement || false;
      if (document.getElementById('p1-maintenanceToggle')) document.getElementById('p1-maintenanceToggle').checked = d.maintenanceMode || false;
    }
  });

  // C. P2 Game Controls
  db.collection('settings').doc('games_config').get().then(doc => {
    if (doc.exists) {
      const d = doc.data();
      if (d.wheelSlices && document.getElementById('p2-wheelSlices')) document.getElementById('p2-wheelSlices').value = d.wheelSlices;
      if (d.spinLimit && document.getElementById('p2-spinLimit')) document.getElementById('p2-spinLimit').value = d.spinLimit;
      if (d.scratchLimit && document.getElementById('p2-scratchLimit')) document.getElementById('p2-scratchLimit').value = d.scratchLimit;
    }
  });

  // D. P3 Security Shield
  db.collection('settings').doc('security').get().then(doc => {
    if (doc.exists) {
      const d = doc.data();
      if (document.getElementById('p3-blockVPN')) document.getElementById('p3-blockVPN').checked = d.blockVPN || false;
      if (document.getElementById('p3-blockRooted')) document.getElementById('p3-blockRooted').checked = d.blockRooted || false;
      if (document.getElementById('p3-oneDevice')) document.getElementById('p3-oneDevice').checked = d.oneDevice || false;
    }
  });

  // E. GPLinks Settings
  db.collection('settings').doc('gplinks').get().then(doc => {
    if (doc.exists) {
      const d = doc.data();
      if (document.getElementById('gplinksToggle')) document.getElementById('gplinksToggle').checked = d.enabled !== false;
      if (d.apiKey && document.getElementById('gplinksKeyInput')) document.getElementById('gplinksKeyInput').value = d.apiKey;
    }
  });
}

// 4. Save Unity Ads Configuration
async function saveUnityAdsConfig() {
  const active = document.getElementById('ads-enabledToggle') ? document.getElementById('ads-enabledToggle').checked : true;
  const gameId = document.getElementById('ads-gameId') ? document.getElementById('ads-gameId').value.trim() : '5868205';
  const cooldown = parseInt(document.getElementById('ads-cooldown')?.value) || 60;
  const rewardedId = document.getElementById('ads-rewardedId') ? document.getElementById('ads-rewardedId').value.trim() : 'BP_Rewarded_Android';
  const interstitialId = document.getElementById('ads-interstitialId') ? document.getElementById('ads-interstitialId').value.trim() : 'Interstitial_Android';
  const testMode = document.getElementById('ads-testMode') ? document.getElementById('ads-testMode').checked : false;

  try {
    await db.collection('settings').doc('unity_ads').set({
      adsActive: active,
      gameId: gameId,
      cooldown: cooldown,
      rewardedId: rewardedId,
      interstitialId: interstitialId,
      testMode: testMode,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    showToast('Unity Ads Settings Saved & Live Synced!');
  } catch (e) {
    alert('Error saving Unity Ads: ' + e.message);
  }
}

// 5. Save P1 Economy Configuration
async function saveP1Config() {
  try {
    await db.collection('settings').doc('economy').set({
      coinRate: parseInt(document.getElementById('p1-coinRate')?.value) || 100,
      referBonus: parseFloat(document.getElementById('p1-referBonus')?.value) || 5.0,
      minTask: parseInt(document.getElementById('p1-minTask')?.value) || 25,
      minRefer: parseInt(document.getElementById('p1-minRefer')?.value) || 50,
      announcement: document.getElementById('p1-announcement')?.value.trim() || '',
      showAnnouncement: document.getElementById('p1-announcementToggle')?.checked || false,
      maintenanceMode: document.getElementById('p1-maintenanceToggle')?.checked || false,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    showToast('Core Economy Controls Saved!');
  } catch (e) {
    alert('Error saving Economy: ' + e.message);
  }
}

// 6. Save P2 Game Limits Configuration
async function saveP2Config() {
  try {
    await db.collection('settings').doc('games_config').set({
      wheelSlices: document.getElementById('p2-wheelSlices')?.value.trim() || '1, 50, 5, 0, 200, 12',
      spinLimit: parseInt(document.getElementById('p2-spinLimit')?.value) || 1,
      scratchLimit: parseInt(document.getElementById('p2-scratchLimit')?.value) || 1,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    showToast('Game Controls Saved!');
  } catch (e) {
    alert('Error saving Game controls: ' + e.message);
  }
}

// 7. Save P3 Security Shield Configuration
async function saveP3Config() {
  try {
    await db.collection('settings').doc('security').set({
      blockVPN: document.getElementById('p3-blockVPN')?.checked || false,
      blockRooted: document.getElementById('p3-blockRooted')?.checked || false,
      oneDevice: document.getElementById('p3-oneDevice')?.checked || false,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    showToast('Security Shield Saved!');
  } catch (e) {
    alert('Error saving Security: ' + e.message);
  }
}

// 8. Save GPLinks Referral Configuration
async function saveGplinksConfig() {
  try {
    await db.collection('settings').doc('gplinks').set({
      enabled: document.getElementById('gplinksToggle')?.checked !== false,
      apiKey: document.getElementById('gplinksKeyInput')?.value.trim() || '',
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    showToast('GPLinks Referral Settings Saved!');
  } catch (e) {
    alert('Error saving GPLinks: ' + e.message);
  }
}

// Auto-run when authenticated
auth.onAuthStateChanged(user => {
  if (user) {
    loadAllSettings();
  }
});
      

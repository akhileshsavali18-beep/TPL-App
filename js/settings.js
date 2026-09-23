// Settings Realtime Engine & Direct Firestore Sync

function loadSettings() {
  if (typeof db === 'undefined') return;

  // 1. Unity Ads Settings Load
  db.collection('settings').doc('unity_ads').onSnapshot(doc => {
    if (doc.exists) {
      const d = doc.data();
      const enabled = d.adsActive ?? d.adsEnabled ?? true;
      const toggle = document.getElementById('ads-enabledToggle');
      if (toggle) {
        toggle.checked = enabled;
        toggleAdsLabel(enabled);
      }
      if (document.getElementById('ads-gameId')) document.getElementById('ads-gameId').value = d.gameId || '5868205';
      if (document.getElementById('ads-cooldown')) document.getElementById('ads-cooldown').value = d.cooldown || 60;
      if (document.getElementById('ads-rewardedId')) document.getElementById('ads-rewardedId').value = d.rewardedId || 'Rewarded_Android';
      if (document.getElementById('ads-interstitialId')) document.getElementById('ads-interstitialId').value = d.interstitialId || 'Interstitial_Android';
      if (document.getElementById('ads-bannerId')) document.getElementById('ads-bannerId').value = d.bannerId || 'Banner_Android';
      if (document.getElementById('ads-testMode')) document.getElementById('ads-testMode').checked = d.testMode ?? true;
    }
  });

  // 2. Economy Settings Load
  db.collection('settings').doc('economy').onSnapshot(doc => {
    if (doc.exists) {
      const d = doc.data();
      if (document.getElementById('p1-coinRate')) document.getElementById('p1-coinRate').value = d.coinRate || 100;
      if (document.getElementById('p1-referBonus')) document.getElementById('p1-referBonus').value = d.referBonus || 5;
      if (document.getElementById('p1-minTask')) document.getElementById('p1-minTask').value = d.minTask || 25;
      if (document.getElementById('p1-minRefer')) document.getElementById('p1-minRefer').value = d.minRefer || 50;
      if (document.getElementById('p1-announcement')) document.getElementById('p1-announcement').value = d.announcement || '';
      if (document.getElementById('p1-announcementToggle')) document.getElementById('p1-announcementToggle').checked = d.showAnnouncement || false;
      if (document.getElementById('p1-maintenanceToggle')) document.getElementById('p1-maintenanceToggle').checked = d.maintenanceMode || false;
    }
  });

  // 3. Security Settings Load
  db.collection('settings').doc('security').onSnapshot(doc => {
    if (doc.exists) {
      const d = doc.data();
      if (document.getElementById('p3-blockVPN')) document.getElementById('p3-blockVPN').checked = d.blockVPN || false;
      if (document.getElementById('p3-blockRooted')) document.getElementById('p3-blockRooted').checked = d.blockRooted || false;
      if (document.getElementById('p3-oneDevice')) document.getElementById('p3-oneDevice').checked = d.oneDevice || false;
    }
  });
}

function toggleAdsLabel(isChecked) {
  const lbl = document.getElementById('adsStatusLabel');
  if (!lbl) return;
  if (isChecked) {
    lbl.innerText = 'Ads Active';
    lbl.className = 'text-green-400 font-bold';
  } else {
    lbl.innerText = 'Ads Disabled';
    lbl.className = 'text-red-400 font-bold';
  }
}

// Unity Ads Save - Updates both 'settings/unity_ads' and 'app_config/ads'
async function saveUnityAdsConfig() {
  const adsActive = document.getElementById('ads-enabledToggle').checked;
  const gameId = document.getElementById('ads-gameId').value.trim();
  const cooldown = parseInt(document.getElementById('ads-cooldown').value) || 60;
  const rewardedId = document.getElementById('ads-rewardedId').value.trim();
  const interstitialId = document.getElementById('ads-interstitialId').value.trim();
  const bannerId = (document.getElementById('ads-bannerId')?.value || 'Banner_Android').trim();
  const testMode = document.getElementById('ads-testMode').checked;

  const data = {
    adsActive: adsActive,
    adsEnabled: adsActive,
    gameId: gameId,
    cooldown: cooldown,
    rewardedId: rewardedId,
    interstitialId: interstitialId,
    bannerId: bannerId,
    testMode: testMode,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  };

  try {
    // 1. App latest path
    await db.collection('settings').doc('unity_ads').set(data, { merge: true });
    // 2. Legacy fallback path
    await db.collection('app_config').doc('ads').set(data, { merge: true });

    if (typeof showToast === 'function') {
      showToast('Unity Ads settings updated live!');
    } else {
      alert('Unity Ads settings updated successfully!');
    }
  } catch (err) {
    alert('Save error: ' + err.message);
  }
}

// Initial Call
if (typeof auth !== 'undefined') {
  auth.onAuthStateChanged(user => {
    if (user) loadSettings();
  });
} else {
  loadSettings();
}

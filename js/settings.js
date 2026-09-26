// Settings Realtime Engine & Direct Firestore Sync

function loadSettings() {
  if (typeof db === 'undefined') return;

  db.collection('settings').doc('unity_ads').onSnapshot(doc => {
    const d = doc.exists ? doc.data() : {};
    const enabled = d.adsActive ?? d.adsEnabled ?? true;
    const toggle = document.getElementById('ads-enabledToggle');
    if (toggle) { toggle.checked = enabled; toggleAdsLabel(enabled); }
    const set = (id, value) => { const el=document.getElementById(id); if(el && value !== undefined && value !== null) el.value=value; };
    const check = (id, value) => { const el=document.getElementById(id); if(el && value !== undefined) el.checked=!!value; };
    set('ads-gameId', d.gameId || '5868205');
    set('ads-cooldown', d.cooldown ?? 60);
    set('ads-rewardedId', d.rewardedId || 'Rewarded_Android');
    set('ads-interstitialId', d.interstitialId || 'Interstitial_Android');
    set('ads-bannerId', d.bannerId || 'Banner_Android');
    set('rewarded-daily-limit', d.rewardedDailyLimit ?? 10);
    check('ads-testMode', d.testMode ?? true);
    check('rewarded-enabled', d.rewardedAdsEnabled ?? true);
    check('interstitial-enabled', d.interstitialEnabled ?? true);
    check('rewarded-spin', d.rewardedSpinEnabled ?? true);
    check('rewarded-scratch', d.rewardedScratchEnabled ?? true);
    check('rewarded-game', d.rewardedGameEnabled ?? true);
  });

  db.collection('settings').doc('economy').onSnapshot(doc => {
    const d = doc.exists ? doc.data() : {};
    const set=(id,v)=>{const el=document.getElementById(id); if(el && v!==undefined && v!==null) el.value=v;};
    const check=(id,v)=>{const el=document.getElementById(id); if(el && v!==undefined) el.checked=!!v;};
    set('p1-coinRate', d.coinRate ?? 100);
    set('p1-referBonus', d.referBonus ?? 5);
    set('withdraw-first-min', d.firstCashMin ?? 25);
    set('withdraw-next-min', d.nextCashMin ?? 50);
    set('withdraw-refer-min', d.minRefer ?? 50);
    set('withdraw-coin-rate', d.coinRate ?? 100);
    set('ref-required-tasks', d.refRequiredTasks ?? 2);
    check('ref-enabled', d.referralEnabled ?? true);
    set('p1-announcement', d.announcement || '');
    check('p1-announcementToggle', d.showAnnouncement ?? false);
    check('p1-maintenanceToggle', d.maintenanceMode ?? false);
    check('app-earning-enabled', d.appEarningEnabled ?? true);
  });

  db.collection('settings').doc('task_rewards').onSnapshot(doc => {
    const d = doc.exists ? doc.data() : {};
    const set=(id,v)=>{const el=document.getElementById(id); if(el && v!==undefined && v!==null) el.value=Array.isArray(v)?v.join(', '):v;};
    const check=(id,v)=>{const el=document.getElementById(id); if(el && v!==undefined) el.checked=!!v;};
    set('task-offerwall-share', d.offerwallUserShare ?? 50);
    set('task-spin-unlock', d.spinUnlockTasks ?? 2);
    set('task-scratch-unlock', d.scratchUnlockTasks ?? 3);
    set('task-spin-rewards', d.spinRewards ?? [1,2,5,0,3,1]);
    set('task-scratch-rewards', d.scratchRewards ?? [1,2,5]);
    check('task-daily-reset', d.dailyReset ?? true);
  });

  db.collection('app_config').doc('withdrawal_settings').onSnapshot(doc => {
    const d=doc.exists?doc.data():{};
    const el=document.getElementById('withdraw-upi-enabled'); if(el) el.checked=d.upiEnabled ?? true;
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


async function saveRewardedAdsConfig() {
  const data = {
    rewardedAdsEnabled: document.getElementById('rewarded-enabled')?.checked ?? true,
    interstitialEnabled: document.getElementById('interstitial-enabled')?.checked ?? true,
    rewardedSpinEnabled: document.getElementById('rewarded-spin')?.checked ?? true,
    rewardedScratchEnabled: document.getElementById('rewarded-scratch')?.checked ?? true,
    rewardedGameEnabled: document.getElementById('rewarded-game')?.checked ?? true,
    rewardedDailyLimit: parseInt(document.getElementById('rewarded-daily-limit')?.value || '10') || 0,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  };
  await db.collection('settings').doc('unity_ads').set(data, {merge:true});
  await db.collection('app_config').doc('ads').set(data, {merge:true});
  showToast('Rewarded-ad controls saved live!');
}

async function saveTaskRewardRules() {
  const parseList = id => (document.getElementById(id)?.value || '').split(',').map(v=>parseInt(v.trim())).filter(v=>!Number.isNaN(v));
  const data = {
    offerwallUserShare: parseInt(document.getElementById('task-offerwall-share')?.value || '50') || 50,
    spinUnlockTasks: Math.max(1, parseInt(document.getElementById('task-spin-unlock')?.value || '2') || 2),
    scratchUnlockTasks: Math.max(1, parseInt(document.getElementById('task-scratch-unlock')?.value || '3') || 3),
    spinRewards: parseList('task-spin-rewards'),
    scratchRewards: parseList('task-scratch-rewards'),
    dailyReset: document.getElementById('task-daily-reset')?.checked ?? true,
    coinRate: parseInt(document.getElementById('p1-coinRate')?.value || '100') || 100,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  };
  await db.collection('settings').doc('task_rewards').set(data,{merge:true});
  await db.collection('settings').doc('economy').set({coinRate:data.coinRate,updatedAt:firebase.firestore.FieldValue.serverTimestamp()},{merge:true});
  showToast('Task & Reward Rules saved live!');
}

async function saveWithdrawalRules() {
  const data = {
    firstCashMin: Math.max(0, Number(document.getElementById('withdraw-first-min')?.value || 25)),
    nextCashMin: Math.max(0, Number(document.getElementById('withdraw-next-min')?.value || 50)),
    minRefer: Math.max(0, Number(document.getElementById('withdraw-refer-min')?.value || 50)),
    coinRate: Math.max(1, Number(document.getElementById('withdraw-coin-rate')?.value || 100)),
    upiEnabled: document.getElementById('withdraw-upi-enabled')?.checked ?? true,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  };
  await db.collection('app_config').doc('withdrawal_settings').set(data,{merge:true});
  await db.collection('settings').doc('economy').set({coinRate:data.coinRate,minRefer:data.minRefer,firstCashMin:data.firstCashMin,nextCashMin:data.nextCashMin,updatedAt:firebase.firestore.FieldValue.serverTimestamp()},{merge:true});
  showToast('Withdrawal Rules saved live!');
}

async function saveReferralRules() {
  const data = {
    referBonus: Math.max(0, Number(document.getElementById('p1-referBonus')?.value || 5)),
    refRequiredTasks: Math.max(1, Number(document.getElementById('ref-required-tasks')?.value || 2)),
    referralEnabled: document.getElementById('ref-enabled')?.checked ?? true,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  };
  await db.collection('settings').doc('economy').set(data,{merge:true});
  showToast('Referral settings saved live!');
}

async function saveAppControls() {
  const data = {
    announcement: document.getElementById('p1-announcement')?.value.trim() || '',
    showAnnouncement: document.getElementById('p1-announcementToggle')?.checked ?? false,
    maintenanceMode: document.getElementById('p1-maintenanceToggle')?.checked ?? false,
    appEarningEnabled: document.getElementById('app-earning-enabled')?.checked ?? true,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  };
  await db.collection('settings').doc('economy').set(data,{merge:true});
  showToast('App Controls saved live!');
}

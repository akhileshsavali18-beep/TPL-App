function fetchAllData() {
  listenWithdrawals();
  listenUsers();
  loadTasksHub();
  loadSettings();
}

function switchTaskSubTab(sub) {
  ['banners', 'games', 'offerwalls'].forEach(s => {
    const view = document.getElementById('view-task-' + s);
    const btn = document.getElementById('subtab-' + s);
    if (view && btn) {
      if (s === sub) { view.classList.remove('hidden'); btn.className = "px-3 py-1.5 rounded-xl subtab-active whitespace-nowrap"; }
      else { view.classList.add('hidden'); btn.className = "px-3 py-1.5 rounded-xl bg-white/5 text-gray-400 whitespace-nowrap"; }
    }
  });
}

function loadTasksHub() {
  // Banners Sync
  db.collection('banners').onSnapshot(snap => {
    const c = document.getElementById('bannersList');
    if (!c) return;
    c.innerHTML = snap.empty ? '<div class="text-center py-4 text-gray-500 text-xs">No banners added.</div>' : '';
    snap.forEach(doc => {
      const b = doc.data();
      const div = document.createElement('div');
      div.className = 'dark-card p-3 rounded-2xl flex justify-between items-center';
      div.innerHTML = `<div><div class="text-xs font-bold text-white">${b.title || 'Banner'}</div><div class="text-[10px] text-gray-400">${b.sub || ''}</div></div>
      <button onclick="db.collection('banners').doc('${doc.id}').delete()" class="text-red-400 text-xs font-bold px-2 py-1 bg-red-500/10 rounded-lg active:scale-95">Delete</button>`;
      c.appendChild(div);
    });
  });

  // Games Sync
  db.collection('games').onSnapshot(snap => {
    const c = document.getElementById('gamesList');
    if (!c) return;
    c.innerHTML = snap.empty ? '<div class="text-center py-4 text-gray-500 text-xs">No games added.</div>' : '';
    snap.forEach(doc => {
      const g = doc.data();
      const div = document.createElement('div');
      div.className = 'dark-card p-3 rounded-2xl flex justify-between items-center';
      div.innerHTML = `<div><div class="text-xs font-bold text-white">${g.title || 'Game'}</div><div class="text-[10px] text-green-400">+${g.coins || 2} Coins</div></div>
      <button onclick="db.collection('games').doc('${doc.id}').delete()" class="text-red-400 text-xs font-bold px-2 py-1 bg-red-500/10 rounded-lg active:scale-95">Delete</button>`;
      c.appendChild(div);
    });
  });
}

function openAddBannerModal() { document.getElementById('bannerModal').classList.remove('hidden'); }
function closeAddBannerModal() { document.getElementById('bannerModal').classList.add('hidden'); }

async function saveNewBanner() {
  const title = document.getElementById('bannerTitle').value.trim();
  const sub = document.getElementById('bannerSub').value.trim();
  const url = document.getElementById('bannerTargetUrl').value.trim();
  if (!title) return alert('Enter title!');
  await db.collection('banners').add({ title, sub, targetUrl: url, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  showToast('Banner Added!');
  closeAddBannerModal();
}

function openAddGameModal() { document.getElementById('gameModal').classList.remove('hidden'); }
function closeAddGameModal() { document.getElementById('gameModal').classList.add('hidden'); }

async function saveNewGame() {
  const title = document.getElementById('gameTitle').value.trim();
  const coins = parseInt(document.getElementById('gameCoins').value) || 2;
  const url = document.getElementById('gameUrl').value.trim();
  if (!title || !url) return alert('Enter name & link!');
  await db.collection('games').add({ title, coins, url, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  showToast('Game Added!');
  closeAddGameModal();
}

async function saveOfferwallsConfig() {
  await db.collection('settings').doc('offerwalls').set({
    cpaleadActive: document.getElementById('cpaleadEnabled').checked,
    cpaleadUrl: document.getElementById('cpaleadUrlInput').value.trim(),
    earnkaroActive: document.getElementById('earnkaroEnabled').checked,
    earnkaroUrl: document.getElementById('earnkaroUrl').value.trim()
  }, { merge: true });
  showToast('Offerwalls Saved!');
}

function toggleAdsLabel(isActive) {
  const lbl = document.getElementById('adsStatusLabel');
  if (lbl) { lbl.innerText = isActive ? 'Ads Active' : 'Ads Paused'; lbl.className = isActive ? 'text-green-400 font-bold' : 'text-red-400 font-bold'; }
}

function loadSettings() {
  db.collection('settings').doc('unity_ads').get().then(doc => {
    if (doc.exists) {
      const d = doc.data();
      document.getElementById('ads-enabledToggle').checked = d.adsActive !== false;
      toggleAdsLabel(d.adsActive !== false);
      if (d.gameId) document.getElementById('ads-gameId').value = d.gameId;
      if (d.rewardedId) document.getElementById('ads-rewardedId').value = d.rewardedId;
    }
  });
}

async function saveUnityAdsConfig() {
  await db.collection('settings').doc('unity_ads').set({
    adsActive: document.getElementById('ads-enabledToggle').checked,
    gameId: document.getElementById('ads-gameId').value.trim(),
    rewardedId: document.getElementById('ads-rewardedId').value.trim(),
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
  showToast('Unity Ads Settings Saved & Live Synced!');
}
    

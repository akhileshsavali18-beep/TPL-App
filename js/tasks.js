// ==========================================
// CONTENT & TASKS HUB MODULE (js/tasks.js)
// ==========================================

function switchTaskSubTab(sub) {
  const subs = ['social', 'offer', 'banners', 'games', 'future'];
  subs.forEach(s => {
    const view = document.getElementById('view-task-' + s);
    const btn = document.getElementById('subtab-' + s);
    if (view && btn) {
      if (s === sub) {
        view.classList.remove('hidden');
        btn.className = "px-3 py-1.5 rounded-xl subtab-active whitespace-nowrap";
      } else {
        view.classList.add('hidden');
        btn.className = "px-3 py-1.5 rounded-xl bg-white/5 text-gray-400 whitespace-nowrap";
      }
    }
  });
}

function loadTasksHub() {
  // 1. Social Tasks Stream
  db.collection('tasks').onSnapshot(snap => {
    const c = document.getElementById('tasksList');
    if (!c) return;
    if (snap.empty) {
      c.innerHTML = `
        <div class="text-center py-6 space-y-2">
          <p class="text-gray-500 text-xs">No tasks in database.</p>
          <button onclick="seedDefaultTasks()" class="px-3 py-1.5 bg-blue-600/30 border border-blue-500/40 text-blue-400 text-xs font-bold rounded-xl active:scale-95">⚡ Load App Tasks (YouTube, TG, Insta)</button>
        </div>`;
      return;
    }
    c.innerHTML = '';
    snap.forEach(doc => {
      const t = doc.data();
      const div = document.createElement('div');
      div.className = 'dark-card p-3 rounded-2xl flex justify-between items-center';
      div.innerHTML = `
        <div>
          <div class="text-xs font-bold text-white">${t.title || 'Task'}</div>
          <div class="text-[10px] text-green-400 font-semibold">+${t.coins || 25} Coins • ${t.category || 'Social'}</div>
        </div>
        <button onclick="deleteDoc('tasks', '${doc.id}')" class="text-red-400 text-xs font-bold px-2 py-1 bg-red-500/10 rounded-lg active:scale-95">Delete</button>
      `;
      c.appendChild(div);
    });
  });

  // 2. Carousel Banners Stream
  db.collection('banners').onSnapshot(snap => {
    const c = document.getElementById('bannersList');
    if (!c) return;
    if (snap.empty) {
      c.innerHTML = `
        <div class="text-center py-6 space-y-2">
          <p class="text-gray-500 text-xs">No banners in database.</p>
          <button onclick="seedDefaultBanners()" class="px-3 py-1.5 bg-green-600/30 border border-green-500/40 text-green-400 text-xs font-bold rounded-xl active:scale-95">⚡ Load 3 Default Banners to Database</button>
        </div>`;
      return;
    }
    c.innerHTML = '';
    snap.forEach(doc => {
      const b = doc.data();
      const div = document.createElement('div');
      div.className = 'dark-card p-3 rounded-2xl flex justify-between items-center';
      div.innerHTML = `
        <div>
          <div class="text-xs font-bold text-white">${b.title || 'Banner'}</div>
          <div class="text-[10px] text-gray-400">${b.sub || 'Carousel Banner'}</div>
        </div>
        <button onclick="deleteDoc('banners', '${doc.id}')" class="text-red-400 text-xs font-bold px-2 py-1 bg-red-500/10 rounded-lg active:scale-95">Delete</button>
      `;
      c.appendChild(div);
    });
  });

  // 3. Games Stream
  db.collection('games').onSnapshot(snap => {
    const c = document.getElementById('gamesList');
    if (!c) return;
    if (snap.empty) {
      c.innerHTML = `
        <div class="text-center py-6 space-y-2">
          <p class="text-gray-500 text-xs">No games in database.</p>
          <button onclick="seedDefaultGames()" class="px-3 py-1.5 bg-purple-600/30 border border-purple-500/40 text-purple-400 text-xs font-bold rounded-xl active:scale-95">⚡ Load 4 Gamezop Games</button>
        </div>`;
      return;
    }
    c.innerHTML = '';
    snap.forEach(doc => {
      const g = doc.data();
      const div = document.createElement('div');
      div.className = 'dark-card p-3 rounded-2xl flex justify-between items-center';
      div.innerHTML = `
        <div>
          <div class="text-xs font-bold text-white">${g.title || 'Game'}</div>
          <div class="text-[10px] text-green-400">+${g.coins || 2} Coins • ${g.category || 'Arcade'}</div>
        </div>
        <button onclick="deleteDoc('games', '${doc.id}')" class="text-red-400 text-xs font-bold px-2 py-1 bg-red-500/10 rounded-lg active:scale-95">Delete</button>
      `;
      c.appendChild(div);
    });
  });

}

// ⚡ 1-Click Sync Defaults from App to Firebase
async function seedDefaultTasks() {
  const tasks = [
    { title: 'Subscribe to YouTube', coins: 30, category: 'Social', url: 'https://youtube.com' },
    { title: 'Join Telegram Channel', coins: 25, category: 'Social', url: 'https://t.me' },
    { title: 'Follow on Instagram', coins: 25, category: 'Social', url: 'https://instagram.com' }
  ];
  for (let t of tasks) {
    await db.collection('tasks').add({ ...t, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  }
  showToast('Default Tasks Synced to Database!');
}

async function seedDefaultBanners() {
  const banners = [
    { title: 'CPAlead Mega Offerwall', sub: 'Complete app installs & earn coins', targetUrl: '' },
    { title: 'Instant UPI Withdrawals', sub: 'Safe & direct cash payouts to bank account', targetUrl: '' },
    { title: 'Lucky Spin & Win', sub: 'Spin the wheel daily to grab bonus coins', targetUrl: '' }
  ];
  for (let b of banners) {
    await db.collection('banners').add({ ...b, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  }
  showToast('Default Banners Synced to Database!');
}

async function seedDefaultGames() {
  const games = [
    { title: 'Cricket Gunda', coins: 2, category: 'Sports', url: 'https://www.gamezop.com/g/r1W50d89?id=tpl_cricket' },
    { title: 'Fruit Chop', coins: 2, category: 'Arcade', url: 'https://www.gamezop.com/g/rkXG0O85?id=tpl_fruit' },
    { title: 'Bottle Shoot', coins: 2, category: 'Action', url: 'https://www.gamezop.com/g/B1w5CdL5?id=tpl_bottle' },
    { title: 'Bubble Wipeout', coins: 2, category: 'Puzzle', url: 'https://www.gamezop.com/g/SkWG0u8q?id=tpl_bubble' }
  ];
  for (let g of games) {
    await db.collection('games').add({ ...g, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  }
  showToast('Default Games Synced to Database!');
}

// Modals Trigger
function openAddTaskModal() { document.getElementById('taskModal').classList.remove('hidden'); }
function closeTaskModal() { document.getElementById('taskModal').classList.add('hidden'); }

async function saveNewTask() {
  const title = document.getElementById('taskTitle').value.trim();
  const coins = parseInt(document.getElementById('taskCoins').value) || 25;
  const cat = document.getElementById('taskCategory').value;
  const url = document.getElementById('taskUrl').value.trim();
  if (!title || !url) return alert('Enter title & URL!');

  await db.collection('tasks').add({ title, coins, category: cat, url, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  showToast('Task Saved!');
  closeTaskModal();
}

function openAddBannerModal() { document.getElementById('bannerModal').classList.remove('hidden'); }
function closeAddBannerModal() { document.getElementById('bannerModal').classList.add('hidden'); }

async function saveNewBanner() {
  const title = document.getElementById('bannerTitle').value.trim();
  const sub = document.getElementById('bannerSub').value.trim();
  const url = document.getElementById('bannerTargetUrl').value.trim();
  if (!title) return alert('Enter title!');

  await db.collection('banners').add({ title, sub, targetUrl: url, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  showToast('Banner Saved!');
  closeAddBannerModal();
}

function openAddGameModal() { document.getElementById('gameModal').classList.remove('hidden'); }
function closeAddGameModal() { document.getElementById('gameModal').classList.add('hidden'); }

async function saveNewGame() {
  const title = document.getElementById('gameTitle').value.trim();
  const coins = parseInt(document.getElementById('gameCoins').value) || 2;
  const category = document.getElementById('gameCategory').value.trim() || 'Arcade';
  const url = document.getElementById('gameUrl').value.trim();
  if (!title || !url) return alert('Enter Title & URL!');

  await db.collection('games').add({ title, coins, category, url, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  showToast('Game Saved!');
  closeAddGameModal();
}

async function saveOfferwallsConfig() {
  const cpaleadActive = document.getElementById('cpaleadEnabled').checked;
  const cpaleadUrl = document.getElementById('cpaleadUrlInput').value.trim();
  const earnkaroActive = document.getElementById('earnkaroEnabled').checked;
  const earnkaroUrl = document.getElementById('earnkaroUrl').value.trim();

  await db.collection('settings').doc('offerwalls').set({
    cpaleadActive, cpaleadUrl, earnkaroActive, earnkaroUrl,
    updatedAt: firebase.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  showToast('Offerwalls Saved & Synced!');
}

async function deleteDoc(coll, id) {
  if (confirm('Delete this item?')) {
    await db.collection(coll).doc(id).delete();
    showToast('Deleted!');
  }
}

auth.onAuthStateChanged(user => {
  if (user) {
    loadTasksHub();
  }
});

// ==========================================
// CONTENT & TASKS HUB MODULE (js/tasks.js)
// ==========================================

// 1. Switch Tasks Sub-Tabs
function switchTaskSubTab(sub) {
  const subs = ['social', 'banners', 'games', 'offerwalls'];
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

// 2. Load Tasks, Banners, Games & Offerwalls
function loadTasksHub() {
  // A. Social Tasks Stream
  db.collection('tasks').onSnapshot(snap => {
    const c = document.getElementById('tasksList');
    if (!c) return;
    if (snap.empty) {
      c.innerHTML = '<div class="text-center py-6 text-gray-500 text-xs">No tasks added yet.</div>';
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

  // B. Carousel Banners Stream
  db.collection('banners').onSnapshot(snap => {
    const c = document.getElementById('bannersList');
    if (!c) return;
    if (snap.empty) {
      c.innerHTML = '<div class="text-center py-6 text-gray-500 text-xs">No banners added yet.</div>';
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

  // C. Games Stream
  db.collection('games').onSnapshot(snap => {
    const c = document.getElementById('gamesList');
    if (!c) return;
    if (snap.empty) {
      c.innerHTML = '<div class="text-center py-6 text-gray-500 text-xs">No games added yet.</div>';
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

  // D. Offerwalls Settings
  db.collection('settings').doc('offerwalls').get().then(doc => {
    if (doc.exists) {
      const d = doc.data();
      const cpaleadToggle = document.getElementById('cpaleadEnabled');
      const cpaleadInput = document.getElementById('cpaleadUrlInput');
      const earnkaroToggle = document.getElementById('earnkaroEnabled');
      const earnkaroInput = document.getElementById('earnkaroUrl');

      if (cpaleadToggle) cpaleadToggle.checked = d.cpaleadActive !== false;
      if (cpaleadInput && d.cpaleadUrl) cpaleadInput.value = d.cpaleadUrl;
      if (earnkaroToggle) earnkaroToggle.checked = d.earnkaroActive !== false;
      if (earnkaroInput && d.earnkaroUrl) earnkaroInput.value = d.earnkaroUrl;
    }
  });
}

// 3. Social Task Modal & Save
function openAddTaskModal() { document.getElementById('taskModal').classList.remove('hidden'); }
function closeTaskModal() { document.getElementById('taskModal').classList.add('hidden'); }

async function saveNewTask() {
  const title = document.getElementById('taskTitle').value.trim();
  const coins = parseInt(document.getElementById('taskCoins').value) || 25;
  const cat = document.getElementById('taskCategory').value;
  const url = document.getElementById('taskUrl').value.trim();
  if (!title || !url) return alert('Please enter task title & URL!');

  try {
    await db.collection('tasks').add({
      title,
      coins,
      category: cat,
      url,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('Task Created Successfully!');
    closeTaskModal();
  } catch (e) {
    alert('Error saving task: ' + e.message);
  }
}

// 4. Banner Modal & Save
function openAddBannerModal() { document.getElementById('bannerModal').classList.remove('hidden'); }
function closeAddBannerModal() { document.getElementById('bannerModal').classList.add('hidden'); }

async function saveNewBanner() {
  const title = document.getElementById('bannerTitle').value.trim();
  const sub = document.getElementById('bannerSub').value.trim();
  const url = document.getElementById('bannerTargetUrl').value.trim();
  if (!title) return alert('Enter Banner Title!');

  try {
    await db.collection('banners').add({
      title,
      sub,
      targetUrl: url,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('Banner Added Successfully!');
    closeAddBannerModal();
  } catch (e) {
    alert('Error saving banner: ' + e.message);
  }
}

// 5. Game Modal & Save
function openAddGameModal() { document.getElementById('gameModal').classList.remove('hidden'); }
function closeAddGameModal() { document.getElementById('gameModal').classList.add('hidden'); }

async function saveNewGame() {
  const title = document.getElementById('gameTitle').value.trim();
  const coins = parseInt(document.getElementById('gameCoins').value) || 2;
  const category = document.getElementById('gameCategory').value.trim() || 'Arcade';
  const url = document.getElementById('gameUrl').value.trim();
  if (!title || !url) return alert('Enter Game Title & URL!');

  try {
    await db.collection('games').add({
      title,
      coins,
      category,
      url,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('Game Added Successfully!');
    closeAddGameModal();
  } catch (e) {
    alert('Error saving game: ' + e.message);
  }
}

// 6. Save Offerwalls Config (CPAlead & EarnKaro)
async function saveOfferwallsConfig() {
  const cpaleadActive = document.getElementById('cpaleadEnabled').checked;
  const cpaleadUrl = document.getElementById('cpaleadUrlInput').value.trim();
  const earnkaroActive = document.getElementById('earnkaroEnabled').checked;
  const earnkaroUrl = document.getElementById('earnkaroUrl').value.trim();

  try {
    await db.collection('settings').doc('offerwalls').set({
      cpaleadActive,
      cpaleadUrl,
      earnkaroActive,
      earnkaroUrl,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    showToast('Offerwalls Saved & Live Synced!');
  } catch (e) {
    alert('Error saving offerwalls: ' + e.message);
  }
}

// 7. Generic Delete Document Helper
async function deleteDoc(coll, id) {
  if (confirm('Are you sure you want to delete this item?')) {
    try {
      await db.collection(coll).doc(id).delete();
      showToast('Item deleted successfully!');
    } catch (e) {
      alert('Error deleting: ' + e.message);
    }
  }
}

// Auto-run when authenticated
auth.onAuthStateChanged(user => {
  if (user) {
    loadTasksHub();
  }
});
    

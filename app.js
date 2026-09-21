// ==========================================
// TPL PRO ADMIN CONSOLE - AIRTIGHT SECURE ENGINE
// ==========================================

// ⚠️ ನಿಮ್ಮ Firebase Authentication Users ಟ್ಯಾಬ್‌ನಲ್ಲಿರುವ UID ಅನ್ನು ಇಲ್ಲಿ ಪೇಸ್ಟ್ ಮಾಡಿ:
const AUTHORIZED_ADMIN_UID = VsGSj7MPsoXIwLbBKPey4rV4Oxg1

const firebaseConfig = {
  apiKey: "AIzaSyCMFViBcyJVEawOZASTQ9qr2zDwIqhqKn8",
  authDomain: "tpl-5bd9d.firebaseapp.com",
  projectId: "tpl-5bd9d",
  storageBucket: "tpl-5bd9d.firebasestorage.app",
  messagingSenderId: "940679131159",
  appId: "1:940679131159:web:8b3de2fbf61b57615a2c52",
  measurementId: "G-KRP2LPFGQ4"
};

if (!firebase.apps.length) firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();
const auth = firebase.auth();

let allUsersData = [];
let pendingWithdrawalsCache = [];

// Listen for official Firebase Auth State
auth.onAuthStateChanged(user => {
  if (user) {
    if (user.uid === AUTHORIZED_ADMIN_UID) {
      // 100% Verified Admin
      document.getElementById('loginScreen').classList.add('hidden');
      document.getElementById('dashboardScreen').classList.remove('hidden');
      fetchAllData();
    } else {
      // Intruder or unauthorized user logged in
      alert("🚨 Access Denied! You are not authorized to view the admin console.");
      auth.signOut();
    }
  } else {
    document.getElementById('loginScreen').classList.remove('hidden');
    document.getElementById('dashboardScreen').classList.add('hidden');
  }
});

// ------------------------------------------
// 1. SECURE AUTHENTICATION LOGIN
// ------------------------------------------
async function handleLogin() {
  const email = document.getElementById('adminEmail').value.trim();
  const pass = document.getElementById('adminPassword').value.trim();
  const btn = document.getElementById('loginBtn');

  if (!email || !pass) {
    alert("Please enter both Admin Email and Password!");
    return;
  }

  btn.innerText = "Verifying Credentials...";
  btn.disabled = true;

  try {
    const cred = await auth.signInWithEmailAndPassword(email, pass);
    if (cred.user.uid !== AUTHORIZED_ADMIN_UID) {
      alert("🚨 Access Denied: Unrecognized Admin UID.");
      await auth.signOut();
      btn.innerText = "Unlock Console";
      btn.disabled = false;
    }
  } catch (err) {
    btn.innerText = "Unlock Console";
    btn.disabled = false;
    alert("Authentication Failed: " + err.message);
  }
}

function handleLogout() {
  auth.signOut();
  location.reload();
}

// ------------------------------------------
// 2. BOTTOM NAVIGATION SWITCHER
// ------------------------------------------
function switchTab(tab) {
  const tabs = ['dashboard', 'payouts', 'users', 'tasks', 'settings'];
  tabs.forEach(t => {
    const content = document.getElementById(`tabContent-${t}`);
    const navBtn = document.getElementById(`nav-${t}`);
    if (t === tab) {
      content.classList.remove('hidden');
      navBtn.className = "flex flex-col items-center gap-1 active-nav transition py-1";
    } else {
      content.classList.add('hidden');
      navBtn.className = "flex flex-col items-center gap-1 text-gray-400 transition py-1";
    }
  });
  window.scrollTo({ top: 0, behavior: 'smooth' });
}

function fetchAllData() {
  fetchWithdrawals();
  fetchUsers();
  fetchTasks();
  fetchConfigs();
}

// ------------------------------------------
// 3. TAB 2: PAYOUTS QUEUE
// ------------------------------------------
function fetchWithdrawals() {
  db.collection('withdrawals').orderBy('createdAt', 'desc').onSnapshot(snap => {
    const list = document.getElementById('withdrawalsList');
    list.innerHTML = '';
    let pCount = 0, pAmt = 0, cAmt = 0;
    pendingWithdrawalsCache = [];

    if (snap.empty) {
      list.innerHTML = '<div class="p-8 text-center text-gray-500 dark-card rounded-2xl text-xs">No withdrawal requests found.</div>';
    }

    snap.forEach(doc => {
      const d = doc.data();
      const id = doc.id;
      const isPending = d.status === 'Pending';

      if (isPending) {
        pCount++;
        pAmt += (d.amount || 0);
        pendingWithdrawalsCache.push({ id, ...d });
      } else if (d.status === 'Completed') {
        cAmt += (d.amount || 0);
      }

      const card = document.createElement('div');
      card.className = `dark-card p-4 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 ${!isPending ? 'opacity-40' : ''}`;

      const upiPayLink = `upi://pay?pa=${encodeURIComponent(d.upiId || '')}&pn=${encodeURIComponent(d.userName || 'TPL Player')}&am=${d.amount}&cu=INR&tn=TPL_Payout`;

      card.innerHTML = `
        <div class="space-y-1">
          <div class="flex items-center gap-2">
            <span class="font-black text-sm text-white">${d.userName || 'Player'}</span>
            <span class="text-[9px] px-2 py-0.5 rounded-full font-bold ${isPending ? 'bg-amber-400/10 text-amber-400 border border-amber-400/20' : 'bg-green-400/10 text-green-400 border border-green-400/20'}">${d.status}</span>
            <span class="text-[10px] text-gray-500">• ${d.type}</span>
          </div>
          <div class="flex items-center gap-2 text-xs text-gray-300">
            <span class="font-mono text-white font-bold">${d.upiId}</span>
            <button onclick="copyText('${d.upiId}')" class="px-2 py-0.5 rounded bg-white/5 hover:bg-white/10 text-green-400 text-[10px] border border-white/5">Copy</button>
          </div>
          <div class="text-[10px] text-gray-500">${d.userEmail || ''}</div>
        </div>

        <div class="flex items-center justify-between sm:justify-end gap-3 pt-2 sm:pt-0 border-t sm:border-t-0 border-white/5">
          <div class="text-right">
            <div class="text-base font-black text-green-400">₹${(d.amount || 0).toFixed(2)}</div>
          </div>
          ${isPending ? `
            <div class="flex gap-1.5">
              <a href="${upiPayLink}" class="px-3 py-1.5 bg-blue-600 active:bg-blue-500 text-white font-bold text-xs rounded-xl transition inline-flex items-center">
                Pay UPI
              </a>
              <button onclick="markAsPaid('${id}')" class="px-3 py-1.5 bg-green-400 active:bg-green-300 text-black font-black text-xs rounded-xl transition">
                Mark Paid
              </button>
              <button onclick="rejectRequest('${id}', '${d.uid}', ${d.amount}, '${d.type}')" class="px-2.5 py-1.5 bg-red-500/10 text-red-400 text-xs rounded-xl border border-red-500/20">
                Reject
              </button>
            </div>
          ` : '<span class="text-xs text-gray-500 font-bold">Settled</span>'}
        </div>
      `;
      list.appendChild(card);
    });

    document.getElementById('statPendingCount').innerText = pCount;
    document.getElementById('statPendingAmount').innerText = '₹' + pAmt.toFixed(2);
    document.getElementById('statPaidAmount').innerText = '₹' + cAmt.toFixed(2);

    const badge = document.getElementById('navBadge');
    if (pCount > 0) {
      badge.innerText = pCount;
      badge.classList.remove('hidden');
    } else {
      badge.classList.add('hidden');
    }
  });
}

function exportCashfreeCSV() {
  if (!pendingWithdrawalsCache.length) return alert('No pending payouts to export!');
  let csv = "TransferId,Amount,Phone,Email,Name,BeneficiaryId,VPA\n";
  pendingWithdrawalsCache.forEach((item) => {
    csv += `TPL_${item.id},${item.amount},,,${item.userName || 'Player'},,${item.upiId}\n`;
  });
  const blob = new Blob([csv], { type: 'text/csv' });
  const url = window.URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.setAttribute('href', url);
  a.setAttribute('download', `Cashfree_Batch_${new Date().toISOString().slice(0,10)}.csv`);
  a.click();
  showToast('Cashfree CSV Exported!');
}

async function markAsPaid(docId) {
  if (!confirm("Confirm payment sent to user?")) return;
  await db.collection('withdrawals').doc(docId).update({
    status: 'Completed',
    paidAt: firebase.firestore.FieldValue.serverTimestamp()
  });
  showToast('Marked as Paid!');
}

async function rejectRequest(docId, uid, amount, type) {
  const reason = prompt("Enter rejection reason (e.g., Invalid UPI ID):");
  if (reason === null) return;
  const field = type === 'Task Cash' ? 'taskCash' : 'referCash';
  await db.collection('users').doc(uid).update({ [field]: firebase.firestore.FieldValue.increment(amount) });
  await db.collection('withdrawals').doc(docId).update({
    status: 'Rejected',
    rejectionReason: reason,
    rejectedAt: firebase.firestore.FieldValue.serverTimestamp()
  });
  showToast('Refunded to user wallet!');
}

// ------------------------------------------
// 4. TAB 3: USERS & ALERTS
// ------------------------------------------
function fetchUsers() {
  db.collection('users').onSnapshot(snap => {
    allUsersData = [];
    snap.forEach(doc => allUsersData.push({ uid: doc.id, ...doc.data() }));
    document.getElementById('statTotalUsers').innerText = allUsersData.length;
    renderUsers(allUsersData);
  });
}

function renderUsers(users) {
  const list = document.getElementById('usersList');
  list.innerHTML = '';
  if (!users.length) {
    list.innerHTML = '<div class="p-8 text-center text-gray-500 dark-card rounded-2xl text-xs">No users found.</div>';
    return;
  }

  users.forEach(u => {
    const isBanned = u.isBanned === true;
    const card = document.createElement('div');
    card.className = `dark-card p-4 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 ${isBanned ? 'border-red-500/30 bg-red-950/10' : ''}`;

    card.innerHTML = `
      <div class="space-y-1">
        <div class="flex items-center gap-2">
          <span class="font-black text-sm text-white">${u.displayName || 'Player'}</span>
          ${isBanned ? '<span class="text-[9px] bg-red-500/20 text-red-400 border border-red-500/30 px-2 py-0.5 rounded-full font-bold">BANNED</span>' : ''}
          <span class="text-[10px] text-yellow-400 font-bold">★ ${u.coins || 0} Coins</span>
        </div>
        <div class="text-[11px] text-gray-400">Email: ${u.email || 'N/A'}</div>
        <div class="text-[11px] text-gray-500">UPI: <span class="text-gray-300 font-mono font-bold">${u.upiId || 'Not Saved'}</span></div>
      </div>
      <div class="flex items-center gap-2 pt-2 sm:pt-0 border-t sm:border-t-0 border-white/5">
        <button onclick="openNotifModal('${u.uid}', '${(u.displayName || 'Player').replace(/'/g, "")}')" class="flex-1 sm:flex-none px-3 py-1.5 bg-white/5 hover:bg-white/10 text-green-400 border border-white/5 rounded-xl text-xs font-bold">
          🔔 Alert
        </button>
        <button onclick="toggleBanUser('${u.uid}', ${isBanned})" class="flex-1 sm:flex-none px-3 py-1.5 ${isBanned ? 'bg-green-500/10 text-green-400 border-green-500/20' : 'bg-red-500/10 text-red-400 border-red-500/20'} border rounded-xl text-xs font-bold">
          ${isBanned ? 'Unban' : 'Ban'}
        </button>
      </div>
    `;
    list.appendChild(card);
  });
}

function filterUsers() {
  const q = document.getElementById('userSearchInput').value.toLowerCase();
  const filtered = allUsersData.filter(u => 
    (u.displayName || '').toLowerCase().includes(q) ||
    (u.email || '').toLowerCase().includes(q) ||
    (u.upiId || '').toLowerCase().includes(q)
  );
  renderUsers(filtered);
}

function openNotifModal(uid, name) {
  document.getElementById('modalUserUid').value = uid;
  document.getElementById('modalUserName').innerText = name;
  document.getElementById('notifTitle').value = '';
  document.getElementById('notifBody').value = '';
  document.getElementById('notifModal').classList.remove('hidden');
}

function closeNotifModal() {
  document.getElementById('notifModal').classList.add('hidden');
}

async function submitUserNotification() {
  const uid = document.getElementById('modalUserUid').value;
  const title = document.getElementById('notifTitle').value.trim();
  const body = document.getElementById('notifBody').value.trim();
  if (!title || !body) return alert('Title ಮತ್ತು Message ಖಾಲಿ ಇರಬಾರದು!');

  try {
    await db.collection('users').doc(uid).collection('notifications').add({
      title,
      body,
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      isRead: false
    });
    closeNotifModal();
    showToast('In-App Notice Sent Successfully!');
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

async function toggleBanUser(uid, currentlyBanned) {
  if (!confirm(`Are you sure you want to ${currentlyBanned ? 'Unban' : 'Ban'} this user?`)) return;
  await db.collection('users').doc(uid).update({ isBanned: !currentlyBanned });
  showToast(currentlyBanned ? 'User Unbanned' : 'User Banned');
}

// ------------------------------------------
// 5. TAB 4: DYNAMIC TASK MANAGER
// ------------------------------------------
function fetchTasks() {
  db.collection('tasks').onSnapshot(snap => {
    const list = document.getElementById('tasksList');
    list.innerHTML = '';

    if (snap.empty) {
      list.innerHTML = '<div class="p-8 text-center text-gray-500 dark-card rounded-2xl text-xs">No active tasks created yet.</div>';
      return;
    }

    snap.forEach(doc => {
      const t = doc.data();
      const id = doc.id;
      const isActive = t.isActive !== false;

      const card = document.createElement('div');
      card.className = `dark-card p-4 rounded-2xl flex items-center justify-between gap-3 ${!isActive ? 'opacity-40' : ''}`;

      card.innerHTML = `
        <div class="space-y-0.5">
          <div class="flex items-center gap-2">
            <span class="font-black text-sm text-white">${t.title}</span>
            <span class="text-[9px] bg-green-400/10 text-green-400 border border-green-400/20 px-2 py-0.5 rounded-full font-bold">+${t.coins} Coins</span>
          </div>
          <div class="text-[10px] text-gray-400">${t.category} • <a href="${t.url}" target="_blank" class="text-sky-400 underline">Open Link</a></div>
        </div>
        <div class="flex items-center gap-2">
          <button onclick="toggleTaskStatus('${id}', ${isActive})" class="px-2.5 py-1 text-[10px] font-bold rounded-lg ${isActive ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20' : 'bg-green-500/10 text-green-400 border border-green-500/20'}">
            ${isActive ? 'Pause' : 'Activate'}
          </button>
          <button onclick="deleteTask('${id}')" class="px-2.5 py-1 text-[10px] font-bold bg-red-500/10 text-red-400 border border-red-500/20 rounded-lg">
            Delete
          </button>
        </div>
      `;
      list.appendChild(card);
    });
  });
}

function openAddTaskModal() {
  document.getElementById('taskTitle').value = '';
  document.getElementById('taskCoins').value = '';
  document.getElementById('taskUrl').value = '';
  document.getElementById('taskModal').classList.remove('hidden');
}

function closeTaskModal() {
  document.getElementById('taskModal').classList.add('hidden');
}

async function saveNewTask() {
  const title = document.getElementById('taskTitle').value.trim();
  const coins = parseInt(document.getElementById('taskCoins').value) || 0;
  const category = document.getElementById('taskCategory').value;
  const url = document.getElementById('taskUrl').value.trim();

  if (!title || !coins || !url) return alert('Fill all fields correctly!');

  try {
    await db.collection('tasks').add({
      title,
      coins,
      category,
      url,
      isActive: true,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    closeTaskModal();
    showToast('Task Added & Live in App!');
  } catch (e) {
    alert('Error adding task: ' + e.message);
  }
}

async function toggleTaskStatus(id, currentlyActive) {
  await db.collection('tasks').doc(id).update({ isActive: !currentlyActive });
  showToast(currentlyActive ? 'Task Paused' : 'Task Activated');
}

async function deleteTask(id) {
  if (!confirm('Are you sure you want to delete this task?')) return;
  await db.collection('tasks').doc(id).delete();
  showToast('Task Deleted');
}

// ------------------------------------------
// 6. TAB 5: P1, P2, P3 CONFIG CONTROLS
// ------------------------------------------
async function fetchConfigs() {
  try {
    const p1Snap = await db.collection('app_config').doc('core').get();
    if (p1Snap.exists) {
      const c = p1Snap.data();
      document.getElementById('p1-coinRate').value = c.coinRate || 100;
      document.getElementById('p1-referBonus').value = c.referBonus || 5;
      document.getElementById('p1-minTask').value = c.minTask || 10;
      document.getElementById('p1-minRefer').value = c.minRefer || 50;
      document.getElementById('p1-announcement').value = c.announcement || '';
      document.getElementById('p1-announcementToggle').checked = c.showAnnouncement === true;
      document.getElementById('p1-maintenanceToggle').checked = c.maintenanceMode === true;
    }

    const p2Snap = await db.collection('app_config').doc('game').get();
    if (p2Snap.exists) {
      const g = p2Snap.data();
      document.getElementById('p2-wheelSlices').value = (g.wheelSlices || [10, 50, 25, 100, 15, 200]).join(', ');
      document.getElementById('p2-spinLimit').value = g.spinLimit || 3;
      document.getElementById('p2-scratchLimit').value = g.scratchLimit || 2;
    }

    const p3Snap = await db.collection('app_config').doc('security').get();
    if (p3Snap.exists) {
      const s = p3Snap.data();
      document.getElementById('p3-blockVPN').checked = s.blockVPN === true;
      document.getElementById('p3-blockRooted').checked = s.blockRooted === true;
      document.getElementById('p3-oneDevice').checked = s.oneDevice === true;
    }
  } catch (e) {
    console.log("Config load status: Ready.");
  }
}

async function saveP1Config() {
  const coinRate = parseInt(document.getElementById('p1-coinRate').value) || 100;
  const referBonus = parseInt(document.getElementById('p1-referBonus').value) || 5;
  const minTask = parseInt(document.getElementById('p1-minTask').value) || 10;
  const minRefer = parseInt(document.getElementById('p1-minRefer').value) || 50;
  const announcement = document.getElementById('p1-announcement').value.trim();
  const showAnnouncement = document.getElementById('p1-announcementToggle').checked;
  const maintenanceMode = document.getElementById('p1-maintenanceToggle').checked;

  try {
    await db.collection('app_config').doc('core').set({
      coinRate, referBonus, minTask, minRefer, announcement, showAnnouncement, maintenanceMode,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('P1 Core Config Saved!');
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

async function saveP2Config() {
  const slicesRaw = document.getElementById('p2-wheelSlices').value;
  const wheelSlices = slicesRaw.split(',').map(n => parseInt(n.trim())).filter(n => !isNaN(n));
  const spinLimit = parseInt(document.getElementById('p2-spinLimit').value) || 3;
  const scratchLimit = parseInt(document.getElementById('p2-scratchLimit').value) || 2;

  try {
    await db.collection('app_config').doc('game').set({
      wheelSlices, spinLimit, scratchLimit,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('P2 Game Config Saved!');
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

async function saveP3Config() {
  const blockVPN = document.getElementById('p3-blockVPN').checked;
  const blockRooted = document.getElementById('p3-blockRooted').checked;
  const oneDevice = document.getElementById('p3-oneDevice').checked;

  try {
    await db.collection('app_config').doc('security').set({
      blockVPN, blockRooted, oneDevice,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('P3 Security Shield Saved!');
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

function copyText(txt) {
  navigator.clipboard.writeText(txt).then(() => showToast('Copied to Clipboard!'));
}

function showToast(msg) {
  const t = document.getElementById('toast');
  t.innerText = msg;
  t.classList.remove('hidden');
  setTimeout(() => t.classList.add('hidden'), 2200);
}

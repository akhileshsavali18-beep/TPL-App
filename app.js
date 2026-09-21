// ==========================================
// TPL PRO ADMIN CONSOLE - AIRTIGHT SECURE ENGINE
// ==========================================

// 🔒 ನಿಮ್ಮ Firebase Admin UID
var AUTHORIZED_ADMIN_UID = "VsGSj7MPsoXIwLbBKPey4rV4Oxg1";

var firebaseConfig = {
  apiKey: "AIzaSyCMFViBcyJVEawOZASTQ9qr2zDwIqhqKn8",
  authDomain: "tpl-5bd9d.firebaseapp.com",
  projectId: "tpl-5bd9d",
  storageBucket: "tpl-5bd9d.firebasestorage.app",
  messagingSenderId: "940679131159",
  appId: "1:940679131159:web:8b3de2fbf61b57615a2c52",
  measurementId: "G-KRP2LPFGQ4"
};

// 1. Initialize Firebase App
if (!firebase.apps.length) {
  firebase.initializeApp(firebaseConfig);
}

var allUsersData = [];
var pendingWithdrawalsCache = [];

// 2. Auth State Listener (Security Check)
firebase.auth().onAuthStateChanged(function(user) {
  if (user) {
    if (user.uid === AUTHORIZED_ADMIN_UID) {
      // 100% Verified Admin
      document.getElementById('loginScreen').classList.add('hidden');
      document.getElementById('dashboardScreen').classList.remove('hidden');
      fetchAllData();
    } else {
      alert("🚨 Access Denied! ಈ ಖಾತೆಗೆ ಅಡ್ಮಿನ್ ಪ್ಯಾನೆಲ್ ಪ್ರವೇಶಿಸಲು ಅನುಮತಿ ಇಲ್ಲ.");
      firebase.auth().signOut();
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
  var email = document.getElementById('adminEmail').value.trim();
  var pass = document.getElementById('adminPassword').value.trim();
  var btn = document.getElementById('loginBtn');

  if (!email || !pass) {
    alert("Admin Email ಮತ್ತು Password ಎರಡನ್ನೂ ಹಾಕಿ!");
    return;
  }

  btn.innerText = "Verifying Credentials...";
  btn.disabled = true;

  try {
    var cred = await firebase.auth().signInWithEmailAndPassword(email, pass);
    if (cred.user.uid !== AUTHORIZED_ADMIN_UID) {
      alert("🚨 Access Denied: Authorized Admin UID ಮ್ಯಾಚ್ ಆಗಿಲ್ಲ.");
      await firebase.auth().signOut();
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
  firebase.auth().signOut();
  location.reload();
}

// ------------------------------------------
// 2. BOTTOM NAVIGATION SWITCHER
// ------------------------------------------
function switchTab(tab) {
  var tabs = ['dashboard', 'payouts', 'users', 'tasks', 'settings'];
  tabs.forEach(function(t) {
    var content = document.getElementById('tabContent-' + t);
    var navBtn = document.getElementById('nav-' + t);
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
  firebase.firestore().collection('withdrawals').orderBy('createdAt', 'desc').onSnapshot(function(snap) {
    var list = document.getElementById('withdrawalsList');
    list.innerHTML = '';
    var pCount = 0, pAmt = 0, cAmt = 0;
    pendingWithdrawalsCache = [];

    if (snap.empty) {
      list.innerHTML = '<div class="p-8 text-center text-gray-500 dark-card rounded-2xl text-xs">No withdrawal requests found.</div>';
    }

    snap.forEach(function(doc) {
      var d = doc.data();
      var id = doc.id;
      var isPending = d.status === 'Pending';

      if (isPending) {
        pCount++;
        pAmt += (d.amount || 0);
        pendingWithdrawalsCache.push(Object.assign({ id: id }, d));
      } else if (d.status === 'Completed') {
        cAmt += (d.amount || 0);
      }

      var card = document.createElement('div');
      card.className = "dark-card p-4 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 " + (!isPending ? 'opacity-40' : '');

      var upiPayLink = "upi://pay?pa=" + encodeURIComponent(d.upiId || '') + "&pn=" + encodeURIComponent(d.userName || 'TPL Player') + "&am=" + d.amount + "&cu=INR&tn=TPL_Payout";

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

    var badge = document.getElementById('navBadge');
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
  var csv = "TransferId,Amount,Phone,Email,Name,BeneficiaryId,VPA\n";
  pendingWithdrawalsCache.forEach(function(item) {
    csv += "TPL_" + item.id + "," + item.amount + ",,," + (item.userName || 'Player') + ",," + item.upiId + "\n";
  });
  var blob = new Blob([csv], { type: 'text/csv' });
  var url = window.URL.createObjectURL(blob);
  var a = document.createElement('a');
  a.setAttribute('href', url);
  a.setAttribute('download', "Cashfree_Batch_" + new Date().toISOString().slice(0,10) + ".csv");
  a.click();
  showToast('Cashfree CSV Exported!');
}

async function markAsPaid(docId) {
  if (!confirm("Confirm payment sent to user?")) return;
  await firebase.firestore().collection('withdrawals').doc(docId).update({
    status: 'Completed',
    paidAt: firebase.firestore.FieldValue.serverTimestamp()
  });
  showToast('Marked as Paid!');
}

async function rejectRequest(docId, uid, amount, type) {
  var reason = prompt("Enter rejection reason (e.g., Invalid UPI ID):");
  if (reason === null) return;
  var field = type === 'Task Cash' ? 'taskCash' : 'referCash';
  var updateData = {};
  updateData[field] = firebase.firestore.FieldValue.increment(amount);
  await firebase.firestore().collection('users').doc(uid).update(updateData);
  await firebase.firestore().collection('withdrawals').doc(docId).update({
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
  firebase.firestore().collection('users').onSnapshot(function(snap) {
    allUsersData = [];
    snap.forEach(function(doc) {
      allUsersData.push(Object.assign({ uid: doc.id }, doc.data()));
    });
    document.getElementById('statTotalUsers').innerText = allUsersData.length;
    renderUsers(allUsersData);
  });
}

function renderUsers(users) {
  var list = document.getElementById('usersList');
  list.innerHTML = '';
  if (!users.length) {
    list.innerHTML = '<div class="p-8 text-center text-gray-500 dark-card rounded-2xl text-xs">No users found.</div>';
    return;
  }

  users.forEach(function(u) {
    var isBanned = u.isBanned === true;
    var card = document.createElement('div');
    card.className = "dark-card p-4 rounded-2xl flex flex-col sm:flex-row sm:items-center justify-between gap-3 " + (isBanned ? 'border-red-500/30 bg-red-950/10' : '');

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
  var q = document.getElementById('userSearchInput').value.toLowerCase();
  var filtered = allUsersData.filter(function(u) {
    return (u.displayName || '').toLowerCase().includes(q) ||
           (u.email || '').toLowerCase().includes(q) ||
           (u.upiId || '').toLowerCase().includes(q);
  });
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
  var uid = document.getElementById('modalUserUid').value;
  var title = document.getElementById('notifTitle').value.trim();
  var body = document.getElementById('notifBody').value.trim();
  if (!title || !body) return alert('Title ಮತ್ತು Message ಖಾಲಿ ಇರಬಾರದು!');

  try {
    await firebase.firestore().collection('users').doc(uid).collection('notifications').add({
      title: title,
      body: body,
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
  if (!confirm("Are you sure you want to " + (currentlyBanned ? 'Unban' : 'Ban') + " this user?")) return;
  await firebase.firestore().collection('users').doc(uid).update({ isBanned: !currentlyBanned });
  showToast(currentlyBanned ? 'User Unbanned' : 'User Banned');
}

// ------------------------------------------
// 5. TAB 4: DYNAMIC TASK MANAGER
// ------------------------------------------
function fetchTasks() {
  firebase.firestore().collection('tasks').onSnapshot(function(snap) {
    var list = document.getElementById('tasksList');
    list.innerHTML = '';

    if (snap.empty) {
      list.innerHTML = '<div class="p-8 text-center text-gray-500 dark-card rounded-2xl text-xs">No active tasks created yet.</div>';
      return;
    }

    snap.forEach(function(doc) {
      var t = doc.data();
      var id = doc.id;
      var isActive = t.isActive !== false;

      var card = document.createElement('div');
      card.className = "dark-card p-4 rounded-2xl flex items-center justify-between gap-3 " + (!isActive ? 'opacity-40' : '');

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
  var title = document.getElementById('taskTitle').value.trim();
  var coins = parseInt(document.getElementById('taskCoins').value) || 0;
  var category = document.getElementById('taskCategory').value;
  var url = document.getElementById('taskUrl').value.trim();

  if (!title || !coins || !url) return alert('Fill all fields correctly!');

  try {
    await firebase.firestore().collection('tasks').add({
      title: title,
      coins: coins,
      category: category,
      url: url,
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
  await firebase.firestore().collection('tasks').doc(id).update({ isActive: !currentlyActive });
  showToast(currentlyActive ? 'Task Paused' : 'Task Activated');
}

async function deleteTask(id) {
  if (!confirm('Are you sure you want to delete this task?')) return;
  await firebase.firestore().collection('tasks').doc(id).delete();
  showToast('Task Deleted');
}

// ------------------------------------------
// 6. TAB 5: P1, P2, P3 CONFIG CONTROLS
// ------------------------------------------
async function fetchConfigs() {
  try {
    var p1Snap = await firebase.firestore().collection('app_config').doc('core').get();
    if (p1Snap.exists) {
      var c = p1Snap.data();
      document.getElementById('p1-coinRate').value = c.coinRate || 100;
      document.getElementById('p1-referBonus').value = c.referBonus || 5;
      document.getElementById('p1-minTask').value = c.minTask || 10;
      document.getElementById('p1-minRefer').value = c.minRefer || 50;
      document.getElementById('p1-announcement').value = c.announcement || '';
      document.getElementById('p1-announcementToggle').checked = c.showAnnouncement === true;
      document.getElementById('p1-maintenanceToggle').checked = c.maintenanceMode === true;
    }

    var p2Snap = await firebase.firestore().collection('app_config').doc('game').get();
    if (p2Snap.exists) {
      var g = p2Snap.data();
      document.getElementById('p2-wheelSlices').value = (g.wheelSlices || [10, 50, 25, 100, 15, 200]).join(', ');
      document.getElementById('p2-spinLimit').value = g.spinLimit || 3;
      document.getElementById('p2-scratchLimit').value = g.scratchLimit || 2;
    }

    var p3Snap = await firebase.firestore().collection('app_config').doc('security').get();
    if (p3Snap.exists) {
      var s = p3Snap.data();
      document.getElementById('p3-blockVPN').checked = s.blockVPN === true;
      document.getElementById('p3-blockRooted').checked = s.blockRooted === true;
      document.getElementById('p3-oneDevice').checked = s.oneDevice === true;
    }
  } catch (e) {
    console.log("Config load status: Ready.");
  }
}

async function saveP1Config() {
  var coinRate = parseInt(document.getElementById('p1-coinRate').value) || 100;
  var referBonus = parseInt(document.getElementById('p1-referBonus').value) || 5;
  var minTask = parseInt(document.getElementById('p1-minTask').value) || 10;
  var minRefer = parseInt(document.getElementById('p1-minRefer').value) || 50;
  var announcement = document.getElementById('p1-announcement').value.trim();
  var showAnnouncement = document.getElementById('p1-announcementToggle').checked;
  var maintenanceMode = document.getElementById('p1-maintenanceToggle').checked;

  try {
    await firebase.firestore().collection('app_config').doc('core').set({
      coinRate: coinRate,
      referBonus: referBonus,
      minTask: minTask,
      minRefer: minRefer,
      announcement: announcement,
      showAnnouncement: showAnnouncement,
      maintenanceMode: maintenanceMode,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('P1 Core Config Saved!');
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

async function saveP2Config() {
  var slicesRaw = document.getElementById('p2-wheelSlices').value;
  var wheelSlices = slicesRaw.split(',').map(function(n) { return parseInt(n.trim()); }).filter(function(n) { return !isNaN(n); });
  var spinLimit = parseInt(document.getElementById('p2-spinLimit').value) || 3;
  var scratchLimit = parseInt(document.getElementById('p2-scratchLimit').value) || 2;

  try {
    await firebase.firestore().collection('app_config').doc('game').set({
      wheelSlices: wheelSlices,
      spinLimit: spinLimit,
      scratchLimit: scratchLimit,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('P2 Game Config Saved!');
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

async function saveP3Config() {
  var blockVPN = document.getElementById('p3-blockVPN').checked;
  var blockRooted = document.getElementById('p3-blockRooted').checked;
  var oneDevice = document.getElementById('p3-oneDevice').checked;

  try {
    await firebase.firestore().collection('app_config').doc('security').set({
      blockVPN: blockVPN,
      blockRooted: blockRooted,
      oneDevice: oneDevice,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('P3 Security Shield Saved!');
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

// ------------------------------------------
// 7. UTILITIES
// ------------------------------------------
function copyText(txt) {
  navigator.clipboard.writeText(txt).then(function() {
    showToast('Copied to Clipboard!');
  });
}

function showToast(msg) {
  var t = document.getElementById('toast');
  t.innerText = msg;
  t.classList.remove('hidden');
  setTimeout(function() {
    t.classList.add('hidden');
  }, 2200);
}

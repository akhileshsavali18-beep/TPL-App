let cachedUsers = [];

function listenUsers() {
  db.collection('users').onSnapshot(snap => {
    document.getElementById('statTotalUsers').innerText = snap.size;
    cachedUsers = [];
    snap.forEach(d => cachedUsers.push({ id: d.id, ...d.data() }));
    renderUsers(cachedUsers);
  });
}

function renderUsers(users) {
  const container = document.getElementById('usersList');
  if (!container) return;
  if (!users.length) { container.innerHTML = '<div class="text-center py-10 text-gray-500 text-xs">No users registered.</div>'; return; }

  container.innerHTML = '';
  users.forEach(u => {
    const div = document.createElement('div');
    div.className = 'dark-card p-4 rounded-2xl space-y-2.5';
    div.innerHTML = `
      <div class="flex justify-between items-start">
        <div>
          <div class="flex items-center gap-2"><span class="text-sm font-black text-white">${u.displayName || 'Player'}</span><span class="text-[10px] text-amber-400 font-bold">★ ${u.coins || 0} Coins</span></div>
          <div class="text-xs text-gray-400 mt-0.5">${u.email || 'No email'}</div>
          <div class="text-xs text-green-400 font-semibold mt-1">UPI: ${u.upiId || 'Not Saved'}</div>
        </div>
        <div class="text-right">
          <div class="text-xs text-gray-400">Cash: <span class="font-bold text-white">₹${parseFloat(u.taskCash || 0).toFixed(2)}</span></div>
        </div>
      </div>
      <div class="flex gap-2 pt-2 border-t border-white/5">
        <button onclick="openEditUserModal('${u.id}')" class="flex-1 py-1.5 bg-blue-500/10 text-blue-400 text-xs font-bold rounded-xl active:scale-95">✏️ Edit</button>
        <button onclick="openNotifModal('${u.id}', '${u.displayName || u.email}')" class="flex-1 py-1.5 bg-white/5 text-gray-300 text-xs font-bold rounded-xl active:scale-95">🔔 Alert</button>
      </div>`;
    container.appendChild(div);
  });
}

function filterUsers() {
  const q = document.getElementById('userSearchInput').value.toLowerCase();
  renderUsers(cachedUsers.filter(u => (u.displayName && u.displayName.toLowerCase().includes(q)) || (u.email && u.email.toLowerCase().includes(q)) || (u.upiId && u.upiId.toLowerCase().includes(q))));
}

function openEditUserModal(uid) {
  const u = cachedUsers.find(user => user.id === uid);
  if (!u) return alert('User not found!');
  document.getElementById('editUserId').value = uid;
  document.getElementById('editUserName').value = u.displayName || '';
  document.getElementById('editUserCoins').value = u.coins || 0;
  document.getElementById('editUserTaskCash').value = u.taskCash || 0;
  document.getElementById('editUserUpi').value = u.upiId || '';
  document.getElementById('editUserModal').classList.remove('hidden');
}

function closeEditUserModal() { document.getElementById('editUserModal').classList.add('hidden'); }

async function saveUserEdit() {
  const uid = document.getElementById('editUserId').value;
  try {
    await db.collection('users').doc(uid).update({
      displayName: document.getElementById('editUserName').value.trim(),
      coins: parseInt(document.getElementById('editUserCoins').value) || 0,
      taskCash: parseFloat(document.getElementById('editUserTaskCash').value) || 0.0,
      upiId: document.getElementById('editUserUpi').value.trim()
    });
    showToast('User Updated!');
    closeEditUserModal();
  } catch (e) { alert('Error: ' + e.message); }
}

function openNotifModal(uid, name) {
  document.getElementById('modalUserUid').value = uid;
  document.getElementById('notifModal').classList.remove('hidden');
}
function closeNotifModal() { document.getElementById('notifModal').classList.add('hidden'); }

async function submitUserNotification() {
  const uid = document.getElementById('modalUserUid').value;
  const msg = document.getElementById('notifBody').value.trim();
  if (!uid || !msg) return alert('Enter alert message!');
  try {
    await db.collection('users').doc(uid).collection('notifications').add({
      title: document.getElementById('notifTitle').value.trim() || '📢 TPL Notice',
      message: msg,
      read: false,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('Alert Sent Successfully!');
    closeNotifModal();
  } catch (e) { alert('Failed: ' + e.message); }
}
  

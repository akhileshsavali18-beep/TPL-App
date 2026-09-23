// ==========================================
// USERS DIRECTORY MODULE (js/users.js)
// ==========================================

let cachedUsers = [];

// 1. Listen to Users Directory
function listenUsers() {
  db.collection('users').onSnapshot(snap => {
    const totalUsersEl = document.getElementById('statTotalUsers');
    if (totalUsersEl) totalUsersEl.innerText = snap.size;

    cachedUsers = [];
    snap.forEach(d => cachedUsers.push({ id: d.id, ...d.data() }));
    renderUsers(cachedUsers);
  });
}

// 2. Render Users List
function renderUsers(users) {
  const container = document.getElementById('usersList');
  if (!container) return;

  if (users.length === 0) {
    container.innerHTML = '<div class="text-center py-10 text-gray-500 text-xs">No users registered yet.</div>';
    return;
  }

  container.innerHTML = '';
  users.forEach(u => {
    const div = document.createElement('div');
    div.className = 'dark-card p-4 rounded-2xl space-y-2.5';
    div.innerHTML = `
      <div class="flex justify-between items-start">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-sm font-black text-white">${u.displayName || 'Player'}</span>
            <span class="text-[10px] text-amber-400 font-bold">★ ${u.coins || 0} Coins</span>
            ${u.isBanned ? '<span class="text-[9px] bg-red-500/20 text-red-400 px-1.5 rounded font-black">BANNED</span>' : ''}
          </div>
          <div class="text-xs text-gray-400 mt-0.5">${u.email || 'No email'}</div>
          <div class="text-xs text-green-400 font-semibold mt-1">UPI: ${u.upiId || 'Not Saved'}</div>
        </div>
        <div class="text-right">
          <div class="text-xs text-gray-400">Cash: <span class="font-bold text-white">₹${parseFloat(u.taskCash || 0).toFixed(2)}</span></div>
          <div class="text-xs text-gray-400">Refer: <span class="font-bold text-purple-400">₹${parseFloat(u.referCash || 0).toFixed(2)}</span></div>
        </div>
      </div>
      <div class="flex gap-2 pt-2 border-t border-white/5">
        <button onclick="openEditUserModal('${u.id}')" class="flex-1 py-1.5 bg-blue-500/10 hover:bg-blue-500/20 text-blue-400 text-xs font-bold rounded-xl active:scale-95">
          ✏️ Edit
        </button>
        <button onclick="openNotifModal('${u.id}', '${u.displayName || u.email}')" class="flex-1 py-1.5 bg-white/5 hover:bg-white/10 text-gray-300 text-xs font-bold rounded-xl active:scale-95">
          🔔 Alert
        </button>
        <button onclick="toggleBanUser('${u.id}', ${u.isBanned || false})" class="flex-1 py-1.5 ${u.isBanned ? 'bg-green-500/10 text-green-400' : 'bg-red-500/10 text-red-400'} text-xs font-bold rounded-xl active:scale-95">
          ${u.isBanned ? 'Unban' : 'Ban'}
        </button>
      </div>
    `;
    container.appendChild(div);
  });
}

// 3. Search Filter
function filterUsers() {
  const q = document.getElementById('userSearchInput').value.toLowerCase();
  const filtered = cachedUsers.filter(u =>
    (u.displayName && u.displayName.toLowerCase().includes(q)) ||
    (u.email && u.email.toLowerCase().includes(q)) ||
    (u.upiId && u.upiId.toLowerCase().includes(q))
  );
  renderUsers(filtered);
}

// 4. Edit User Modal & Logic
function openEditUserModal(uid) {
  const u = cachedUsers.find(user => user.id === uid);
  if (!u) return alert('User not found!');

  document.getElementById('editUserId').value = uid;
  document.getElementById('editUserName').value = u.displayName || '';
  document.getElementById('editUserCoins').value = u.coins || 0;
  document.getElementById('editUserTaskCash').value = u.taskCash || 0;
  document.getElementById('editUserReferCash').value = u.referCash || 0;
  document.getElementById('editUserUpi').value = u.upiId || '';
  document.getElementById('editUserModal').classList.remove('hidden');
}

function closeEditUserModal() {
  document.getElementById('editUserModal').classList.add('hidden');
}

async function saveUserEdit() {
  const uid = document.getElementById('editUserId').value;
  const name = document.getElementById('editUserName').value.trim();
  const coins = parseInt(document.getElementById('editUserCoins').value) || 0;
  const taskCash = parseFloat(document.getElementById('editUserTaskCash').value) || 0.0;
  const referCash = parseFloat(document.getElementById('editUserReferCash').value) || 0.0;
  const upiId = document.getElementById('editUserUpi').value.trim();

  try {
    await db.collection('users').doc(uid).update({
      displayName: name,
      coins: coins,
      taskCash: taskCash,
      referCash: referCash,
      upiId: upiId
    });
    showToast('User profile updated successfully!');
    closeEditUserModal();
  } catch (e) {
    alert('Error updating user: ' + e.message);
  }
}

// 5. In-App Alert Notice Modal & Send
function openNotifModal(uid, name) {
  document.getElementById('modalUserUid').value = uid;
  document.getElementById('notifTitle').value = '📢 TPL Notice';
  document.getElementById('notifBody').value = '';
  document.getElementById('notifModal').classList.remove('hidden');
}

function closeNotifModal() {
  document.getElementById('notifModal').classList.add('hidden');
}

async function submitUserNotification() {
  const uid = document.getElementById('modalUserUid').value;
  const title = document.getElementById('notifTitle').value.trim();
  const msg = document.getElementById('notifBody').value.trim();
  if (!uid || !msg) return alert('Enter alert message!');

  try {
    await db.collection('users').doc(uid).collection('notifications').add({
      title: title || '📢 TPL Notice',
      message: msg,
      read: false,
      createdAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    showToast('Alert Sent Successfully!');
    closeNotifModal();
  } catch (e) {
    alert('Failed: ' + e.message);
  }
}

// 6. Ban / Unban User
async function toggleBanUser(uid, isBanned) {
  const act = isBanned ? 'Unban' : 'Ban';
  if (!confirm(`Are you sure you want to ${act} this user?`)) return;
  try {
    await db.collection('users').doc(uid).update({ isBanned: !isBanned });
    showToast(`User ${act}ned!`);
  } catch (e) {
    alert('Error: ' + e.message);
  }
}

// Auto-run when authenticated
auth.onAuthStateChanged(user => {
  if (user) {
    listenUsers();
  }
});
                

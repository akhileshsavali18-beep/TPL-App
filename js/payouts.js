// ==========================================
// PAYOUTS MODULE (js/payouts.js) - WITH ERROR DETECTOR
// ==========================================

// 1. On-Screen Script Error Catcher (ಯಾವುದೇ ಸ್ಕ್ರಿಪ್ಟ್ ಎರರ್ ಬಂದರೆ ಸ್ಕ್ರೀನ್ ಮೇಲೆಯೇ ತೋರಿಸುತ್ತದೆ)
window.addEventListener('error', function(e) {
  const container = document.getElementById('withdrawalsList');
  if (container) {
    container.innerHTML = `
      <div class="p-4 rounded-2xl bg-red-500/10 border border-red-500/30 text-center space-y-1">
        <div class="text-xs font-bold text-red-400">⚠️ Script Error Found:</div>
        <div class="text-[11px] text-white font-mono">${e.message}</div>
        <div class="text-[9px] text-gray-400">File: ${e.filename ? e.filename.split('/').pop() : 'script'} (Line: ${e.lineno})</div>
      </div>`;
  }
});

// Safe global variable (Duplicate declaration crash ಆಗುವುದಿಲ್ಲ)
window.cachedWithdrawals = window.cachedWithdrawals || [];

function listenWithdrawals() {
  const container = document.getElementById('withdrawalsList');
  if (!container) return;

  try {
    if (typeof db === 'undefined') {
      container.innerHTML = '<div class="text-center py-6 text-red-400 text-xs font-bold">⚠️ Firebase DB not initialized!</div>';
      return;
    }

    db.collection('withdrawals').onSnapshot(snap => {
      window.cachedWithdrawals = [];
      let pendingCount = 0;
      let pendingAmount = 0.0;
      let totalPaid = 0.0;

      snap.forEach(d => {
        const w = { id: d.id, ...d.data() };
        window.cachedWithdrawals.push(w);

        const amt = parseFloat(w.amount) || 0.0;
        const st = (w.status || 'pending').toLowerCase();

        if (st === 'pending') {
          pendingCount++;
          pendingAmount += amt;
        } else if (['completed', 'success', 'settled', 'paid'].includes(st)) {
          totalPaid += amt;
        }
      });

      // Sort recent first
      window.cachedWithdrawals.sort((a, b) => (b.createdAt?.seconds || 0) - (a.createdAt?.seconds || 0));

      // Update Home Metrics Live
      const pCountEl = document.getElementById('statPendingCount');
      const pAmtEl = document.getElementById('statPendingAmount');
      const paidAmtEl = document.getElementById('statPaidAmount');
      const badgeEl = document.getElementById('navBadge');

      if (pCountEl) pCountEl.innerText = pendingCount;
      if (pAmtEl) pAmtEl.innerText = '₹' + pendingAmount.toFixed(2);
      if (paidAmtEl) paidAmtEl.innerText = '₹' + totalPaid.toFixed(2);

      if (badgeEl) {
        badgeEl.innerText = pendingCount;
        if (pendingCount > 0) badgeEl.classList.remove('hidden');
        else badgeEl.classList.add('hidden');
      }

      renderWithdrawals(window.cachedWithdrawals);
    }, err => {
      console.error("Payouts Firestore Error:", err);
      container.innerHTML = `
        <div class="p-4 rounded-2xl bg-red-500/10 border border-red-500/30 text-center space-y-1">
          <div class="text-xs font-bold text-red-400">⚠️ Firestore Error:</div>
          <div class="text-[11px] text-white">${err.message}</div>
        </div>`;
    });
  } catch (err) {
    container.innerHTML = `
      <div class="p-4 rounded-2xl bg-red-500/10 border border-red-500/30 text-center space-y-1">
        <div class="text-xs font-bold text-red-400">⚠️ Execution Error:</div>
        <div class="text-[11px] text-white">${err.message}</div>
      </div>`;
  }
}

function renderWithdrawals(withdrawals) {
  const container = document.getElementById('withdrawalsList');
  if (!container) return;

  if (!withdrawals || withdrawals.length === 0) {
    container.innerHTML = '<div class="text-center py-10 text-gray-500 text-xs">No withdrawal requests found in database.</div>';
    return;
  }

  container.innerHTML = '';
  withdrawals.forEach(w => {
    const st = (w.status || 'pending').toLowerCase();
    const isPending = st === 'pending';
    const isSuccess = ['completed', 'success', 'settled', 'paid'].includes(st);
    const isRejected = st === 'rejected';

    let badgeClass = 'bg-amber-400/10 text-amber-400 border border-amber-400/20';
    if (isSuccess) badgeClass = 'bg-green-400/10 text-green-400 border border-green-400/20';
    if (isRejected) badgeClass = 'bg-red-400/10 text-red-400 border border-red-400/20';

    const div = document.createElement('div');
    div.className = 'dark-card p-4 rounded-2xl space-y-3';
    div.innerHTML = `
      <div class="flex items-start justify-between">
        <div>
          <div class="flex items-center gap-2">
            <span class="text-sm font-black text-white">${w.userName || 'TPL Player'}</span>
            <span class="text-[9px] font-black px-2 py-0.5 rounded-md uppercase ${badgeClass}">${st}</span>
          </div>
          <div class="text-[11px] text-gray-400 mt-0.5">${w.type || 'Cash Balance'}</div>
          <div class="flex items-center gap-1.5 text-xs text-gray-300 font-semibold mt-1">
            <span>${w.upiId || 'No UPI'}</span>
            <button onclick="copyToClipboard('${w.upiId || ''}')" class="text-gray-500 hover:text-green-400 text-[10px]">📋 Copy</button>
          </div>
        </div>
        <div class="text-right">
          <div class="text-xl font-black text-green-400">₹${parseFloat(w.amount || 0).toFixed(2)}</div>
          <div class="text-[9px] text-gray-500">${w.createdAt?.toDate ? w.createdAt.toDate().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}) : 'Recent'}</div>
        </div>
      </div>

      <div class="flex items-center gap-2 pt-2 border-t border-white/5">
        <!-- 📲 Pay UPI Button (Pending ಇದ್ದಾಗ ಮಾತ್ರ ಕಾಣುತ್ತದೆ) -->
        ${isPending ? `
          <button onclick="payViaUPI('${w.upiId || ''}', ${w.amount \vert{}\vert{} 0}, '${w.id}')" class="flex-1 py-2 bg-blue-600 hover:bg-blue-500 text-white rounded-xl text-xs font-bold flex items-center justify-center gap-1 active:scale-95">
            <span>📲 Pay UPI</span>
          </button>
        ` : ''}

        <!-- Status Controller -->
        <select onchange="updateWithdrawalStatus('${w.id}', '${w.uid}', ${w.amount}, '${w.upiId}', '${w.type || 'Cash'}', '${st}', this.value)" class="${isPending ? 'flex-1' : 'w-full'} py-2 px-2 bg-black/60 border border-white/10 rounded-xl text-xs text-white font-bold focus:outline-none">
          <option value="pending" ${isPending ? 'selected' : ''}>⏳ Pending</option>
          <option value="completed" ${isSuccess ? 'selected' : ''}>✅ Success</option>
          <option value="rejected" ${isRejected ? 'selected' : ''}>❌ Rejected</option>
        </select>
      </div>
    `;
    container.appendChild(div);
  });
}

function payViaUPI(upiId, amount, reqId) {
  if (!upiId) return alert('UPI ID not found!');
  const note = encodeURIComponent('TPL PAYOUT ' + reqId);
  window.location.href = `upi://pay?pa=${upiId.trim()}&pn=TPL%20App&am=${parseFloat(amount).toFixed(2)}&tn=${note}&cu=INR`;
}

async function updateWithdrawalStatus(reqId, uid, amount, upiId, type, oldStatus, newStatus) {
  if (oldStatus === newStatus) return;

  try {
    await db.collection('withdrawals').doc(reqId).update({
      status: newStatus,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp(),
      ...(newStatus === 'completed' ? { paidAt: firebase.firestore.FieldValue.serverTimestamp() } : {})
    });

    if (newStatus === 'rejected' && oldStatus === 'pending' && uid) {
      const isRefer = (type || '').toLowerCase().includes('refer');
      const refundField = isRefer ? 'referCash' : 'taskCash';

      await db.collection('users').doc(uid).update({
        [refundField]: firebase.firestore.FieldValue.increment(parseFloat(amount))
      });

      await db.collection('users').doc(uid).collection('notifications').add({
        title: '❌ Withdrawal Rejected',
        message: `Your withdrawal of ₹${parseFloat(amount).toFixed(2)} was rejected. Refunded to balance.`,
        read: false,
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      });

      showToast(`Rejected & ₹${amount} Refunded to User!`);
      return;
    }

    if (newStatus === 'completed' && uid) {
      await db.collection('users').doc(uid).collection('notifications').add({
        title: '🎉 Payout Successful!',
        message: `Your withdrawal of ₹${parseFloat(amount).toFixed(2)} has been credited to ${upiId || 'your UPI'}!`,
        read: false,
        createdAt: firebase.firestore.FieldValue.serverTimestamp()
      });

      showToast('Status: Completed & Notification Sent!');
      return;
    }

    showToast('Status updated to ' + newStatus);
  } catch (e) {
    alert('Error updating status: ' + e.message);
  }
}

function copyToClipboard(text) {
  if (!text) return;
  navigator.clipboard.writeText(text);
  showToast('Copied: ' + text);
}

// 1. Immediate Run
listenWithdrawals();

// 2. Run on Auth Change
if (typeof auth !== 'undefined') {
  auth.onAuthStateChanged(user => {
    if (user) listenWithdrawals();
  })
}
    

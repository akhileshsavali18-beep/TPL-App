let cachedWithdrawals = [];

function listenWithdrawals() {
  db.collection('withdrawals').orderBy('createdAt', 'desc').onSnapshot(snap => {
    cachedWithdrawals = [];
    let pendingCount = 0;
    let pendingAmount = 0.0;
    let totalPaid = 0.0;

    snap.forEach(d => {
      const w = { id: d.id, ...d.data() };
      cachedWithdrawals.push(w);
      const amt = parseFloat(w.amount) || 0.0;
      const st = (w.status || 'pending').toLowerCase();

      if (st === 'pending') { pendingCount++; pendingAmount += amt; }
      else if (st === 'completed' || st === 'success' || st === 'settled' || st === 'paid') { totalPaid += amt; }
    });

    document.getElementById('statPendingCount').innerText = pendingCount;
    document.getElementById('statPendingAmount').innerText = '₹' + pendingAmount.toFixed(2);
    document.getElementById('statPaidAmount').innerText = '₹' + totalPaid.toFixed(2);

    renderWithdrawals(cachedWithdrawals);
  });
}

function renderWithdrawals(withdrawals) {
  const container = document.getElementById('withdrawalsList');
  if (!container) return;
  if (!withdrawals.length) { container.innerHTML = '<div class="text-center py-10 text-gray-500 text-xs">No withdrawals found.</div>'; return; }

  container.innerHTML = '';
  withdrawals.forEach(w => {
    const st = (w.status || 'pending').toLowerCase();
    const isPending = st === 'pending';
    const isSuccess = st === 'completed' || st === 'success' || st === 'settled' || st === 'paid';
    const badgeClass = isSuccess ? 'bg-green-400/10 text-green-400' : (st === 'rejected' ? 'bg-red-400/10 text-red-400' : 'bg-amber-400/10 text-amber-400');

    const div = document.createElement('div');
    div.className = 'dark-card p-4 rounded-2xl space-y-3';
    div.innerHTML = `
      <div class="flex items-start justify-between">
        <div>
          <div class="flex items-center gap-2"><span class="text-sm font-black text-white">${w.userName || 'TPL Player'}</span><span class="text-[9px] font-black px-2 py-0.5 rounded-md uppercase ${badgeClass}">${st}</span></div>
          <div class="text-xs text-gray-300 font-semibold mt-1">${w.upiId || 'No UPI'}</div>
        </div>
        <div class="text-xl font-black text-green-400">₹${parseFloat(w.amount || 0).toFixed(2)}</div>
      </div>
      <div class="flex items-center gap-2 pt-2 border-t border-white/5">
        ${isPending ? `<button onclick="payViaUPI('${w.upiId || ''}', ${w.amount \vert{}\vert{} 0}, '${w.id}')" class="flex-1 py-2 bg-blue-600 text-white rounded-xl text-xs font-bold active:scale-95">📲 Pay UPI</button>` : ''}
        <select onchange="updateWithdrawalStatus('${w.id}', '${w.uid}', ${w.amount}, '${w.type || 'Cash'}', '${st}', this.value)" class="${isPending ? 'flex-1' : 'w-full'} py-2 px-2 bg-black/60 border border-white/10 rounded-xl text-xs text-white font-bold">
          <option value="pending" ${isPending ? 'selected' : ''}>⏳ Pending</option>
          <option value="completed" ${isSuccess ? 'selected' : ''}>✅ Success</option>
          <option value="rejected" ${st === 'rejected' ? 'selected' : ''}>❌ Rejected</option>
        </select>
      </div>`;
    container.appendChild(div);
  });
}

function payViaUPI(upiId, amount, reqId) {
  if (!upiId) return alert('UPI ID not found!');
  window.location.href = `upi://pay?pa=${upiId.trim()}&pn=TPL%20App&am=${parseFloat(amount).toFixed(2)}&tn=${encodeURIComponent('TPL WITHDRAW ' + reqId)}&cu=INR`;
}

async function updateWithdrawalStatus(reqId, uid, amount, type, oldStatus, newStatus) {
  if (oldStatus === newStatus) return;
  try {
    await db.collection('withdrawals').doc(reqId).update({ status: newStatus, updatedAt: firebase.firestore.FieldValue.serverTimestamp() });

    // REJECTED -> AUTOMATIC REFUND TO USER WALLET
    if (newStatus === 'rejected' && oldStatus === 'pending' && uid) {
      const field = (type || '').toLowerCase().includes('refer') ? 'referCash' : 'taskCash';
      await db.collection('users').doc(uid).update({ [field]: firebase.firestore.FieldValue.increment(parseFloat(amount)) });
      await db.collection('users').doc(uid).collection('notifications').add({
        title: '❌ Withdrawal Rejected',
        message: `Your withdrawal request of ₹${parseFloat(amount).toFixed(2)} was rejected. Money refunded to your balance.`,
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
        read: false
      });
      showToast(`Rejected & ₹${amount} Refunded to User!`);
    } else if (newStatus === 'completed' && uid) {
      await db.collection('users').doc(uid).collection('notifications').add({
        title: '🎉 Payout Successful!',
        message: `Your withdrawal of ₹${parseFloat(amount).toFixed(2)} has been credited to your UPI!`,
        createdAt: firebase.firestore.FieldValue.serverTimestamp(),
        read: false
      });
      showToast('Completed & Notification Sent!');
    }
  } catch (e) { alert('Error: ' + e.message); }
}

function exportCashfreeCSV() {
  if (!cachedWithdrawals.length) return alert('No withdrawals to export!');
  let csv = 'Transfer_ID,Amount,UPI_VPA,Status\n';
  cachedWithdrawals.forEach(w => { csv += `"${w.id}","${w.amount}","${w.upiId || ''}","${w.status || 'pending'}"\n`; });
  const a = document.createElement('a');
  a.href = window.URL.createObjectURL(new Blob([csv], { type: 'text/csv' }));
  a.download = `TPL_Payouts_${new Date().toISOString().slice(0, 10)}.csv`;
  a.click();
}                                                                                                                                    }
          

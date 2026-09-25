// ==========================================
// CONTENT & TASKS HUB MODULE (js/tasks.js)
// ==========================================

function switchTaskSubTab(sub) {
  const subs = ['social', 'banners', 'future'];
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
      c.innerHTML = '<div class="text-center py-6 text-gray-500 text-xs">No social tasks yet. Use + Add Task.</div>';
      return;
    }
    c.innerHTML = '';
    snap.forEach(doc => {
      const t = doc.data();
      const platform = String(t.platform || t.category || 'social').toLowerCase();
      const active = t.isActive !== false;
      const logo = platform.includes('instagram') ? 'https://cdn.simpleicons.org/instagram/E4405F' :
        platform.includes('youtube') ? 'https://cdn.simpleicons.org/youtube/FF0000' :
        platform.includes('telegram') ? 'https://cdn.simpleicons.org/telegram/26A5E4' : '';
      const div = document.createElement('div');
      div.className = 'dark-card p-3 rounded-2xl space-y-3';
      div.innerHTML = `
        <div class="flex items-center gap-3">
          <div class="w-11 h-11 rounded-xl bg-white/5 border border-white/10 flex items-center justify-center overflow-hidden">
            ${logo ? '<img src="' + logo + '" class="w-7 h-7 object-contain">' : '<span class="text-lg">🌐</span>'}
          </div>
          <div class="min-w-0 flex-1">
            <div class="text-xs font-bold text-white truncate">${t.title || 'Social Task'}</div>
            <div class="text-[10px] text-gray-400 truncate">${t.subtitle || t.description || 'Complete social task'} • +${Number(t.coins || 25)} Coins</div>
            <div class="text-[9px] ${active ? 'text-green-400' : 'text-gray-500'} mt-1">${active ? 'ACTIVE' : 'INACTIVE'} • ${platform}</div>
          </div>
          <button onclick="toggleTaskActive('${doc.id}', ${active})" class="px-2 py-1 rounded-lg text-[9px] font-black ${active ? 'bg-green-400/10 text-green-400' : 'bg-white/5 text-gray-500'}">${active ? 'ON' : 'OFF'}</button>
        </div>
        <div class="flex gap-2">
          <button onclick="editSocialTask('${doc.id}')" class="flex-1 px-2 py-2 bg-white/5 border border-white/10 text-white text-[10px] font-black rounded-xl">Edit</button>
          <button onclick="deleteDoc('tasks', '${doc.id}')" class="px-3 py-2 bg-red-500/10 text-red-400 text-[10px] font-black rounded-xl">Delete</button>
        </div>
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
    const docs = snap.docs.sort((a, b) => Number(a.data().order ?? 0) - Number(b.data().order ?? 0));
    docs.forEach(doc => {
      const b = doc.data();
      const image = (b.imageUrl || b.image || '').toString();
      const active = b.isActive !== false;
      const div = document.createElement('div');
      div.className = 'dark-card p-3 rounded-2xl space-y-3';
      div.innerHTML = `
        <div class="flex items-center gap-3">
          <div class="w-20 h-12 rounded-xl overflow-hidden bg-black/30 border border-white/10 flex-shrink-0">
            ${image ? '<img src="' + image.replace(/"/g, '&quot;') + '" class="w-full h-full object-cover" onerror="this.style.display=\'none\'">' : '<div class="w-full h-full flex items-center justify-center text-gray-600 text-[10px]">No image</div>'}
          </div>
          <div class="min-w-0 flex-1">
            <div class="text-xs font-bold text-white truncate">${b.title || 'Banner'}</div>
            <div class="text-[10px] text-gray-400 truncate">${b.sub || 'Carousel Banner'}</div>
            <div class="text-[9px] ${active ? 'text-green-400' : 'text-gray-500'} mt-1">${active ? 'ACTIVE' : 'INACTIVE'} • Order ${Number(b.order ?? 0)}</div>
          </div>
          <button onclick="toggleBannerActive('${doc.id}', ${active})" class="px-2 py-1 rounded-lg text-[9px] font-black ${active ? 'bg-green-400/10 text-green-400' : 'bg-white/5 text-gray-500'}">${active ? 'ON' : 'OFF'}</button>
        </div>
        <div class="flex gap-2">
          <button onclick="editBanner('${doc.id}')" class="flex-1 px-2 py-2 bg-white/5 border border-white/10 text-white text-[10px] font-black rounded-xl">Edit</button>
          <button onclick="deleteDoc('banners', '${doc.id}')" class="px-3 py-2 bg-red-500/10 text-red-400 text-[10px] font-black rounded-xl">Delete</button>
        </div>
      `;
      c.appendChild(div);
    });
  });

}

// ⚡ 1-Click Sync Defaults from App to Firebase
async function seedDefaultTasks() { showToast('Use + Add Task to create your own social tasks.'); }

async function seedDefaultBanners() {
  const banners = [
    { title: 'Complete Tasks & Earn Coins', sub: 'Finish tasks and grow your TPL wallet', targetUrl: '', imageUrl: '', isActive: true, order: 1 },
    { title: 'Fast & Easy Withdrawals', sub: 'Withdraw your available balance', targetUrl: '', imageUrl: '', isActive: true, order: 2 },
    { title: 'Daily Bonus', sub: 'Spin and scratch for extra coins', targetUrl: '', imageUrl: '', isActive: true, order: 3 }
  ];
  for (let b of banners) {
    await db.collection('banners').add({ ...b, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
  }
  showToast('Default Banners Synced to Database!');
}

// Modals Trigger
function ensureTaskModal() {
  if (document.getElementById('taskModal')) return;
  const wrap = document.createElement('div');
  wrap.id = 'taskModal';
  wrap.className = 'hidden fixed inset-0 z-50 bg-black/70 backdrop-blur-sm p-4 flex items-end sm:items-center justify-center';
  wrap.innerHTML = `
    <div class="dark-card w-full max-w-md rounded-3xl p-5 space-y-4 max-h-[90vh] overflow-y-auto">
      <div class="flex items-center justify-between">
        <div><div id="taskModalTitle" class="text-lg font-black text-white">Add Social Task</div><div class="text-[10px] text-gray-500">Add the exact social profile/channel link.</div></div>
        <button onclick="closeTaskModal()" class="text-gray-400 text-xl">×</button>
      </div>
      <input type="hidden" id="taskEditId">
      <select id="taskPlatform" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">
        <option value="instagram">Instagram</option>
        <option value="youtube">YouTube</option>
        <option value="telegram">Telegram</option>
        <option value="other">Other</option>
      </select>
      <input id="taskTitle" placeholder="Task title (e.g. Follow @yourpage)" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">
      <input id="taskSubtitle" placeholder="Short description" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">
      <input type="number" id="taskCoins" min="1" value="25" placeholder="Reward coins" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">
      <input id="taskUrl" placeholder="Exact Instagram / YouTube / Telegram URL" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">
      <label class="flex items-center justify-between px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-gray-300">Active <input type="checkbox" id="taskActive" checked class="w-4 h-4 accent-green-400"></label>
      <button onclick="saveNewTask()" class="w-full py-3 bg-green-400 text-black font-black text-xs rounded-xl">Save Task</button>
    </div>`;
  document.body.appendChild(wrap);
}
function openAddTaskModal() {
  ensureTaskModal();
  document.getElementById('taskModalTitle').textContent='Add Social Task';
  document.getElementById('taskEditId').value='';
  document.getElementById('taskPlatform').value='instagram';
  document.getElementById('taskTitle').value='';
  document.getElementById('taskSubtitle').value='';
  document.getElementById('taskCoins').value='25';
  document.getElementById('taskUrl').value='';
  document.getElementById('taskActive').checked=true;
  document.getElementById('taskModal').classList.remove('hidden');
}
function closeTaskModal(){ const m=document.getElementById('taskModal'); if(m) m.classList.add('hidden'); }
async function editSocialTask(id){
  ensureTaskModal();
  const snap=await db.collection('tasks').doc(id).get();
  if(!snap.exists) return alert('Task not found.');
  const t=snap.data()||{};
  document.getElementById('taskModalTitle').textContent='Edit Social Task';
  document.getElementById('taskEditId').value=id;
  document.getElementById('taskPlatform').value=t.platform||'other';
  document.getElementById('taskTitle').value=t.title||'';
  document.getElementById('taskSubtitle').value=t.subtitle||t.description||'';
  document.getElementById('taskCoins').value=String(t.coins??25);
  document.getElementById('taskUrl').value=t.url||t.link||'';
  document.getElementById('taskActive').checked=t.isActive!==false;
  document.getElementById('taskModal').classList.remove('hidden');
}
async function saveNewTask() {
  const id=document.getElementById('taskEditId').value.trim();
  const platform=document.getElementById('taskPlatform').value;
  const title=document.getElementById('taskTitle').value.trim();
  const subtitle=document.getElementById('taskSubtitle').value.trim();
  const coins=Math.max(1, Number(document.getElementById('taskCoins').value)||25);
  const url=document.getElementById('taskUrl').value.trim();
  const isActive=document.getElementById('taskActive').checked;
  if(!title || !url) return alert('Enter title and exact social URL!');
  const payload={platform,title,subtitle,coins,url,isActive,category:'Social',updatedAt:firebase.firestore.FieldValue.serverTimestamp()};
  if(id) await db.collection('tasks').doc(id).set(payload,{merge:true});
  else await db.collection('tasks').add({...payload,createdAt:firebase.firestore.FieldValue.serverTimestamp()});
  showToast(id ? 'Social Task Updated!' : 'Social Task Added!');
  closeTaskModal();
}
async function toggleTaskActive(id,active){
  await db.collection('tasks').doc(id).set({isActive:!active,updatedAt:firebase.firestore.FieldValue.serverTimestamp()},{merge:true});
  showToast(!active?'Task Activated!':'Task Deactivated!');
}

function ensureBannerModal() {
  if (document.getElementById('bannerModal')) return;
  const wrap = document.createElement('div');
  wrap.id = 'bannerModal';
  wrap.className = 'hidden fixed inset-0 z-50 bg-black/70 backdrop-blur-sm p-4 flex items-end sm:items-center justify-center';
  wrap.innerHTML = `
    <div class="dark-card w-full max-w-md rounded-3xl p-5 space-y-4 max-h-[90vh] overflow-y-auto">
      <div class="flex items-center justify-between">
        <div>
          <div id="bannerModalTitle" class="text-lg font-black text-white">Add Banner</div>
          <div class="text-[10px] text-gray-500">Use an image URL or upload directly if Firebase Storage is available.</div>
        </div>
        <button onclick="closeAddBannerModal()" class="text-gray-400 text-xl">×</button>
      </div>

      <input type="hidden" id="bannerEditId">
      <input type="hidden" id="bannerCurrentImageUrl">
      <input type="hidden" id="bannerCurrentStoragePath">

      <input id="bannerTitle" placeholder="Banner title" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">

      <input id="bannerSub" placeholder="Short subtitle (optional)" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">

      <div class="space-y-2">
        <label class="block text-[10px] text-gray-400 font-bold uppercase">Banner Image</label>
        <input id="bannerImageUrl" type="url" placeholder="Paste direct image URL (https://.../banner.png)" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white" oninput="handleBannerImageUrlChanged()">
        <div class="text-[9px] text-gray-500">Recommended: GitHub Raw / GitHub Pages direct image URL. No Firebase Storage upgrade needed.</div>
        <div class="text-center text-[9px] text-gray-600">OR</div>
        <label class="flex items-center justify-center gap-2 w-full px-3 py-4 bg-blue-500/10 border border-blue-400/30 border-dashed rounded-2xl text-xs text-blue-300 font-black cursor-pointer active:scale-[0.99]">
          <span>📤 Choose Image</span>
          <input id="bannerImageFile" type="file" accept="image/jpeg,image/png,image/webp,image/gif" class="hidden" onchange="handleBannerImageSelected(event)">
        </label>
        <div id="bannerUploadName" class="text-[10px] text-gray-500 text-center">No new image selected</div>
        <div id="bannerImagePreview" class="hidden rounded-2xl overflow-hidden border border-white/10 bg-black/30 aspect-video">
          <img id="bannerPreviewImg" class="w-full h-full object-cover">
        </div>
      </div>

      <input id="bannerTargetUrl" placeholder="Click target URL (optional)" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">

      <div class="grid grid-cols-2 gap-3">
        <input type="number" id="bannerOrder" min="0" value="1" placeholder="Order" class="w-full px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-white">
        <label class="flex items-center justify-between px-3 py-3 bg-black/50 border border-white/10 rounded-xl text-xs text-gray-300">Active <input type="checkbox" id="bannerActive" checked class="w-4 h-4 accent-green-400"></label>
      </div>

      <div id="bannerUploadProgress" class="hidden space-y-1">
        <div class="flex justify-between text-[10px] text-gray-400"><span>Uploading...</span><span id="bannerUploadPercent">0%</span></div>
        <div class="h-1.5 rounded-full bg-white/10 overflow-hidden"><div id="bannerUploadBar" class="h-full bg-blue-400 transition-all" style="width:0%"></div></div>
      </div>

      <button id="saveBannerBtn" onclick="saveNewBanner()" class="w-full py-3 bg-green-400 text-black font-black text-xs rounded-xl">Save Banner</button>
    </div>`;
  document.body.appendChild(wrap);
}

function openAddBannerModal() {
  ensureBannerModal();
  document.getElementById('bannerModalTitle').textContent = 'Add Banner';
  document.getElementById('bannerEditId').value = '';
  document.getElementById('bannerCurrentImageUrl').value = '';
  document.getElementById('bannerCurrentStoragePath').value = '';
  document.getElementById('bannerTitle').value = '';
  document.getElementById('bannerSub').value = '';
  document.getElementById('bannerImageUrl').value = '';
  document.getElementById('bannerTargetUrl').value = '';
  document.getElementById('bannerOrder').value = '1';
  document.getElementById('bannerActive').checked = true;
  document.getElementById('bannerImageFile').value = '';
  document.getElementById('bannerUploadName').textContent = 'No new image selected';
  document.getElementById('bannerImagePreview').classList.add('hidden');
  document.getElementById('bannerUploadProgress').classList.add('hidden');
  document.getElementById('saveBannerBtn').disabled = false;
  document.getElementById('saveBannerBtn').textContent = 'Save Banner';
  document.getElementById('bannerModal').classList.remove('hidden');
}

function closeAddBannerModal() {
  const m = document.getElementById('bannerModal');
  if (m) m.classList.add('hidden');
}

function handleBannerImageUrlChanged() {
  const input = document.getElementById('bannerImageUrl');
  const url = input ? input.value.trim() : '';
  const fileInput = document.getElementById('bannerImageFile');
  const name = document.getElementById('bannerUploadName');
  const box = document.getElementById('bannerImagePreview');
  const img = document.getElementById('bannerPreviewImg');

  if (!url) return;

  if (!/^https?:\/\//i.test(url)) {
    if (name) name.textContent = 'Enter a valid http(s) image URL';
    if (box) box.classList.add('hidden');
    return;
  }

  if (fileInput) fileInput.value = '';
  if (name) name.textContent = 'Image URL selected';
  if (img && box) {
    img.src = url;
    img.onload = () => box.classList.remove('hidden');
    img.onerror = () => {
      box.classList.add('hidden');
      if (name) name.textContent = 'Image URL could not be loaded';
    };
  }
}

function handleBannerImageSelected(event) {
  const file = event.target.files && event.target.files[0];
  const name = document.getElementById('bannerUploadName');
  const box = document.getElementById('bannerImagePreview');
  const img = document.getElementById('bannerPreviewImg');

  if (!file) {
    if (name) name.textContent = 'No new image selected';
    if (box) box.classList.add('hidden');
    return;
  }

  if (!file.type.startsWith('image/')) {
    event.target.value = '';
    if (name) name.textContent = 'Invalid file type';
    if (box) box.classList.add('hidden');
    return alert('Please select an image file.');
  }

  if (file.size > 8 * 1024 * 1024) {
    event.target.value = '';
    if (name) name.textContent = 'File is too large';
    if (box) box.classList.add('hidden');
    return alert('Banner image must be 8 MB or smaller.');
  }

  const urlInput = document.getElementById('bannerImageUrl');
  if (urlInput) urlInput.value = '';
  if (name) name.textContent = file.name + ' • ' + (file.size / 1024 / 1024).toFixed(2) + ' MB';
  if (img && box) {
    img.src = URL.createObjectURL(file);
    box.classList.remove('hidden');
  }
}

function setBannerUploadProgress(percent) {
  const wrap = document.getElementById('bannerUploadProgress');
  const label = document.getElementById('bannerUploadPercent');
  const bar = document.getElementById('bannerUploadBar');
  if (wrap) wrap.classList.remove('hidden');
  if (label) label.textContent = Math.round(percent) + '%';
  if (bar) bar.style.width = Math.max(0, Math.min(100, percent)) + '%';
}

function uploadBannerImage(file, storagePath) {
  return new Promise((resolve, reject) => {
    let settled = false;
    let timeoutId;

    const finishReject = (error) => {
      if (settled) return;
      settled = true;
      if (timeoutId) clearTimeout(timeoutId);
      reject(error instanceof Error ? error : new Error(String(error || 'Upload failed')));
    };

    const finishResolve = (value) => {
      if (settled) return;
      settled = true;
      if (timeoutId) clearTimeout(timeoutId);
      resolve(value);
    };

    try {
      if (!firebase.storage) {
        finishReject(new Error('Firebase Storage SDK is not loaded. Refresh the admin page.'));
        return;
      }

      const storage = firebase.storage();
      const safeName = (file.name || 'banner').replace(/[^a-zA-Z0-9._-]/g, '_');
      const ref = storage.ref().child(storagePath + '_' + safeName);

      // Fail fast instead of leaving the admin panel stuck at 0%.
      timeoutId = setTimeout(() => {
        finishReject(new Error(
          'Firebase Storage upload timed out. Check that Firebase Storage is enabled and its rules allow the logged-in admin to upload.'
        ));
      }, 30000);

      const task = ref.put(file, {
        contentType: file.type || 'image/jpeg',
        cacheControl: 'public,max-age=31536000'
      });

      task.on(
        'state_changed',
        snapshot => {
          const progress = snapshot.totalBytes
            ? (snapshot.bytesTransferred / snapshot.totalBytes) * 100
            : 0;
          setBannerUploadProgress(progress);
        },
        error => {
          console.error('Firebase Storage upload error:', error);
          finishReject(new Error(
            'Storage upload failed: ' + (error && error.message ? error.message : error)
          ));
        },
        async () => {
          try {
            const url = await task.snapshot.ref.getDownloadURL();
            finishResolve({ url: url, path: task.snapshot.ref.fullPath });
          } catch (e) {
            finishReject(new Error(
              'Upload completed but download URL failed: ' + (e && e.message ? e.message : e)
            ));
          }
        }
      );
    } catch (e) {
      finishReject(new Error(
        'Firebase Storage could not start: ' + (e && e.message ? e.message : e)
      ));
    }
  });
}

async function saveNewBanner() {
  const btn = document.getElementById('saveBannerBtn');
  const id = document.getElementById('bannerEditId').value.trim();
  const title = document.getElementById('bannerTitle').value.trim();
  const sub = document.getElementById('bannerSub').value.trim();
  const targetUrl = document.getElementById('bannerTargetUrl').value.trim();
  const order = Math.max(0, Number(document.getElementById('bannerOrder').value) || 0);
  const isActive = document.getElementById('bannerActive').checked;
  const fileInput = document.getElementById('bannerImageFile');
  const file = fileInput && fileInput.files ? fileInput.files[0] : null;
  const imageUrlInput = document.getElementById('bannerImageUrl');
  const imageUrl = imageUrlInput ? imageUrlInput.value.trim() : '';
  const currentImageUrl = document.getElementById('bannerCurrentImageUrl').value.trim();
  const currentStoragePath = document.getElementById('bannerCurrentStoragePath').value.trim();

  if (!title) return alert('Enter banner title!');
  if (!id && !file && !imageUrl) return alert('Paste an image URL or choose a banner image.');
  if (imageUrl && !/^https?:\/\//i.test(imageUrl)) return alert('Enter a valid image URL starting with http:// or https://');
  if (file && (!file.type.startsWith('image/') || file.size > 8 * 1024 * 1024)) {
    return alert('Please choose an image up to 8 MB.');
  }

  try {
    btn.disabled = true;
    btn.textContent = file ? 'Uploading...' : 'Saving...';

    // Generate the Firestore document ID before upload so the Storage path is stable.
    const docRef = id ? db.collection('banners').doc(id) : db.collection('banners').doc();
    let savedImageUrl = currentImageUrl;
    let storagePath = currentStoragePath;

    if (imageUrl) {
      savedImageUrl = imageUrl;
      storagePath = '';
    } else if (file) {
      setBannerUploadProgress(0);
      const uploaded = await uploadBannerImage(file, 'banners/' + docRef.id + '/' + Date.now());
      savedImageUrl = uploaded.url;
      storagePath = uploaded.path;
    }

    const payload = {
      title,
      sub,
      imageUrl: savedImageUrl,
      targetUrl,
      isActive,
      order,
      storagePath,
      updatedAt: firebase.firestore.FieldValue.serverTimestamp()
    };

    if (id) {
      await docRef.set(payload, { merge: true });
    } else {
      await docRef.set({ ...payload, createdAt: firebase.firestore.FieldValue.serverTimestamp() });
    }

    // Remove the previous uploaded file after the new banner is safely saved.
    if (file && currentStoragePath && currentStoragePath !== storagePath) {
      try {
        await firebase.storage().ref().child(currentStoragePath).delete();
      } catch (cleanupError) {
        console.warn('Old banner cleanup skipped:', cleanupError);
      }
    }

    showToast(id ? 'Banner Updated!' : 'Banner Uploaded & Saved!');
    closeAddBannerModal();
  } catch (e) {
    console.error('Banner upload/save error:', e);
    alert('Banner upload failed: ' + (e.message || e));
  } finally {
    btn.disabled = false;
    btn.textContent = 'Save Banner';
    const progress = document.getElementById('bannerUploadProgress');
    if (progress) progress.classList.add('hidden');
  }
}

async function editBanner(id) {
  ensureBannerModal();
  const snap = await db.collection('banners').doc(id).get();
  if (!snap.exists) return alert('Banner not found.');
  const b = snap.data() || {};

  document.getElementById('bannerModalTitle').textContent = 'Edit Banner';
  document.getElementById('bannerEditId').value = id;
  document.getElementById('bannerCurrentImageUrl').value = b.imageUrl || b.image || '';
  document.getElementById('bannerCurrentStoragePath').value = b.storagePath || '';
  document.getElementById('bannerTitle').value = b.title || '';
  document.getElementById('bannerSub').value = b.sub || '';
  document.getElementById('bannerImageUrl').value = b.imageUrl || b.image || '';
  document.getElementById('bannerTargetUrl').value = b.targetUrl || b.url || b.link || '';
  document.getElementById('bannerOrder').value = String(b.order ?? 1);
  document.getElementById('bannerActive').checked = b.isActive !== false;
  document.getElementById('bannerImageFile').value = '';
  document.getElementById('bannerUploadName').textContent = b.imageUrl || b.image ? 'Current image URL loaded' : 'No new image selected';
  document.getElementById('bannerUploadProgress').classList.add('hidden');

  const currentImage = b.imageUrl || b.image || '';
  const preview = document.getElementById('bannerImagePreview');
  const img = document.getElementById('bannerPreviewImg');
  if (currentImage) {
    img.src = currentImage;
    preview.classList.remove('hidden');
  } else {
    preview.classList.add('hidden');
  }

  document.getElementById('saveBannerBtn').disabled = false;
  document.getElementById('saveBannerBtn').textContent = 'Save Banner';
  document.getElementById('bannerModal').classList.remove('hidden');
}

async function toggleBannerActive(id, active) {
  await db.collection('banners').doc(id).set({isActive:!active,updatedAt:firebase.firestore.FieldValue.serverTimestamp()},{merge:true});
  showToast(!active ? 'Banner Activated!' : 'Banner Deactivated!');
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
